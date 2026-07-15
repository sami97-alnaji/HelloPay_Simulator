import 'dart:convert';
import 'enums.dart';

typedef Json = Map<String, dynamic>;
DateTime _date(Object? v, [DateTime? fallback]) =>
    DateTime.tryParse('${v ?? ''}')?.toUtc() ??
    fallback ??
    DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
int _int(Object? v, [int fallback = 0]) =>
    v is num ? v.toInt() : int.tryParse('$v') ?? fallback;
double _num(Object? v, [double fallback = 0]) =>
    v is num ? v.toDouble() : double.tryParse('$v') ?? fallback;
bool _bool(Object? v, [bool fallback = false]) => v is bool
    ? v
    : '$v'.toLowerCase() == 'true'
        ? true
        : fallback;
String _str(Object? v, [String fallback = '']) => v?.toString() ?? fallback;

abstract class ImmutableModel {
  const ImmutableModel();
  Json toJson();
  @override
  bool operator ==(Object other) =>
      other.runtimeType == runtimeType &&
      other is ImmutableModel &&
      jsonEncode(other.toJson()) == jsonEncode(toJson());
  @override
  int get hashCode => jsonEncode(toJson()).hashCode;
}

class TerminalConfig extends ImmutableModel {
  const TerminalConfig(
      {required this.terminalId,
      required this.deviceName,
      required this.ipAddress,
      required this.port,
      required this.protocol,
      required this.appVersion,
      required this.integrationModeEnabled,
      required this.apiSimulatorEnabled,
      required this.tippingEnabled,
      required this.maximumTipAmount,
      required this.maximumTipPercentage,
      required this.currency,
      required this.certificateFingerprint});
  factory TerminalConfig.defaults() => const TerminalConfig(
      terminalId: 'HP-SIM-001',
      deviceName: 'HelloPay Simulator',
      ipAddress: '127.0.0.1',
      port: 8080,
      protocol: 'HTTP',
      appVersion: '0.1.0',
      integrationModeEnabled: true,
      apiSimulatorEnabled: true,
      tippingEnabled: true,
      maximumTipAmount: 10000,
      maximumTipPercentage: 20,
      currency: 'HUF',
      certificateFingerprint: 'SIMULATOR-LOCAL-CERTIFICATE');
  factory TerminalConfig.fromJson(Json j) => TerminalConfig(
      terminalId: _str(j['terminalId']),
      deviceName: _str(j['deviceName']),
      ipAddress: _str(j['ipAddress']),
      port: _int(j['port'], 8080),
      protocol: _str(j['protocol'], 'HTTP'),
      appVersion: _str(j['appVersion']),
      integrationModeEnabled: _bool(j['integrationModeEnabled'], true),
      apiSimulatorEnabled: _bool(j['apiSimulatorEnabled'], true),
      tippingEnabled: _bool(j['tippingEnabled'], true),
      maximumTipAmount: _num(j['maximumTipAmount']),
      maximumTipPercentage: _num(j['maximumTipPercentage']),
      currency: _str(j['currency'], 'HUF'),
      certificateFingerprint: _str(j['certificateFingerprint']));
  final String terminalId,
      deviceName,
      ipAddress,
      protocol,
      appVersion,
      currency,
      certificateFingerprint;
  final int port;
  final bool integrationModeEnabled, apiSimulatorEnabled, tippingEnabled;
  final double maximumTipAmount, maximumTipPercentage;
  TerminalConfig copyWith(
          {String? terminalId,
          bool? integrationModeEnabled,
          bool? tippingEnabled,
          double? maximumTipAmount,
          double? maximumTipPercentage}) =>
      TerminalConfig(
          terminalId: terminalId ?? this.terminalId,
          deviceName: deviceName,
          ipAddress: ipAddress,
          port: port,
          protocol: protocol,
          appVersion: appVersion,
          integrationModeEnabled:
              integrationModeEnabled ?? this.integrationModeEnabled,
          apiSimulatorEnabled: apiSimulatorEnabled,
          tippingEnabled: tippingEnabled ?? this.tippingEnabled,
          maximumTipAmount: maximumTipAmount ?? this.maximumTipAmount,
          maximumTipPercentage:
              maximumTipPercentage ?? this.maximumTipPercentage,
          currency: currency,
          certificateFingerprint: certificateFingerprint);
  @override
  Json toJson() => {
        'terminalId': terminalId,
        'deviceName': deviceName,
        'ipAddress': ipAddress,
        'port': port,
        'protocol': protocol,
        'appVersion': appVersion,
        'integrationModeEnabled': integrationModeEnabled,
        'apiSimulatorEnabled': apiSimulatorEnabled,
        'tippingEnabled': tippingEnabled,
        'maximumTipAmount': maximumTipAmount,
        'maximumTipPercentage': maximumTipPercentage,
        'currency': currency,
        'certificateFingerprint': certificateFingerprint
      };
}

class TerminalRuntimeState extends ImmutableModel {
  const TerminalRuntimeState(
      {required this.status,
      this.currentTransactionId,
      required this.paymentProcessor,
      required this.lastActivityAt,
      this.errorMessage});
  factory TerminalRuntimeState.ready(DateTime now) => TerminalRuntimeState(
      status: TerminalStatus.ready,
      paymentProcessor: 'HelloPay Simulator',
      lastActivityAt: now);
  factory TerminalRuntimeState.fromJson(Json j) => TerminalRuntimeState(
      status: TerminalStatusJson.fromJson(j['status']),
      currentTransactionId: j['currentTransactionId']?.toString(),
      paymentProcessor: _str(j['paymentProcessor']),
      lastActivityAt: _date(j['lastActivityAt']),
      errorMessage: j['errorMessage']?.toString());
  final TerminalStatus status;
  final String? currentTransactionId, errorMessage;
  final String paymentProcessor;
  final DateTime lastActivityAt;
  TerminalRuntimeState copyWith(
          {TerminalStatus? status,
          String? currentTransactionId,
          bool clearTransactionId = false,
          String? errorMessage,
          bool clearError = false,
          DateTime? lastActivityAt}) =>
      TerminalRuntimeState(
          status: status ?? this.status,
          currentTransactionId: clearTransactionId
              ? null
              : currentTransactionId ?? this.currentTransactionId,
          paymentProcessor: paymentProcessor,
          lastActivityAt: lastActivityAt ?? this.lastActivityAt,
          errorMessage: clearError ? null : errorMessage ?? this.errorMessage);
  @override
  Json toJson() => {
        'status': status.wire,
        'currentTransactionId': currentTransactionId,
        'paymentProcessor': paymentProcessor,
        'lastActivityAt': lastActivityAt.toIso8601String(),
        'errorMessage': errorMessage
      };
}

class OtpToken extends ImmutableModel {
  const OtpToken(
      {required this.value,
      required this.createdAt,
      required this.expiresAt,
      required this.isUsed});
  factory OtpToken.fromJson(Json j) => OtpToken(
      value: _str(j['value']),
      createdAt: _date(j['createdAt']),
      expiresAt: _date(j['expiresAt']),
      isUsed: _bool(j['isUsed']));
  final String value;
  final DateTime createdAt, expiresAt;
  final bool isUsed;
  bool isExpiredAt(DateTime now) => !now.isBefore(expiresAt);
  bool get isExpired => isExpiredAt(DateTime.now().toUtc());
  bool get isValid => !isUsed && !isExpired;
  Duration remainingDurationAt(DateTime now) =>
      isExpiredAt(now) ? Duration.zero : expiresAt.difference(now);
  Duration get remainingDuration => remainingDurationAt(DateTime.now().toUtc());
  OtpToken copyWith({bool? isUsed}) => OtpToken(
      value: value,
      createdAt: createdAt,
      expiresAt: expiresAt,
      isUsed: isUsed ?? this.isUsed);
  @override
  Json toJson() => {
        'value': value,
        'createdAt': createdAt.toIso8601String(),
        'expiresAt': expiresAt.toIso8601String(),
        'isUsed': isUsed
      };
}

class PairingSession extends ImmutableModel {
  const PairingSession(
      {required this.sessionId,
      required this.terminalId,
      required this.posId,
      required this.posName,
      required this.certificateFingerprint,
      required this.createdAt,
      required this.expiresAt,
      required this.isActive});
  factory PairingSession.fromJson(Json j) => PairingSession(
      sessionId: _str(j['sessionId']),
      terminalId: _str(j['terminalId']),
      posId: _str(j['posId']),
      posName: _str(j['posName']),
      certificateFingerprint: _str(j['certificateFingerprint']),
      createdAt: _date(j['createdAt']),
      expiresAt: _date(j['expiresAt']),
      isActive: _bool(j['isActive']));
  final String sessionId, terminalId, posId, posName, certificateFingerprint;
  final DateTime createdAt, expiresAt;
  final bool isActive;
  bool isValidAt(DateTime now) => isActive && now.isBefore(expiresAt);
  PairingSession copyWith({bool? isActive}) => PairingSession(
      sessionId: sessionId,
      terminalId: terminalId,
      posId: posId,
      posName: posName,
      certificateFingerprint: certificateFingerprint,
      createdAt: createdAt,
      expiresAt: expiresAt,
      isActive: isActive ?? this.isActive);
  @override
  Json toJson() => {
        'sessionId': sessionId,
        'terminalId': terminalId,
        'posId': posId,
        'posName': posName,
        'certificateFingerprint': certificateFingerprint,
        'createdAt': createdAt.toIso8601String(),
        'expiresAt': expiresAt.toIso8601String(),
        'isActive': isActive
      };
}

class PaymentRequest extends ImmutableModel {
  const PaymentRequest(
      {required this.requestId,
      required this.base,
      this.tip,
      required this.service,
      required this.paymentMethod,
      this.userCode,
      this.remoteIdentity});
  factory PaymentRequest.fromJson(Json j) => PaymentRequest(
      requestId: _str(j['requestId']),
      base: _num(j['base']),
      tip: j.containsKey('tip') && j['tip'] != null ? _num(j['tip']) : null,
      service: _num(j['service']),
      paymentMethod: PaymentMethodJson.fromJson(j['paymentMethod']),
      userCode: j['userCode']?.toString(),
      remoteIdentity: j['remoteIdentity']?.toString());
  final String requestId;
  final double base, service;
  final double? tip;
  final PaymentMethod paymentMethod;
  final String? userCode, remoteIdentity;
  bool get hasOmittedTip => tip == null;
  PaymentRequest copyWith(
          {String? requestId,
          double? base,
          double? tip,
          bool clearTip = false,
          double? service,
          PaymentMethod? paymentMethod}) =>
      PaymentRequest(
          requestId: requestId ?? this.requestId,
          base: base ?? this.base,
          tip: clearTip ? null : tip ?? this.tip,
          service: service ?? this.service,
          paymentMethod: paymentMethod ?? this.paymentMethod,
          userCode: userCode,
          remoteIdentity: remoteIdentity);
  @override
  Json toJson() => {
        'requestId': requestId,
        'base': base,
        if (tip != null) 'tip': tip,
        'service': service,
        'paymentMethod': paymentMethod.wire,
        'userCode': userCode,
        'remoteIdentity': remoteIdentity
      };
}

class RefundRequest extends ImmutableModel {
  const RefundRequest(
      {required this.requestId,
      required this.amount,
      required this.paymentMethod,
      required this.userCode,
      this.remoteIdentity,
      this.originalTransactionId});
  factory RefundRequest.fromJson(Json j) => RefundRequest(
      requestId: _str(j['requestId']),
      amount: _num(j['amount']),
      paymentMethod: PaymentMethodJson.fromJson(j['paymentMethod']),
      userCode: _str(j['userCode']),
      remoteIdentity: j['remoteIdentity']?.toString(),
      originalTransactionId: j['originalTransactionId']?.toString());
  final String requestId, userCode;
  final double amount;
  final PaymentMethod paymentMethod;
  final String? remoteIdentity, originalTransactionId;
  RefundRequest copyWith({double? amount}) => RefundRequest(
      requestId: requestId,
      amount: amount ?? this.amount,
      paymentMethod: paymentMethod,
      userCode: userCode,
      remoteIdentity: remoteIdentity,
      originalTransactionId: originalTransactionId);
  @override
  Json toJson() => {
        'requestId': requestId,
        'amount': amount,
        'paymentMethod': paymentMethod.wire,
        'userCode': userCode,
        'remoteIdentity': remoteIdentity,
        'originalTransactionId': originalTransactionId
      };
}

class VoidRequest extends ImmutableModel {
  const VoidRequest(
      {required this.requestId,
      required this.lastTransactionId,
      this.userCode});
  factory VoidRequest.fromJson(Json j) => VoidRequest(
      requestId: _str(j['requestId']),
      lastTransactionId: _str(j['lastTransactionId']),
      userCode: j['userCode']?.toString());
  final String requestId, lastTransactionId;
  final String? userCode;
  VoidRequest copyWith({String? userCode}) => VoidRequest(
      requestId: requestId,
      lastTransactionId: lastTransactionId,
      userCode: userCode ?? this.userCode);
  @override
  Json toJson() => {
        'requestId': requestId,
        'lastTransactionId': lastTransactionId,
        'userCode': userCode
      };
}

class ReceiptData extends ImmutableModel {
  const ReceiptData(
      {required this.type,
      required this.content,
      required this.mimeType,
      required this.createdAt});
  factory ReceiptData.fromJson(Json j) => ReceiptData(
      type: ReceiptTypeJson.fromJson(j['type']),
      content: _str(j['content']),
      mimeType: _str(j['mimeType']),
      createdAt: _date(j['createdAt']));
  final ReceiptType type;
  final String content, mimeType;
  final DateTime createdAt;
  ReceiptData copyWith({String? content}) => ReceiptData(
      type: type,
      content: content ?? this.content,
      mimeType: mimeType,
      createdAt: createdAt);
  @override
  Json toJson() => {
        'type': type.wire,
        'content': content,
        'mimeType': mimeType,
        'createdAt': createdAt.toIso8601String()
      };
}

class Transaction extends ImmutableModel {
  const Transaction(
      {required this.transactionId,
      required this.requestId,
      required this.externalId,
      required this.type,
      required this.status,
      required this.baseAmount,
      required this.tipAmount,
      required this.serviceAmount,
      required this.totalAmount,
      required this.refundedAmount,
      required this.paymentMethod,
      required this.paymentProcessor,
      required this.cardType,
      required this.maskedCardNumber,
      required this.cardNumberLast4,
      required this.requireSignature,
      this.userCode,
      this.remoteIdentity,
      required this.createdAt,
      this.completedAt,
      this.receiptData,
      this.errorCode,
      this.errorMessage});
  factory Transaction.fromJson(Json j) => Transaction(
      transactionId: _str(j['transactionId']),
      requestId: _str(j['requestId']),
      externalId: _str(j['externalId']),
      type: TransactionTypeJson.fromJson(j['type']),
      status: TransactionStatusJson.fromJson(j['status']),
      baseAmount: _num(j['baseAmount']),
      tipAmount: _num(j['tipAmount']),
      serviceAmount: _num(j['serviceAmount']),
      totalAmount: _num(j['totalAmount']),
      refundedAmount: _num(j['refundedAmount']),
      paymentMethod: PaymentMethodJson.fromJson(j['paymentMethod']),
      paymentProcessor: _str(j['paymentProcessor']),
      cardType: _str(j['cardType']),
      maskedCardNumber: _str(j['maskedCardNumber']),
      cardNumberLast4: _str(j['cardNumberLast4']),
      requireSignature: _bool(j['requireSignature']),
      userCode: j['userCode']?.toString(),
      remoteIdentity: j['remoteIdentity']?.toString(),
      createdAt: _date(j['createdAt']),
      completedAt: j['completedAt'] == null ? null : _date(j['completedAt']),
      receiptData: j['receiptData'] is Map
          ? ReceiptData.fromJson(
              Map<String, dynamic>.from(j['receiptData'] as Map))
          : null,
      errorCode: j['errorCode']?.toString(),
      errorMessage: j['errorMessage']?.toString());
  final String transactionId, requestId, externalId;
  final TransactionType type;
  final TransactionStatus status;
  final double baseAmount,
      tipAmount,
      serviceAmount,
      totalAmount,
      refundedAmount;
  final PaymentMethod paymentMethod;
  final String paymentProcessor, cardType, maskedCardNumber, cardNumberLast4;
  final bool requireSignature;
  final String? userCode, remoteIdentity;
  final DateTime createdAt;
  final DateTime? completedAt;
  final ReceiptData? receiptData;
  final String? errorCode, errorMessage;
  double get remainingRefundableAmount =>
      (totalAmount - refundedAmount).clamp(0, double.infinity);
  bool get isRefundable =>
      isSuccessful &&
      type == TransactionType.payment &&
      remainingRefundableAmount > 0;
  bool get isSuccessful => status == TransactionStatus.success;
  bool get isFinalState => switch (status) {
        TransactionStatus.pending || TransactionStatus.processing => false,
        _ => true
      };
  Transaction copyWith(
          {TransactionStatus? status,
          double? refundedAmount,
          DateTime? completedAt,
          ReceiptData? receiptData,
          String? errorCode,
          String? errorMessage}) =>
      Transaction(
          transactionId: transactionId,
          requestId: requestId,
          externalId: externalId,
          type: type,
          status: status ?? this.status,
          baseAmount: baseAmount,
          tipAmount: tipAmount,
          serviceAmount: serviceAmount,
          totalAmount: totalAmount,
          refundedAmount: refundedAmount ?? this.refundedAmount,
          paymentMethod: paymentMethod,
          paymentProcessor: paymentProcessor,
          cardType: cardType,
          maskedCardNumber: maskedCardNumber,
          cardNumberLast4: cardNumberLast4,
          requireSignature: requireSignature,
          userCode: userCode,
          remoteIdentity: remoteIdentity,
          createdAt: createdAt,
          completedAt: completedAt ?? this.completedAt,
          receiptData: receiptData ?? this.receiptData,
          errorCode: errorCode ?? this.errorCode,
          errorMessage: errorMessage ?? this.errorMessage);
  @override
  Json toJson() => {
        'transactionId': transactionId,
        'requestId': requestId,
        'externalId': externalId,
        'type': type.wire,
        'status': status.wire,
        'baseAmount': baseAmount,
        'tipAmount': tipAmount,
        'serviceAmount': serviceAmount,
        'totalAmount': totalAmount,
        'refundedAmount': refundedAmount,
        'paymentMethod': paymentMethod.wire,
        'paymentProcessor': paymentProcessor,
        'cardType': cardType,
        'maskedCardNumber': maskedCardNumber,
        'cardNumberLast4': cardNumberLast4,
        'requireSignature': requireSignature,
        'userCode': userCode,
        'remoteIdentity': remoteIdentity,
        'createdAt': createdAt.toIso8601String(),
        'completedAt': completedAt?.toIso8601String(),
        'receiptData': receiptData?.toJson(),
        'errorCode': errorCode,
        'errorMessage': errorMessage
      };
}

class SettlementReport extends ImmutableModel {
  const SettlementReport(
      {required this.reportId,
      required this.openedAt,
      required this.closedAt,
      required this.paymentCount,
      required this.refundCount,
      required this.voidCount,
      required this.grossAmount,
      required this.refundAmount,
      required this.netAmount,
      this.helloPayReceipt,
      this.otpReceipt});
  factory SettlementReport.fromJson(Json j) => SettlementReport(
      reportId: _str(j['reportId']),
      openedAt: _date(j['openedAt']),
      closedAt: _date(j['closedAt']),
      paymentCount: _int(j['paymentCount']),
      refundCount: _int(j['refundCount']),
      voidCount: _int(j['voidCount']),
      grossAmount: _num(j['grossAmount']),
      refundAmount: _num(j['refundAmount']),
      netAmount: _num(j['netAmount']),
      helloPayReceipt: j['helloPayReceipt']?.toString(),
      otpReceipt: j['otpReceipt']?.toString());
  final String reportId;
  final DateTime openedAt, closedAt;
  final int paymentCount, refundCount, voidCount;
  final double grossAmount, refundAmount, netAmount;
  final String? helloPayReceipt, otpReceipt;
  SettlementReport copyWith() => this;
  @override
  Json toJson() => {
        'reportId': reportId,
        'openedAt': openedAt.toIso8601String(),
        'closedAt': closedAt.toIso8601String(),
        'paymentCount': paymentCount,
        'refundCount': refundCount,
        'voidCount': voidCount,
        'grossAmount': grossAmount,
        'refundAmount': refundAmount,
        'netAmount': netAmount,
        'helloPayReceipt': helloPayReceipt,
        'otpReceipt': otpReceipt
      };
}

class ScenarioPreset extends ImmutableModel {
  const ScenarioPreset(
      {required this.id,
      required this.name,
      required this.description,
      required this.scenario,
      required this.delay,
      required this.terminalStatusBefore,
      required this.terminalStatusDuring,
      required this.terminalStatusAfter,
      required this.requiresPin,
      required this.pinBehavior,
      required this.requireSignature,
      required this.processor,
      this.responseErrorCode,
      this.responseErrorMessage,
      required this.receiptEnabled,
      this.customResponse});
  factory ScenarioPreset.fromJson(Json j) => ScenarioPreset(
      id: _str(j['id']),
      name: _str(j['name']),
      description: _str(j['description']),
      scenario: SimulatorScenarioJson.fromJson(j['scenario']),
      delay: Duration(milliseconds: _int(j['delayMs'])),
      terminalStatusBefore:
          TerminalStatusJson.fromJson(j['terminalStatusBefore']),
      terminalStatusDuring:
          TerminalStatusJson.fromJson(j['terminalStatusDuring']),
      terminalStatusAfter:
          TerminalStatusJson.fromJson(j['terminalStatusAfter']),
      requiresPin: _bool(j['requiresPin']),
      pinBehavior: PinBehaviorJson.fromJson(j['pinBehavior']),
      requireSignature: _bool(j['requireSignature']),
      processor: _str(j['processor'], 'HelloPay Simulator'),
      responseErrorCode: j['responseErrorCode']?.toString(),
      responseErrorMessage: j['responseErrorMessage']?.toString(),
      receiptEnabled: _bool(j['receiptEnabled'], true),
      customResponse: j['customResponse'] is Map
          ? Map<String, dynamic>.from(j['customResponse'] as Map)
          : null);
  final String id, name, description, processor;
  final SimulatorScenario scenario;
  final Duration delay;
  final TerminalStatus terminalStatusBefore,
      terminalStatusDuring,
      terminalStatusAfter;
  final bool requiresPin, requireSignature, receiptEnabled;
  final PinBehavior pinBehavior;
  final String? responseErrorCode, responseErrorMessage;
  final Json? customResponse;
  ScenarioPreset copyWith({
    SimulatorScenario? scenario,
    Duration? delay,
    TerminalStatus? terminalStatusBefore,
    TerminalStatus? terminalStatusDuring,
    TerminalStatus? terminalStatusAfter,
    bool? requiresPin,
    PinBehavior? pinBehavior,
    bool? requireSignature,
    String? processor,
    String? responseErrorCode,
    bool clearResponseErrorCode = false,
    String? responseErrorMessage,
    bool clearResponseErrorMessage = false,
    bool? receiptEnabled,
    Json? customResponse,
    bool clearCustomResponse = false,
  }) =>
      ScenarioPreset(
          id: id,
          name: name,
          description: description,
          scenario: scenario ?? this.scenario,
          delay: delay ?? this.delay,
          terminalStatusBefore:
              terminalStatusBefore ?? this.terminalStatusBefore,
          terminalStatusDuring:
              terminalStatusDuring ?? this.terminalStatusDuring,
          terminalStatusAfter: terminalStatusAfter ?? this.terminalStatusAfter,
          requiresPin: requiresPin ?? this.requiresPin,
          pinBehavior: pinBehavior ?? this.pinBehavior,
          requireSignature: requireSignature ?? this.requireSignature,
          processor: processor ?? this.processor,
          responseErrorCode: clearResponseErrorCode
              ? null
              : responseErrorCode ?? this.responseErrorCode,
          responseErrorMessage: clearResponseErrorMessage
              ? null
              : responseErrorMessage ?? this.responseErrorMessage,
          receiptEnabled: receiptEnabled ?? this.receiptEnabled,
          customResponse: clearCustomResponse
              ? null
              : customResponse ?? this.customResponse);
  @override
  Json toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'scenario': scenario.wire,
        'delayMs': delay.inMilliseconds,
        'terminalStatusBefore': terminalStatusBefore.wire,
        'terminalStatusDuring': terminalStatusDuring.wire,
        'terminalStatusAfter': terminalStatusAfter.wire,
        'requiresPin': requiresPin,
        'pinBehavior': pinBehavior.wire,
        'requireSignature': requireSignature,
        'processor': processor,
        'responseErrorCode': responseErrorCode,
        'responseErrorMessage': responseErrorMessage,
        'receiptEnabled': receiptEnabled,
        'customResponse': customResponse
      };
}

class DemoCard extends ImmutableModel {
  const DemoCard(
      {required this.id,
      required this.displayName,
      required this.cardholderName,
      required this.maskedPan,
      required this.last4,
      required this.cardType,
      required this.visualVariant,
      required this.interactionMethod,
      required this.supportedPaymentMethods,
      required this.requiresPin,
      this.correctPin,
      required this.pinBehavior,
      required this.defaultScenario,
      required this.requireSignature,
      required this.expiryLabel,
      required this.developerNotes});
  factory DemoCard.fromJson(Json j) => DemoCard(
      id: _str(j['id']),
      displayName: _str(j['displayName']),
      cardholderName: _str(j['cardholderName']),
      maskedPan: _str(j['maskedPan']),
      last4: _str(j['last4']),
      cardType: _str(j['cardType']),
      visualVariant: _str(j['visualVariant']),
      interactionMethod:
          CardInteractionMethodJson.fromJson(j['interactionMethod']),
      supportedPaymentMethods:
          (j['supportedPaymentMethods'] as List? ?? const [])
              .map(PaymentMethodJson.fromJson)
              .toSet(),
      requiresPin: _bool(j['requiresPin']),
      correctPin: j['correctPin']?.toString(),
      pinBehavior: PinBehaviorJson.fromJson(j['pinBehavior']),
      defaultScenario: SimulatorScenarioJson.fromJson(j['defaultScenario']),
      requireSignature: _bool(j['requireSignature']),
      expiryLabel: _str(j['expiryLabel']),
      developerNotes: _str(j['developerNotes']));
  final String id,
      displayName,
      cardholderName,
      maskedPan,
      last4,
      cardType,
      visualVariant,
      expiryLabel,
      developerNotes;
  final CardInteractionMethod interactionMethod;
  final Set<PaymentMethod> supportedPaymentMethods;
  final bool requiresPin, requireSignature;
  final String? correctPin;
  final PinBehavior pinBehavior;
  final SimulatorScenario defaultScenario;
  DemoCard copyWith() => this;
  @override
  Json toJson() => {
        'id': id,
        'displayName': displayName,
        'cardholderName': cardholderName,
        'maskedPan': maskedPan,
        'last4': last4,
        'cardType': cardType,
        'visualVariant': visualVariant,
        'interactionMethod': interactionMethod.wire,
        'supportedPaymentMethods':
            supportedPaymentMethods.map((e) => e.wire).toList(),
        'requiresPin': requiresPin,
        'correctPin': correctPin,
        'pinBehavior': pinBehavior.wire,
        'defaultScenario': defaultScenario.wire,
        'requireSignature': requireSignature,
        'expiryLabel': expiryLabel,
        'developerNotes': developerNotes
      };
}

class ApiRequestEnvelope<T> extends ImmutableModel {
  const ApiRequestEnvelope(
      {required this.requestId,
      required this.timestamp,
      required this.payload});
  final String requestId;
  final DateTime timestamp;
  final T payload;
  @override
  Json toJson() => {
        'requestId': requestId,
        'timestamp': timestamp.toIso8601String(),
        'payload': payload is ImmutableModel
            ? (payload as ImmutableModel).toJson()
            : payload
      };
}

class ApiResponseEnvelope<T> extends ImmutableModel {
  const ApiResponseEnvelope(
      {required this.requestId,
      this.errorCode,
      this.errorMessage,
      required this.timestamp,
      this.payload});
  final String requestId;
  final String? errorCode, errorMessage;
  final DateTime timestamp;
  final T? payload;
  bool get isSuccess => errorCode == null;
  @override
  Json toJson() => {
        'requestId': requestId,
        'errorCode': errorCode,
        'errorMessage': errorMessage,
        'timestamp': timestamp.toIso8601String(),
        'payload': payload is ImmutableModel
            ? (payload as ImmutableModel).toJson()
            : payload
      };
}
