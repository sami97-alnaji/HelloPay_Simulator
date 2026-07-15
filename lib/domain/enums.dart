enum TerminalStatus { ready, busy, errorState, inactive }

enum TransactionType { payment, refund, voidTransaction, topUp }

enum TransactionStatus {
  pending,
  processing,
  success,
  failed,
  cancelled,
  timedOut
}

enum PaymentMethod { auto, bank, szep, ep, softpos }

enum ReceiptType { text, image, base64, bitmap }

enum CardInteractionMethod { contactless, insert, swipe }

enum PinBehavior {
  notRequired,
  correct,
  failOnceThenSuccess,
  alwaysIncorrect,
  blocked
}

enum SimulatorScenario {
  success,
  userCancelled,
  transactionFailed,
  terminalBusy,
  requestTimeout,
  sessionExpired,
  permissionDenied,
  invalidAmount,
  negativeTip,
  unsupportedPaymentMethod,
  tipNotAllowed,
  tipExceedsLimit,
  refundFailed,
  voidFailed,
  appTerminated,
  networkError,
  pairingTokenInvalid,
  pairingTokenExpired,
  noLastTransaction,
  transactionIdMismatch,
  custom
}

enum SimulatorSpeed { instant, fast, realistic, slowTraining }

extension EnumWire<T extends Enum> on T {
  String get wire => switch (this) {
        TerminalStatus.errorState => 'ERROR_STATE',
        TransactionType.voidTransaction => 'VOID',
        _ => name
            .replaceAllMapped(RegExp(r'(?<!^)([A-Z])'), (m) => '_${m[1]}')
            .toUpperCase(),
      };
}

T parseEnum<T extends Enum>(Object? value, List<T> values, T fallback,
    {Map<String, T>? aliases}) {
  final text = value?.toString().trim().toUpperCase();
  if (text == null || text.isEmpty) return fallback;
  return aliases?[text] ??
      values.firstWhere(
        (item) => item.wire == text || item.name.toUpperCase() == text,
        orElse: () => fallback,
      );
}

extension TerminalStatusJson on TerminalStatus {
  static TerminalStatus fromJson(Object? value) =>
      parseEnum(value, TerminalStatus.values, TerminalStatus.inactive);
}

extension TransactionTypeJson on TransactionType {
  static TransactionType fromJson(Object? value) =>
      parseEnum(value, TransactionType.values, TransactionType.payment);
}

extension TransactionStatusJson on TransactionStatus {
  static TransactionStatus fromJson(Object? value) =>
      parseEnum(value, TransactionStatus.values, TransactionStatus.pending);
}

extension PaymentMethodJson on PaymentMethod {
  static PaymentMethod fromJson(Object? value) =>
      parseEnum(value, PaymentMethod.values, PaymentMethod.auto);
}

extension ReceiptTypeJson on ReceiptType {
  static ReceiptType fromJson(Object? value) =>
      parseEnum(value, ReceiptType.values, ReceiptType.text);
}

extension CardInteractionMethodJson on CardInteractionMethod {
  static CardInteractionMethod fromJson(Object? value) => parseEnum(
      value, CardInteractionMethod.values, CardInteractionMethod.contactless);
}

extension PinBehaviorJson on PinBehavior {
  static PinBehavior fromJson(Object? value) =>
      parseEnum(value, PinBehavior.values, PinBehavior.notRequired);
}

extension SimulatorScenarioJson on SimulatorScenario {
  static SimulatorScenario fromJson(Object? value) =>
      parseEnum(value, SimulatorScenario.values, SimulatorScenario.custom);
}

extension SimulatorSpeedJson on SimulatorSpeed {
  static SimulatorSpeed fromJson(Object? value) =>
      parseEnum(value, SimulatorSpeed.values, SimulatorSpeed.realistic);
}
