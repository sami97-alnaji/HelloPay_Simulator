import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../domain/demo_data.dart';
import '../domain/enums.dart';
import '../domain/models.dart';
import '../domain/simulator_engine.dart';
import '../domain/simulator_error.dart';

enum TipMode { omitted, explicitZero, custom }

class SimulatorController extends ChangeNotifier {
  SimulatorController({SimulatorEngine? engine})
      : engine = engine ?? SimulatorEngine() {
    selectedCard = this.engine.selectedCard;
    selectedScenario = this.engine.selectedScenario;
  }

  final SimulatorEngine engine;
  late DemoCard selectedCard;
  late ScenarioPreset selectedScenario;
  PaymentRequest? pendingRequest;
  Transaction? resultTransaction;
  SimulatorError? resultError;
  TransactionType resultType = TransactionType.payment;
  SettlementReport? settlementReport;
  Json? _operationRequest;
  TipMode tipMode = TipMode.omitted;
  bool processing = false;
  bool developerDetailsEnabled = false;
  SimulatorSpeed speed = SimulatorSpeed.fast;
  int pinAttempts = 0;
  String pin = '';
  bool _executed = false;

  void selectCard(DemoCard card) {
    selectedCard = card;
    engine.selectedCard = card;
    notifyListeners();
  }

  void selectScenario(ScenarioPreset scenario) {
    selectedScenario = scenario;
    engine.selectedScenario = scenario;
    notifyListeners();
  }

  OtpToken generateOtp() {
    final token = engine.generateOtp();
    notifyListeners();
    return token;
  }

  SimulatorResult<PairingSession> pair({
    required String token,
    required String posId,
    required String posName,
  }) {
    final result = engine.createPairingSession(
        token: token, posId: posId, posName: posName);
    notifyListeners();
    return result;
  }

  void preparePayment(PaymentRequest request) {
    pendingRequest = request;
    _operationRequest = request.toJson();
    resultTransaction = null;
    resultError = null;
    resultType = TransactionType.payment;
    pin = '';
    pinAttempts = 0;
    _executed = false;
    notifyListeners();
  }

  void refundTransaction(Transaction original) {
    final originalUserCode = original.userCode?.trim();
    final request = RefundRequest(
      requestId: _operationId('REFUND'),
      amount: original.remainingRefundableAmount,
      paymentMethod: original.paymentMethod,
      userCode: originalUserCode == null || originalUserCode.isEmpty
          ? 'demo-user'
          : originalUserCode,
      remoteIdentity: original.remoteIdentity,
      originalTransactionId: original.transactionId,
    );
    _operationRequest = request.toJson();
    resultType = TransactionType.refund;
    final result = engine.processRefund(request);
    resultTransaction = result.value;
    resultError = result.error;
    notifyListeners();
  }

  void voidTransaction(Transaction original, {bool mismatchedId = false}) {
    final originalUserCode = original.userCode?.trim();
    final request = VoidRequest(
      requestId: _operationId('VOID'),
      lastTransactionId: mismatchedId
          ? '${original.transactionId}-MISMATCH'
          : original.transactionId,
      userCode: originalUserCode == null || originalUserCode.isEmpty
          ? 'demo-user'
          : originalUserCode,
    );
    _operationRequest = request.toJson();
    resultType = TransactionType.voidTransaction;
    final result = engine.voidLastTransaction(request);
    resultTransaction = result.value;
    resultError = result.error;
    notifyListeners();
  }

  void closeBatch() {
    settlementReport = engine.closeBatch();
    notifyListeners();
  }

  String _operationId(String prefix) =>
      '$prefix-${DateTime.now().microsecondsSinceEpoch}';

  void appendPin(String digit) {
    if (pin.length < 6) {
      pin += digit;
      notifyListeners();
    }
  }

  void deletePin() {
    if (pin.isNotEmpty) {
      pin = pin.substring(0, pin.length - 1);
      notifyListeners();
    }
  }

  bool submitPin() {
    final behavior = effectivePinBehavior;
    pinAttempts++;
    final accepted = switch (behavior) {
      PinBehavior.notRequired ||
      PinBehavior.correct =>
        pin == (selectedCard.correctPin ?? '1234'),
      PinBehavior.failOnceThenSuccess => pinAttempts > 1,
      PinBehavior.alwaysIncorrect || PinBehavior.blocked => false,
    };
    pin = '';
    notifyListeners();
    return accepted;
  }

  PinBehavior get effectivePinBehavior => selectedScenario.requiresPin
      ? selectedScenario.pinBehavior
      : selectedCard.pinBehavior;

  Duration get processingDelay {
    final speedDelay = switch (speed) {
      SimulatorSpeed.instant => Duration.zero,
      SimulatorSpeed.fast => const Duration(milliseconds: 900),
      SimulatorSpeed.realistic => const Duration(milliseconds: 1600),
      SimulatorSpeed.slowTraining => const Duration(milliseconds: 2600),
    };
    return selectedScenario.delay > speedDelay
        ? selectedScenario.delay
        : speedDelay;
  }

  Future<void> executePaymentOnce() async {
    if (_executed || pendingRequest == null) return;
    _executed = true;
    processing = true;
    engine.runtimeState =
        engine.runtimeState.copyWith(status: TerminalStatus.busy);
    notifyListeners();
    await Future<void>.delayed(processingDelay);
    engine.runtimeState =
        engine.runtimeState.copyWith(status: TerminalStatus.ready);
    final result = engine.processPayment(pendingRequest!);
    resultError = result.error;
    resultTransaction = result.value ??
        (engine.transactionHistory.isEmpty
            ? null
            : engine.transactionHistory.last);
    processing = false;
    notifyListeners();
  }

  void cancelPayment() {
    selectedScenario =
        ScenarioPresets.all.firstWhere((s) => s.id == 'cancelled');
    engine.selectedScenario = selectedScenario;
    _executed = false;
    notifyListeners();
  }

  void clearPin() {
    pin = '';
    notifyListeners();
  }

  void clearHistory() {
    engine.clearTransactionHistory();
    resultTransaction = null;
    notifyListeners();
  }

  void clearLastTransaction() {
    engine.lastTransaction = null;
    resultTransaction = null;
    notifyListeners();
  }

  void invalidateSession() {
    engine.invalidateSession();
    notifyListeners();
  }

  void setTippingEnabled(bool value) {
    engine.config = engine.config.copyWith(tippingEnabled: value);
    notifyListeners();
  }

  void setTipLimits({double? amount, double? percentage}) {
    engine.config = engine.config
        .copyWith(maximumTipAmount: amount, maximumTipPercentage: percentage);
    notifyListeners();
  }

  void setSpeed(SimulatorSpeed value) {
    speed = value;
    notifyListeners();
  }

  void setDeveloperDetailsEnabled(bool value) {
    developerDetailsEnabled = value;
    notifyListeners();
  }

  void reset() {
    engine.resetSimulator();
    selectedCard = engine.selectedCard;
    selectedScenario = engine.selectedScenario;
    pendingRequest = null;
    resultTransaction = null;
    resultError = null;
    resultType = TransactionType.payment;
    settlementReport = null;
    _operationRequest = null;
    tipMode = TipMode.omitted;
    processing = false;
    pin = '';
    pinAttempts = 0;
    _executed = false;
    notifyListeners();
  }

  String requestJson() =>
      const JsonEncoder.withIndent('  ').convert(_operationRequest ??
          pendingRequest?.toJson() ??
          const <String, Object?>{});

  String responseJson() =>
      const JsonEncoder.withIndent('  ').convert(resultTransaction?.toJson() ??
          {
            'errorCode': resultError?.code,
            'errorMessage': resultError?.userMessage
          });
}
