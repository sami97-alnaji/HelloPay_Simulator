import 'models.dart';

class SimulatorError extends ImmutableModel {
  const SimulatorError(
      {required this.code,
      required this.name,
      required this.developerMessage,
      required this.userMessage,
      required this.recoverable,
      required this.recommendedAction});
  final int code;
  final String name, developerMessage, userMessage, recommendedAction;
  final bool recoverable;
  @override
  Json toJson() => {
        'code': code,
        'name': name,
        'developerMessage': developerMessage,
        'userMessage': userMessage,
        'recoverable': recoverable,
        'recommendedAction': recommendedAction
      };
}

abstract final class ErrorCatalog {
  static final Map<int, SimulatorError> _items = {
    1000: _e(1000, 'generalError'),
    1001: _e(1001, 'unsupportedPaymentMethod'),
    1002: _e(1002, 'invalidAmount'),
    1003: _e(1003, 'negativeTip'),
    1004: _e(1004, 'userInterrupted'),
    1005: _e(1005, 'tipNotAllowedForPaymentMethod'),
    1006: _e(1006, 'notAuthenticated'),
    1007: _e(1007, 'internalError'),
    1008: _e(1008, 'unsupportedAction'),
    1009: _e(1009, 'notInIntegrationMode'),
    1010: _e(1010, 'appTerminated'),
    1011: _e(1011, 'terminalBusy'),
    1012: _e(1012, 'tipExceedsLimit'),
    1101: _e(1101, 'permissionCheckUnavailable'),
    1102: _e(1102, 'permissionDenied'),
    1201: _e(1201, 'authenticationFailed'),
    1202: _e(1202, 'invalidCredentials'),
    1203: _e(1203, 'userNotFound'),
    2000: _e(2000, 'transactionFailed'),
    2001: _e(2001, 'refundFailed'),
    2002: _e(2002, 'voidFailed'),
    2003: _e(2003, 'missingTransactionId'),
    2004: _e(2004, 'transactionIdMismatch'),
    2005: _e(2005, 'noLastTransaction'),
    2006: _e(2006, 'actionInProgress'),
    3001: _e(3001, 'pairingTokenInvalid'),
    3002: _e(3002, 'pairingTokenExpired'),
    3003: _e(3003, 'keyExchangeFailed'),
    3004: _e(3004, 'sessionExpired'),
    3005: _e(3005, 'sessionNotFound'),
    3006: _e(3006, 'decryptionFailed'),
    3007: _e(3007, 'encryptionFailed'),
    3008: _e(3008, 'invalidSignature'),
    3009: _e(3009, 'deviceNotPaired'),
    3010: _e(3010, 'networkError'),
    3011: _e(3011, 'invalidRequest'),
    3012: _e(3012, 'requestTimeout'),
    3013: _e(3013, 'contextRecoveryFailed'),
  };
  static SimulatorError _e(int code, String name) => SimulatorError(
      code: code,
      name: name,
      developerMessage: 'Simulator error $code: $name.',
      userMessage: _user(name),
      recoverable: !const {1007, 1010, 3006, 3007}.contains(code),
      recommendedAction: 'Review the request and retry when appropriate.');
  static String _user(String name) => switch (name) {
        'invalidAmount' => 'Enter an amount greater than zero.',
        'terminalBusy' => 'The terminal is busy. Please wait.',
        'permissionDenied' => 'Permission was denied.',
        'transactionIdMismatch' =>
          'The transaction ID does not match the last eligible transaction.',
        'noLastTransaction' => 'There is no transaction available to void.',
        _ => 'The request could not be completed.'
      };
  static SimulatorError lookup(int code) => _items[code] ?? _items[1000]!;
  static List<SimulatorError> get all => List.unmodifiable(_items.values);
}
