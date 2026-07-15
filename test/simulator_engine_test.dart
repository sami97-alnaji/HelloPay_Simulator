import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:hellopay_simulator/domain/demo_data.dart';
import 'package:hellopay_simulator/domain/enums.dart';
import 'package:hellopay_simulator/domain/models.dart';
import 'package:hellopay_simulator/domain/simulator_engine.dart';
import 'package:hellopay_simulator/domain/simulator_error.dart';

void main() {
  late DateTime now;
  late SimulatorEngine engine;
  setUp(() {
    now = DateTime.utc(2026, 7, 15, 12);
    engine = SimulatorEngine(clock: () => now, random: Random(1));
  });
  PaymentRequest payment(
          {double base = 1000,
          double? tip = 0,
          PaymentMethod method = PaymentMethod.bank}) =>
      PaymentRequest(
          requestId: 'req',
          base: base,
          tip: tip,
          service: 0,
          paymentMethod: method);
  test('enum serialization is safe', () {
    expect(TerminalStatus.errorState.wire, 'ERROR_STATE');
    expect(TerminalStatusJson.fromJson('bad'), TerminalStatus.inactive);
    expect(
        TransactionTypeJson.fromJson('VOID'), TransactionType.voidTransaction);
  });
  test('OTP expires and is one-time use', () {
    final otp = engine.generateOtp(validFor: const Duration(minutes: 1));
    expect(engine.validatePairingToken(otp.value).isSuccess, true);
    expect(engine.validatePairingToken(otp.value).error!.code, 3001);
    now = now.add(const Duration(minutes: 2));
    expect(otp.isExpiredAt(now), true);
  });
  test('pairing success, invalid, and expired', () {
    final otp = engine.generateOtp();
    expect(
        engine
            .createPairingSession(
                token: otp.value, posId: 'pos', posName: 'POS')
            .isSuccess,
        true);
    expect(
        engine
            .createPairingSession(token: 'bad', posId: 'p', posName: 'P')
            .error!
            .code,
        3001);
    final expired = engine.generateOtp(validFor: Duration.zero);
    expect(engine.validatePairingToken(expired.value).error!.code, 3002);
  });
  test('successful payment restores ready state', () {
    final r = engine.processPayment(payment());
    expect(r.isSuccess, true);
    expect(r.value!.isSuccessful, true);
    expect(engine.runtimeState.status, TerminalStatus.ready);
  });
  test('amount, negative tip, omitted versus zero, and SZEP tip validation',
      () {
    expect(engine.processPayment(payment(base: 0)).error!.code, 1002);
    expect(engine.processPayment(payment(tip: -1)).error!.code, 1003);
    expect(payment(tip: null).hasOmittedTip, true);
    expect(payment(tip: 0).hasOmittedTip, false);
    engine.selectedCard = DemoCards.all.firstWhere((c) => c.id == 'szep');
    expect(
        engine
            .processPayment(payment(method: PaymentMethod.szep, tip: 1))
            .error!
            .code,
        1005);
  });
  test('terminal busy and cancellation are preserved', () {
    engine.runtimeState =
        engine.runtimeState.copyWith(status: TerminalStatus.busy);
    expect(engine.processPayment(payment()).error!.code, 1011);
    engine.runtimeState =
        engine.runtimeState.copyWith(status: TerminalStatus.ready);
    engine.selectedScenario =
        ScenarioPresets.all.firstWhere((p) => p.id == 'cancelled');
    expect(engine.processPayment(payment()).error!.code, 1004);
    expect(engine.transactionHistory.last.status, TransactionStatus.cancelled);
  });
  test('refund honors remaining amount', () {
    final sale = engine.processPayment(payment()).value!;
    final refund = engine.processRefund(RefundRequest(
        requestId: 'refund',
        amount: 500,
        paymentMethod: PaymentMethod.bank,
        userCode: 'u',
        originalTransactionId: sale.transactionId));
    expect(refund.isSuccess, true);
    expect(
        engine
            .processRefund(RefundRequest(
                requestId: 'r2',
                amount: 600,
                paymentMethod: PaymentMethod.bank,
                userCode: 'u',
                originalTransactionId: sale.transactionId))
            .error!
            .code,
        2001);
  });
  test('void succeeds, mismatched ID and absent transaction fail', () {
    expect(
        engine
            .voidLastTransaction(
                const VoidRequest(requestId: 'v', lastTransactionId: 'x'))
            .error!
            .code,
        2005);
    final sale = engine.processPayment(payment()).value!;
    expect(
        engine
            .voidLastTransaction(
                const VoidRequest(requestId: 'v', lastTransactionId: 'wrong'))
            .error!
            .code,
        2004);
    expect(
        engine
            .voidLastTransaction(VoidRequest(
                requestId: 'v', lastTransactionId: sale.transactionId))
            .isSuccess,
        true);
  });
  test('session expiry, error catalog, and timeout state restoration', () {
    final otp = engine.generateOtp(validFor: const Duration(minutes: 1));
    engine.createPairingSession(
        token: otp.value,
        posId: 'p',
        posName: 'p',
        validFor: const Duration(minutes: 1));
    now = now.add(const Duration(minutes: 2));
    expect(engine.processPayment(payment(), sessionRequired: true).error!.code,
        3004);
    expect(ErrorCatalog.lookup(2004).name, 'transactionIdMismatch');
    engine.selectedScenario =
        ScenarioPresets.all.firstWhere((p) => p.id == 'timeout');
    expect(engine.processPayment(payment()).error!.code, 3012);
    expect(engine.runtimeState.status, TerminalStatus.ready);
  });
}
