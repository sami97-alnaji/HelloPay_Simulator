import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hellopay_simulator/app/simulator_app.dart';
import 'package:hellopay_simulator/domain/demo_data.dart';
import 'package:hellopay_simulator/domain/enums.dart';
import 'package:hellopay_simulator/domain/models.dart';
import 'package:hellopay_simulator/screens/terminal_screens.dart';
import 'package:hellopay_simulator/state/simulator_controller.dart';
import 'package:hellopay_simulator/state/simulator_providers.dart';
import 'package:hellopay_simulator/widgets/terminal_widgets.dart';

void main() {
  PaymentRequest request({double base = 1000, double? tip}) => PaymentRequest(
      requestId: 'REQ-UI',
      base: base,
      tip: tip,
      service: 0,
      paymentMethod: PaymentMethod.bank);

  Widget testApp(Widget child, SimulatorController controller) =>
      ProviderScope(overrides: [
        simulatorControllerProvider.overrideWith((ref) => controller)
      ], child: MaterialApp(home: child));

  testWidgets('app starts on splash then standby', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: HelloPaySimulatorApp()));
    expect(find.text('Development & Demo Terminal Simulator'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 801));
    await tester.pumpAndSettle();
    expect(find.text('Standby terminal'), findsOneWidget);
  });

  testWidgets('standby reflects READY', (tester) async {
    await tester.pumpWidget(testApp(const HomeScreen(), SimulatorController()));
    expect(find.text('READY'), findsWidgets);
  });

  testWidgets('pairing OTP generation updates the pairing screen',
      (tester) async {
    final controller = SimulatorController();
    await tester.pumpWidget(testApp(const PairingScreen(), controller));
    await tester.tap(find.text('Generate Pairing Code'));
    await tester.pump();
    expect(controller.engine.otp, isNotNull);
    expect(find.text('PAIRING CODE'), findsOneWidget);
  });

  test('successful pairing creates an active session', () {
    final controller = SimulatorController();
    final token = controller.generateOtp();
    final result = controller.pair(
        token: token.value, posId: 'POS-1', posName: 'Checkout');
    expect(result.isSuccess, isTrue);
    expect(controller.engine.isSessionValid, isTrue);
  });

  testWidgets('payment entry validation rejects zero base amount',
      (tester) async {
    await tester
        .pumpWidget(testApp(const PaymentEntryScreen(), SimulatorController()));
    await tester.enterText(find.widgetWithText(TextFormField, '12500'), '0');
    await tester.tap(find.text('Start Payment'));
    await tester.pump();
    expect(find.text('Enter an amount greater than zero'), findsOneWidget);
  });

  test('omitted tip mode creates a request without a tip key', () {
    final value = request(tip: null);
    expect(value.hasOmittedTip, isTrue);
    expect(value.toJson().containsKey('tip'), isFalse);
  });

  test('explicit zero tip mode retains a zero tip key', () {
    final value = request(tip: 0);
    expect(value.hasOmittedTip, isFalse);
    expect(value.toJson()['tip'], 0);
  });

  test('card selection updates controller and shared engine', () {
    final controller = SimulatorController();
    final card = DemoCards.all.firstWhere((c) => c.id == 'declined');
    controller.selectCard(card);
    expect(controller.selectedCard, card);
    expect(controller.engine.selectedCard, card);
  });

  testWidgets('test card library supports search and selected indicator',
      (tester) async {
    final controller = SimulatorController();
    tester.view.physicalSize = const Size(800, 1280);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(testApp(const CardsScreen(), controller));
    expect(find.text('SELECTED'), findsOneWidget);
    await tester.enterText(find.byType(TextField).first, 'Declined');
    await tester.pump();
    expect(find.text('Demo Declined'), findsOneWidget);
  });

  test('PIN required cards and scenarios are detected', () {
    final controller = SimulatorController();
    controller
        .selectCard(DemoCards.all.firstWhere((c) => c.id == 'mastercard-pin'));
    expect(controller.selectedCard.requiresPin, isTrue);
  });

  test('no-PIN card skips PIN requirement', () {
    final controller = SimulatorController();
    controller
        .selectCard(DemoCards.all.firstWhere((c) => c.id == 'visa-approved'));
    expect(controller.selectedCard.requiresPin, isFalse);
    expect(controller.selectedScenario.requiresPin, isFalse);
  });

  test('wrong PIN once then success behavior is preserved', () {
    final controller = SimulatorController();
    controller.selectCard(DemoCards.all.firstWhere((c) => c.id == 'pin-retry'));
    controller.preparePayment(request());
    for (final digit in '0000'.split('')) {
      controller.appendPin(digit);
    }
    expect(controller.submitPin(), isFalse);
    for (final digit in '1234'.split('')) {
      controller.appendPin(digit);
    }
    expect(controller.submitPin(), isTrue);
  });

  test('PIN blocked scenario overrides the selected card behavior', () {
    final controller = SimulatorController();
    controller.selectCard(
        DemoCards.all.firstWhere((card) => card.id == 'mastercard-pin'));
    controller.selectScenario(ScenarioPresets.all
        .firstWhere((scenario) => scenario.id == 'pin-blocked'));
    controller.preparePayment(request());
    for (final digit in '1234'.split('')) {
      controller.appendPin(digit);
    }
    expect(controller.effectivePinBehavior, PinBehavior.blocked);
    expect(controller.submitPin(), isFalse);
  });

  test('payment executes only once', () async {
    final controller = SimulatorController()..speed = SimulatorSpeed.instant;
    controller.preparePayment(request());
    await Future.wait(
        [controller.executePaymentOnce(), controller.executePaymentOnce()]);
    expect(controller.engine.transactionHistory, hasLength(1));
  });

  test('approved result is retained and terminal returns to READY', () async {
    final controller = SimulatorController()..speed = SimulatorSpeed.instant;
    controller.preparePayment(request());
    await controller.executePaymentOnce();
    expect(controller.resultTransaction?.isSuccessful, isTrue);
    expect(controller.engine.runtimeState.status, TerminalStatus.ready);
  });

  test('declined result is represented as a failed transaction', () async {
    final controller = SimulatorController()..speed = SimulatorSpeed.instant;
    controller.selectScenario(
        ScenarioPresets.all.firstWhere((s) => s.id == 'rejected'));
    controller.preparePayment(request());
    await controller.executePaymentOnce();
    expect(controller.resultTransaction?.status, TransactionStatus.failed);
    expect(controller.resultError, isNotNull);
  });

  test('customer-cancelled result remains auditable', () async {
    final controller = SimulatorController()..speed = SimulatorSpeed.instant;
    controller.selectScenario(
        ScenarioPresets.all.firstWhere((s) => s.id == 'cancelled'));
    controller.preparePayment(request());
    await controller.executePaymentOnce();
    expect(controller.resultTransaction?.status, TransactionStatus.cancelled);
    expect(controller.engine.transactionHistory, hasLength(1));
  });

  test('timeout result exposes recovery state and restores READY', () async {
    final controller = SimulatorController()..speed = SimulatorSpeed.instant;
    controller.selectScenario(
        ScenarioPresets.all.firstWhere((s) => s.id == 'timeout'));
    controller.preparePayment(request());
    await controller.executePaymentOnce();
    expect(controller.resultTransaction?.status, TransactionStatus.timedOut);
    expect(controller.engine.runtimeState.status, TerminalStatus.ready);
  });

  testWidgets('receipt displays the prominent demo warning', (tester) async {
    final controller = SimulatorController();
    controller.resultTransaction =
        controller.engine.processPayment(request()).value;
    await tester.pumpWidget(testApp(const ReceiptScreen(), controller));
    expect(find.text('DEMO RECEIPT — NOT A REAL PAYMENT'), findsOneWidget);
  });

  testWidgets('scenario studio shows selection and state transitions',
      (tester) async {
    tester.view.physicalSize = const Size(800, 1280);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
        testApp(const ScenarioStudioScreen(), SimulatorController()));
    expect(find.text('Scenario preset'), findsOneWidget);
    expect(find.text('Expected flow preview'), findsOneWidget);
    expect(find.text('Before'), findsOneWidget);
  });

  testWidgets('transaction appears in history', (tester) async {
    final controller = SimulatorController();
    controller.engine.processPayment(request());
    await tester.pumpWidget(testApp(const HistoryScreen(), controller));
    expect(find.textContaining('PAYMENT •'), findsOneWidget);
    expect(find.textContaining('REQ-UI'), findsOneWidget);
  });

  test('reset simulator clears transaction and session state', () async {
    final controller = SimulatorController()..speed = SimulatorSpeed.instant;
    final token = controller.generateOtp();
    controller.pair(token: token.value, posId: 'P', posName: 'POS');
    controller.preparePayment(request());
    await controller.executePaymentOnce();
    controller.reset();
    expect(controller.engine.transactionHistory, isEmpty);
    expect(controller.engine.pairingSession, isNull);
    expect(controller.engine.runtimeState.status, TerminalStatus.ready);
  });

  testWidgets('phone and tablet home layouts render without overflow',
      (tester) async {
    for (final size in const [
      Size(360, 800),
      Size(390, 844),
      Size(600, 960),
      Size(800, 1280)
    ]) {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      await tester
          .pumpWidget(testApp(const HomeScreen(), SimulatorController()));
      expect(find.text('Standby terminal'), findsOneWidget,
          reason: 'layout at $size');
    }
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  });

  test('rebuild-style duplicate execution does not duplicate payment',
      () async {
    final controller = SimulatorController()..speed = SimulatorSpeed.instant;
    controller.preparePayment(request());
    await controller.executePaymentOnce();
    await controller.executePaymentOnce();
    await controller.executePaymentOnce();
    expect(controller.engine.transactionHistory, hasLength(1));
  });

  test('custom approved JSON executes only after valid configuration',
      () async {
    final controller = SimulatorController()..speed = SimulatorSpeed.instant;
    final custom = ScenarioPresets.all.firstWhere((s) => s.id == 'custom');
    controller.selectScenario(custom.copyWith(
        delay: Duration.zero,
        customResponse: const {'status': 'APPROVED', 'demo': true}));
    controller.preparePayment(request());
    await controller.executePaymentOnce();
    expect(controller.resultTransaction?.isSuccessful, isTrue);
  });

  testWidgets('refund and void results use transaction-specific wording',
      (tester) async {
    final controller = SimulatorController();
    final sale = controller.engine.processPayment(request()).value!;
    final refund = controller.engine
        .processRefund(RefundRequest(
            requestId: 'REF-1',
            amount: 100,
            paymentMethod: PaymentMethod.bank,
            userCode: 'demo',
            originalTransactionId: sale.transactionId))
        .value!;
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(body: TransactionResultView(transaction: refund))));
    expect(find.text('Refund successful'), findsOneWidget);

    final voidController = SimulatorController();
    final voidSale = voidController.engine.processPayment(request()).value!;
    final voidTransaction = voidController.engine
        .voidLastTransaction(VoidRequest(
            requestId: 'VOID-1', lastTransactionId: voidSale.transactionId))
        .value!;
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: TransactionResultView(transaction: voidTransaction))));
    expect(find.text('Void successful'), findsOneWidget);
  });

  test('controller exposes refund, void mismatch and settlement UI operations',
      () {
    final refundController = SimulatorController();
    final refundableSale =
        refundController.engine.processPayment(request()).value!;
    refundController.refundTransaction(refundableSale);
    expect(refundController.resultType, TransactionType.refund);
    expect(refundController.resultTransaction?.type, TransactionType.refund);

    final voidController = SimulatorController();
    final voidSale = voidController.engine.processPayment(request()).value!;
    voidController.voidTransaction(voidSale, mismatchedId: true);
    expect(voidController.resultType, TransactionType.voidTransaction);
    expect(voidController.resultTransaction, isNull);
    expect(voidController.resultError?.code, 2004);

    voidController.voidTransaction(voidSale);
    expect(voidController.resultTransaction?.type,
        TransactionType.voidTransaction);
    voidController.closeBatch();
    expect(voidController.settlementReport?.paymentCount, 1);
    expect(voidController.settlementReport?.voidCount, 1);
  });

  testWidgets('transaction detail exposes Android financial actions',
      (tester) async {
    final controller = SimulatorController();
    final sale = controller.engine.processPayment(request()).value!;
    await tester.pumpWidget(testApp(
        TransactionDetailScreen(transactionId: sale.transactionId),
        controller));
    expect(find.text('Refund remaining amount'), findsOneWidget);
    expect(find.text('Void this transaction'), findsOneWidget);
    expect(find.text('Test void ID mismatch'), findsOneWidget);
  });

  testWidgets('failed refund retains refund-specific result wording',
      (tester) async {
    final controller = SimulatorController();
    final sale = controller.engine.processPayment(request()).value!;
    controller.selectScenario(ScenarioPresets.all
        .firstWhere((scenario) => scenario.id == 'refund-failed'));
    controller.refundTransaction(sale);
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: TransactionResultView(
                error: controller.resultError,
                expectedType: controller.resultType))));
    expect(find.text('Refund failed'), findsOneWidget);
    expect(find.text('The request could not be completed.'), findsOneWidget);
  });

  testWidgets('settlement report renders shared-engine totals', (tester) async {
    final controller = SimulatorController();
    controller.engine.processPayment(request());
    controller.closeBatch();
    await tester
        .pumpWidget(testApp(const SettlementReportScreen(), controller));
    expect(find.text('Batch closed successfully'), findsOneWidget);
    expect(find.text('1'), findsOneWidget);
    expect(find.text('1 000 HUF'), findsWidgets);
  });

  testWidgets('receipt includes refunded amount when relevant', (tester) async {
    final controller = SimulatorController();
    final sale = controller.engine.processPayment(request()).value!;
    controller.engine.processRefund(RefundRequest(
        requestId: 'REF-2',
        amount: 250,
        paymentMethod: PaymentMethod.bank,
        userCode: 'demo',
        originalTransactionId: sale.transactionId));
    final updatedSale = controller.engine.transactionHistory.first;
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(body: ReceiptPaper(transaction: updatedSale))));
    expect(find.textContaining('Refunded: 250 HUF'), findsOneWidget);
  });

  test('HUF money formatting uses grouped Hungarian presentation', () {
    expect(money(12500), '12 500 HUF');
    expect(money(12500.5), '12 500,50 HUF');
    expect(money(-1000), '-1 000 HUF');
  });

  testWidgets('contactless fallback exposes the chip recovery state',
      (tester) async {
    final controller = SimulatorController();
    controller.selectCard(
        DemoCards.all.firstWhere((card) => card.id == 'contactless-fallback'));
    controller.preparePayment(request());
    await tester
        .pumpWidget(testApp(const CardPresentationScreen(), controller));
    expect(find.text('Tap card'), findsWidgets);
    await tester.tap(find.text('Tap card').last);
    await tester.pump();
    expect(find.text('Contactless failed'), findsOneWidget);
    expect(find.text('Use chip instead'), findsWidgets);
  });

  testWidgets('terminal reader remains bounded on a phone viewport',
      (tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final controller = SimulatorController()..preparePayment(request());
    await tester
        .pumpWidget(testApp(const CardPresentationScreen(), controller));
    expect(find.byType(TerminalReaderScene), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
