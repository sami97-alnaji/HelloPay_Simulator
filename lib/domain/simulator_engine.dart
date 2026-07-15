import 'dart:math';
import 'demo_data.dart';
import 'enums.dart';
import 'models.dart';
import 'simulator_error.dart';

typedef Clock = DateTime Function();

class SimulatorResult<T> {
  const SimulatorResult.success(this.value) : error = null;
  const SimulatorResult.failure(this.error) : value = null;
  final T? value;
  final SimulatorError? error;
  bool get isSuccess => error == null;
}

class SimulatorEngine {
  SimulatorEngine({Clock? clock, Random? random, TerminalConfig? config})
      : _clock = clock ?? (() => DateTime.now().toUtc()),
        _random = random ?? Random(),
        config = config ?? TerminalConfig.defaults() {
    runtimeState = TerminalRuntimeState.ready(_clock());
    selectedCard = DemoCards.all.first;
    selectedScenario = ScenarioPresets.all.first;
  }
  final Clock _clock;
  final Random _random;
  TerminalConfig config;
  late TerminalRuntimeState runtimeState;
  OtpToken? otp;
  PairingSession? pairingSession;
  late DemoCard selectedCard;
  late ScenarioPreset selectedScenario;
  Transaction? activeTransaction, lastTransaction;
  final List<Transaction> transactionHistory = [];
  final List<SettlementReport> settlementHistory = [];
  String _id(String prefix) =>
      '$prefix-${_clock().millisecondsSinceEpoch}-${_random.nextInt(99999).toString().padLeft(5, '0')}';
  OtpToken generateOtp({Duration validFor = const Duration(minutes: 5)}) {
    final now = _clock();
    otp = OtpToken(
        value: (100000 + _random.nextInt(900000)).toString(),
        createdAt: now,
        expiresAt: now.add(validFor),
        isUsed: false);
    return otp!;
  }

  SimulatorResult<OtpToken> validatePairingToken(String token) {
    final current = otp;
    if (current == null || current.value != token) {
      return SimulatorResult.failure(ErrorCatalog.lookup(3001));
    }
    if (current.isExpiredAt(_clock())) {
      return SimulatorResult.failure(ErrorCatalog.lookup(3002));
    }
    if (current.isUsed) {
      return SimulatorResult.failure(ErrorCatalog.lookup(3001));
    }
    otp = current.copyWith(isUsed: true);
    return SimulatorResult.success(otp!);
  }

  SimulatorResult<PairingSession> createPairingSession(
      {required String token,
      required String posId,
      required String posName,
      Duration validFor = const Duration(hours: 8)}) {
    final valid = validatePairingToken(token);
    if (!valid.isSuccess) return SimulatorResult.failure(valid.error!);
    final now = _clock();
    pairingSession = PairingSession(
        sessionId: _id('PS'),
        terminalId: config.terminalId,
        posId: posId,
        posName: posName,
        certificateFingerprint: config.certificateFingerprint,
        createdAt: now,
        expiresAt: now.add(validFor),
        isActive: true);
    return SimulatorResult.success(pairingSession!);
  }

  void invalidateSession() {
    if (pairingSession != null) {
      pairingSession = pairingSession!.copyWith(isActive: false);
    }
  }

  bool get isSessionValid => pairingSession?.isValidAt(_clock()) ?? false;
  Json checkHealth() => {
        'healthy': runtimeState.status != TerminalStatus.inactive,
        'status': runtimeState.status.wire,
        'timestamp': _clock().toIso8601String()
      };
  String getTerminalId() => config.terminalId;
  TerminalStatus getTerminalStatus() => runtimeState.status;
  Json getTippingConfiguration() => {
        'enabled': config.tippingEnabled,
        'maximumTipAmount': config.maximumTipAmount,
        'maximumTipPercentage': config.maximumTipPercentage,
        'currency': config.currency
      };
  SimulatorResult<Transaction> processPayment(PaymentRequest request,
      {bool sessionRequired = false}) {
    final now = _clock();
    final id = request.requestId.isEmpty ? _id('REQ') : request.requestId;
    final normalized = PaymentRequest(
        requestId: id,
        base: request.base,
        tip: request.tip,
        service: request.service,
        paymentMethod: request.paymentMethod,
        userCode: request.userCode,
        remoteIdentity: request.remoteIdentity);
    final validation = _validatePayment(normalized, sessionRequired);
    if (validation != null) return _failedPayment(normalized, validation, now);
    runtimeState = runtimeState.copyWith(
        status: TerminalStatus.busy, lastActivityAt: now, clearError: true);
    final scenario = selectedScenario.scenario == SimulatorScenario.success
        ? selectedCard.defaultScenario
        : selectedScenario.scenario;
    final customStatus = selectedScenario.customResponse?['status']
        ?.toString()
        .trim()
        .toUpperCase();
    final customApproved = scenario == SimulatorScenario.custom &&
        (customStatus == 'APPROVED' || customStatus == 'SUCCESS');
    if (scenario != SimulatorScenario.success && !customApproved) {
      final error = _scenarioError(scenario);
      runtimeState = runtimeState.copyWith(
          status: TerminalStatus.ready,
          lastActivityAt: _clock(),
          errorMessage: error.userMessage);
      return _failedPayment(normalized, error, _clock());
    }
    final method = normalized.paymentMethod == PaymentMethod.auto
        ? PaymentMethod.bank
        : normalized.paymentMethod;
    final tx = Transaction(
        transactionId: _id('TXN'),
        requestId: id,
        externalId: _id('EXT'),
        type: TransactionType.payment,
        status: TransactionStatus.success,
        baseAmount: normalized.base,
        tipAmount: normalized.tip ?? 0,
        serviceAmount: normalized.service,
        totalAmount:
            normalized.base + (normalized.tip ?? 0) + normalized.service,
        refundedAmount: 0,
        paymentMethod: method,
        paymentProcessor: 'HelloPay Simulator',
        cardType: selectedCard.cardType,
        maskedCardNumber: selectedCard.maskedPan,
        cardNumberLast4: selectedCard.last4,
        requireSignature:
            selectedCard.requireSignature || selectedScenario.requireSignature,
        userCode: normalized.userCode,
        remoteIdentity: normalized.remoteIdentity,
        createdAt: now,
        completedAt: _clock(),
        receiptData: selectedScenario.receiptEnabled
            ? ReceiptData(
                type: ReceiptType.text,
                content: 'SIMULATOR RECEIPT',
                mimeType: 'text/plain',
                createdAt: _clock())
            : null,
        errorCode: null,
        errorMessage: null);
    activeTransaction = null;
    lastTransaction = tx;
    transactionHistory.add(tx);
    runtimeState = runtimeState.copyWith(
        status: TerminalStatus.ready,
        lastActivityAt: _clock(),
        clearTransactionId: true,
        clearError: true);
    return SimulatorResult.success(tx);
  }

  SimulatorError? _validatePayment(PaymentRequest r, bool sessionRequired) {
    if (runtimeState.status == TerminalStatus.busy) {
      return ErrorCatalog.lookup(1011);
    }
    if (!config.integrationModeEnabled) return ErrorCatalog.lookup(1009);
    if (sessionRequired && !isSessionValid) return ErrorCatalog.lookup(3004);
    if (r.base <= 0) return ErrorCatalog.lookup(1002);
    if (r.tip != null && r.tip! < 0) return ErrorCatalog.lookup(1003);
    if (r.service < 0) return ErrorCatalog.lookup(1002);
    final m = r.paymentMethod == PaymentMethod.auto
        ? PaymentMethod.bank
        : r.paymentMethod;
    if (!selectedCard.supportedPaymentMethods.contains(m)) {
      return ErrorCatalog.lookup(1001);
    }
    if ((m == PaymentMethod.szep ||
            m == PaymentMethod.ep ||
            m == PaymentMethod.softpos) &&
        (r.tip ?? 0) > 0) {
      return ErrorCatalog.lookup(1005);
    }
    if (!config.tippingEnabled && (r.tip ?? 0) > 0) {
      return ErrorCatalog.lookup(1005);
    }
    if ((r.tip ?? 0) > config.maximumTipAmount ||
        (r.base > 0 &&
            (r.tip ?? 0) / r.base * 100 > config.maximumTipPercentage)) {
      return ErrorCatalog.lookup(1012);
    }
    return null;
  }

  SimulatorResult<Transaction> _failedPayment(
      PaymentRequest r, SimulatorError e, DateTime now) {
    final status = e.code == 1004
        ? TransactionStatus.cancelled
        : e.code == 3012
            ? TransactionStatus.timedOut
            : TransactionStatus.failed;
    final tx = Transaction(
        transactionId: _id('TXN'),
        requestId: r.requestId,
        externalId: _id('EXT'),
        type: TransactionType.payment,
        status: status,
        baseAmount: r.base,
        tipAmount: r.tip ?? 0,
        serviceAmount: r.service,
        totalAmount: r.base + (r.tip ?? 0) + r.service,
        refundedAmount: 0,
        paymentMethod: r.paymentMethod == PaymentMethod.auto
            ? PaymentMethod.bank
            : r.paymentMethod,
        paymentProcessor: 'HelloPay Simulator',
        cardType: selectedCard.cardType,
        maskedCardNumber: selectedCard.maskedPan,
        cardNumberLast4: selectedCard.last4,
        requireSignature: false,
        userCode: r.userCode,
        remoteIdentity: r.remoteIdentity,
        createdAt: now,
        completedAt: _clock(),
        receiptData: null,
        errorCode: e.code.toString(),
        errorMessage: e.userMessage);
    transactionHistory.add(tx);
    return SimulatorResult.failure(e);
  }

  SimulatorError _scenarioError(SimulatorScenario s) => switch (s) {
        SimulatorScenario.userCancelled => ErrorCatalog.lookup(1004),
        SimulatorScenario.terminalBusy => ErrorCatalog.lookup(1011),
        SimulatorScenario.requestTimeout => ErrorCatalog.lookup(3012),
        SimulatorScenario.sessionExpired => ErrorCatalog.lookup(3004),
        SimulatorScenario.permissionDenied => ErrorCatalog.lookup(1102),
        SimulatorScenario.invalidAmount => ErrorCatalog.lookup(1002),
        SimulatorScenario.negativeTip => ErrorCatalog.lookup(1003),
        SimulatorScenario.unsupportedPaymentMethod => ErrorCatalog.lookup(1001),
        SimulatorScenario.tipNotAllowed => ErrorCatalog.lookup(1005),
        SimulatorScenario.tipExceedsLimit => ErrorCatalog.lookup(1012),
        SimulatorScenario.refundFailed => ErrorCatalog.lookup(2001),
        SimulatorScenario.voidFailed => ErrorCatalog.lookup(2002),
        SimulatorScenario.appTerminated => ErrorCatalog.lookup(1010),
        SimulatorScenario.networkError => ErrorCatalog.lookup(3010),
        _ => ErrorCatalog.lookup(2000)
      };
  SimulatorResult<Transaction> processRefund(RefundRequest request) {
    if (request.amount <= 0) {
      return SimulatorResult.failure(ErrorCatalog.lookup(1002));
    }
    if (request.userCode.trim().isEmpty) {
      return SimulatorResult.failure(ErrorCatalog.lookup(1102));
    }
    if (selectedScenario.scenario == SimulatorScenario.permissionDenied) {
      return SimulatorResult.failure(ErrorCatalog.lookup(1102));
    }
    if (selectedScenario.scenario == SimulatorScenario.refundFailed) {
      return SimulatorResult.failure(ErrorCatalog.lookup(2001));
    }
    Transaction? original;
    if (request.originalTransactionId != null) {
      original = transactionHistory
          .where((x) => x.transactionId == request.originalTransactionId)
          .cast<Transaction?>()
          .firstOrNull;
      if (original == null) {
        return SimulatorResult.failure(ErrorCatalog.lookup(2003));
      }
      if (request.amount > original.remainingRefundableAmount) {
        return SimulatorResult.failure(ErrorCatalog.lookup(2001));
      }
    }
    final now = _clock();
    if (original != null) {
      final i = transactionHistory.indexOf(original);
      original = original.copyWith(
          refundedAmount: original.refundedAmount + request.amount);
      transactionHistory[i] = original;
      if (lastTransaction?.transactionId == original.transactionId) {
        lastTransaction = original;
      }
    }
    final tx = Transaction(
        transactionId: _id('REF'),
        requestId: request.requestId.isEmpty ? _id('REQ') : request.requestId,
        externalId: _id('EXT'),
        type: TransactionType.refund,
        status: TransactionStatus.success,
        baseAmount: request.amount,
        tipAmount: 0,
        serviceAmount: 0,
        totalAmount: request.amount,
        refundedAmount: 0,
        paymentMethod: request.paymentMethod,
        paymentProcessor: 'HelloPay Simulator',
        cardType: selectedCard.cardType,
        maskedCardNumber: selectedCard.maskedPan,
        cardNumberLast4: selectedCard.last4,
        requireSignature: false,
        userCode: request.userCode,
        remoteIdentity: request.remoteIdentity,
        createdAt: now,
        completedAt: now,
        receiptData: ReceiptData(
            type: ReceiptType.text,
            content: 'SIMULATOR REFUND RECEIPT',
            mimeType: 'text/plain',
            createdAt: now),
        errorCode: null,
        errorMessage: null);
    transactionHistory.add(tx);
    lastTransaction = tx;
    return SimulatorResult.success(tx);
  }

  SimulatorResult<Transaction> voidLastTransaction(VoidRequest request) {
    if (request.lastTransactionId.trim().isEmpty) {
      return SimulatorResult.failure(ErrorCatalog.lookup(2003));
    }
    final last = lastTransaction;
    if (last == null) return SimulatorResult.failure(ErrorCatalog.lookup(2005));
    if (last.transactionId != request.lastTransactionId) {
      return SimulatorResult.failure(ErrorCatalog.lookup(2004));
    }
    if (!last.isSuccessful) {
      return SimulatorResult.failure(ErrorCatalog.lookup(2002));
    }
    if (selectedScenario.scenario == SimulatorScenario.voidFailed) {
      return SimulatorResult.failure(ErrorCatalog.lookup(2002));
    }
    final now = _clock();
    final tx = Transaction(
        transactionId: _id('VOID'),
        requestId: request.requestId.isEmpty ? _id('REQ') : request.requestId,
        externalId: _id('EXT'),
        type: TransactionType.voidTransaction,
        status: TransactionStatus.success,
        baseAmount: last.totalAmount,
        tipAmount: 0,
        serviceAmount: 0,
        totalAmount: last.totalAmount,
        refundedAmount: 0,
        paymentMethod: last.paymentMethod,
        paymentProcessor: 'HelloPay Simulator',
        cardType: last.cardType,
        maskedCardNumber: last.maskedCardNumber,
        cardNumberLast4: last.cardNumberLast4,
        requireSignature: false,
        userCode: request.userCode,
        remoteIdentity: null,
        createdAt: now,
        completedAt: now,
        receiptData: null,
        errorCode: null,
        errorMessage: null);
    transactionHistory.add(tx);
    lastTransaction = tx;
    return SimulatorResult.success(tx);
  }

  Transaction? getLastTransaction() => lastTransaction;
  SettlementReport closeBatch() {
    final now = _clock();
    final payments = transactionHistory
        .where((t) => t.type == TransactionType.payment && t.isSuccessful)
        .toList();
    final refunds = transactionHistory
        .where((t) => t.type == TransactionType.refund && t.isSuccessful)
        .toList();
    final voids = transactionHistory
        .where(
            (t) => t.type == TransactionType.voidTransaction && t.isSuccessful)
        .toList();
    final gross = payments.fold(0.0, (v, t) => v + t.totalAmount);
    final refund = refunds.fold(0.0, (v, t) => v + t.totalAmount);
    final r = SettlementReport(
        reportId: _id('SET'),
        openedAt: transactionHistory.isEmpty
            ? now
            : transactionHistory.first.createdAt,
        closedAt: now,
        paymentCount: payments.length,
        refundCount: refunds.length,
        voidCount: voids.length,
        grossAmount: gross,
        refundAmount: refund,
        netAmount: gross - refund,
        helloPayReceipt: 'SIMULATOR SETTLEMENT',
        otpReceipt: otp?.value);
    settlementHistory.add(r);
    return r;
  }

  void clearTransactionHistory() {
    transactionHistory.clear();
    lastTransaction = null;
    activeTransaction = null;
  }

  void resetSimulator() {
    otp = null;
    pairingSession = null;
    clearTransactionHistory();
    settlementHistory.clear();
    config = TerminalConfig.defaults();
    runtimeState = TerminalRuntimeState.ready(_clock());
    selectedCard = DemoCards.all.first;
    selectedScenario = ScenarioPresets.all.first;
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
