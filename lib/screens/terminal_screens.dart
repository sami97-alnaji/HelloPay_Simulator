import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../api/api_controller.dart';
import '../domain/demo_data.dart';
import '../domain/enums.dart';
import '../domain/models.dart';
import '../domain/simulator_engine.dart';
import '../state/simulator_controller.dart';
import '../state/simulator_providers.dart';
import '../theme/app_theme.dart';
import '../widgets/terminal_widgets.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  Timer? _timer;
  @override
  void initState() {
    super.initState();
    _timer = Timer(const Duration(milliseconds: 800), () {
      if (mounted) context.go('/home');
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        body: Stack(children: [
          const Positioned.fill(
              child: ColoredBox(color: AppColors.hpSurfaceMuted)),
          Positioned.fill(child: CustomPaint(painter: _SplashPainter())),
          Center(
              child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Container(
                  width: 92,
                  height: 92,
                  decoration: const BoxDecoration(
                      color: AppColors.hpOrange, shape: BoxShape.circle),
                  child: const Icon(Icons.point_of_sale_rounded,
                      size: 48, color: Colors.white)),
              const SizedBox(height: 24),
              const Text('HelloPay Simulator',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900)),
              const SizedBox(height: 8),
              const Text('Development & Demo Terminal Simulator',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: AppColors.hpTextMuted)),
              const SizedBox(height: 32),
              const SizedBox(
                  width: 160,
                  child: LinearProgressIndicator(
                      color: AppColors.hpOrange,
                      backgroundColor: AppColors.hpBorder)),
              const SizedBox(height: 16),
              const Text('Version 0.1.0',
                  style: TextStyle(color: AppColors.hpTextMuted)),
            ]),
          )),
        ]),
      );
}

class _SplashPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawCircle(
        Offset(size.width * .86, size.height * .18),
        size.shortestSide * .34,
        Paint()..color = AppColors.hpYellowGreen.withValues(alpha: .45));
    canvas.drawCircle(
        Offset(size.width * .06, size.height * .9),
        size.shortestSide * .3,
        Paint()..color = AppColors.hpGreen.withValues(alpha: .25));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.watch(simulatorControllerProvider);
    final api = ref.watch(apiControllerProvider);
    final engine = controller.engine;
    final tx = engine.lastTransaction;
    final wide = MediaQuery.sizeOf(context).width >= 700;
    const actions = [
      _HomeAction('Scenario Studio', Icons.tune_rounded, '/scenarios'),
      _HomeAction('Test Cards', Icons.credit_card_rounded, '/cards'),
      _HomeAction(
          'Transaction History', Icons.receipt_long_rounded, '/history'),
      _HomeAction('Terminal Settings', Icons.settings_rounded, '/settings'),
      _HomeAction('Local API Monitor', Icons.lan_rounded, '/api-monitor'),
      _HomeAction(
          'Developer Documentation', Icons.code_rounded, '/developer-docs'),
    ];
    return TerminalPageScaffold(
      title: 'Standby terminal',
      subtitle: 'Ready for integration and customer-flow testing',
      status: engine.runtimeState.status,
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        _ResponsivePair(
            wide: wide,
            firstFlex: 3,
            secondFlex: 2,
            first: TerminalPanel(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                  const Text('Terminal identity',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 16),
                  _DataRow('Terminal ID', engine.config.terminalId),
                  _DataRow('Device name', engine.config.deviceName),
                  _DataRow(
                      'Integration mode',
                      engine.config.integrationModeEnabled
                          ? 'Enabled'
                          : 'Disabled'),
                  _DataRow(
                      'API simulator mode',
                      api.isRunning
                          ? 'Listening on ${api.server.boundPort}'
                          : 'Stopped'),
                  _DataRow(
                      'Pairing state',
                      engine.pairingSession == null
                          ? 'Not paired'
                          : engine.isSessionValid
                              ? 'Paired'
                              : 'Expired'),
                  _DataRow('Session state',
                      engine.isSessionValid ? 'Active' : 'Inactive'),
                ])),
            second: TerminalPanel(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                  const Text('Last transaction',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 16),
                  if (tx == null)
                    const Padding(
                        padding: EdgeInsets.symmetric(vertical: 20),
                        child: Text('No transactions yet',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: AppColors.hpTextMuted)))
                  else ...[
                    AmountDisplay(
                        amount: tx.totalAmount, label: tx.status.wire),
                    const SizedBox(height: 8),
                    Text('${tx.cardType} • ${tx.cardNumberLast4}',
                        textAlign: TextAlign.center),
                    TextButton(
                        onPressed: () =>
                            context.push('/history/${tx.transactionId}'),
                        child: const Text('View details')),
                  ],
                ]))),
        const SizedBox(height: 16),
        _ResponsivePair(
          wide: wide,
          first: PrimaryTerminalButton(
              label: 'Pair Device',
              icon: Icons.link_rounded,
              onPressed: () => context.push('/pairing')),
          second: SecondaryTerminalButton(
              label: 'Start Test Payment',
              icon: Icons.payments_rounded,
              onPressed: () => context.push('/payment')),
        ),
        const SizedBox(height: 24),
        GridView.count(
            crossAxisCount: wide ? 3 : 1,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: wide ? 2.6 : 3.2,
            children: actions.map((a) => _ActionCard(action: a)).toList()),
      ]),
    );
  }
}

class _HomeAction {
  const _HomeAction(this.label, this.icon, this.path);
  final String label, path;
  final IconData icon;
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({required this.action});
  final _HomeAction action;
  @override
  Widget build(BuildContext context) => InkWell(
        onTap: () => context.push(action.path),
        borderRadius: BorderRadius.circular(12),
        child: TerminalPanel(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(children: [
              Icon(action.icon, color: AppColors.hpOrange),
              const SizedBox(width: 12),
              Expanded(
                  child: Text(action.label,
                      style: const TextStyle(fontWeight: FontWeight.w700))),
              const Icon(Icons.chevron_right_rounded)
            ])),
      );
}

class PairingScreen extends ConsumerStatefulWidget {
  const PairingScreen({super.key});
  @override
  ConsumerState<PairingScreen> createState() => _PairingScreenState();
}

class _PairingScreenState extends ConsumerState<PairingScreen> {
  final posId = TextEditingController(text: 'POS-DEMO-01');
  final posName = TextEditingController(text: 'Demo Checkout');
  final otp = TextEditingController();
  Timer? ticker;
  String? error;
  @override
  void initState() {
    super.initState();
    ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    ticker?.cancel();
    posId.dispose();
    posName.dispose();
    otp.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = ref.watch(simulatorControllerProvider);
    final engine = controller.engine;
    final token = engine.otp;
    final session = engine.pairingSession;
    final wide = MediaQuery.sizeOf(context).width >= 700;
    if (session != null && engine.isSessionValid) {
      return TerminalPageScaffold(
          title: 'Pairing complete',
          subtitle: 'The simulated POS can now open a terminal session',
          status: engine.runtimeState.status,
          child: TerminalPanel(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                const Icon(Icons.verified_rounded,
                    color: AppColors.hpSuccess, size: 72),
                const Text('Device paired successfully',
                    textAlign: TextAlign.center,
                    style:
                        TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
                const SizedBox(height: 20),
                _DataRow('Session ID', session.sessionId),
                _DataRow('Terminal ID', session.terminalId),
                _DataRow('POS', '${session.posName} (${session.posId})'),
                _DataRow('Certificate', _mask(session.certificateFingerprint)),
                _DataRow('Expires', session.expiresAt.toLocal().toString()),
                const SizedBox(height: 18),
                PrimaryTerminalButton(
                    label: 'Return to Terminal',
                    onPressed: () => context.go('/home')),
              ])));
    }
    final remaining = token?.remainingDuration.inSeconds ?? 0;
    return TerminalPageScaffold(
        title: 'Pair device',
        subtitle: 'Generate and validate a short-lived development OTP',
        status: engine.runtimeState.status,
        child: Column(children: [
          TerminalPanel(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                const Row(children: [
                  Icon(Icons.info_outline, color: AppColors.hpGreen),
                  SizedBox(width: 10),
                  Expanded(
                      child: Text(
                          'Simulation data only. Never use this code as a real credential.'))
                ]),
                const SizedBox(height: 18),
                _DataRow('Terminal ID', engine.config.terminalId),
                const SizedBox(height: 12),
                _ResponsivePair(
                    wide: wide,
                    first: TextField(
                        controller: posId,
                        decoration: const InputDecoration(
                            labelText: 'POS ID', border: OutlineInputBorder())),
                    second: TextField(
                        controller: posName,
                        decoration: const InputDecoration(
                            labelText: 'POS name',
                            border: OutlineInputBorder()))),
                const SizedBox(height: 14),
                PrimaryTerminalButton(
                    label: token == null
                        ? 'Generate Pairing Code'
                        : 'Regenerate Pairing Code',
                    icon: Icons.password_rounded,
                    onPressed: () {
                      final generated =
                          ref.read(simulatorControllerProvider).generateOtp();
                      otp.text = generated.value;
                    }),
              ])),
          if (token != null) ...[
            const SizedBox(height: 16),
            TerminalPanel(
                child: Column(children: [
              Text(
                  token.isUsed
                      ? 'USED CODE'
                      : token.isExpired
                          ? 'EXPIRED CODE'
                          : 'PAIRING CODE',
                  style: TextStyle(
                      color: token.isValid
                          ? AppColors.hpGreen
                          : AppColors.hpDeclined,
                      fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              SelectableText(token.value.split('').join('  '),
                  style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 3)),
              const SizedBox(height: 8),
              Text(token.isExpired
                  ? 'Expired'
                  : 'Expires in ${remaining ~/ 60}:${(remaining % 60).toString().padLeft(2, '0')}'),
              TextButton.icon(
                  onPressed: () =>
                      Clipboard.setData(ClipboardData(text: token.value)),
                  icon: const Icon(Icons.copy_rounded),
                  label: const Text('Copy development code')),
              const Divider(height: 28),
              TextField(
                  controller: otp,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  decoration: InputDecoration(
                      labelText: 'Enter OTP',
                      border: const OutlineInputBorder(),
                      errorText: error)),
              Row(children: [
                Expanded(
                    child: SecondaryTerminalButton(
                        label: 'Use displayed code',
                        onPressed: () =>
                            setState(() => otp.text = token.value))),
                const SizedBox(width: 10),
                Expanded(
                    child: PrimaryTerminalButton(
                        label: 'Submit pairing',
                        onPressed: token.isValid
                            ? () {
                                final result = ref
                                    .read(simulatorControllerProvider)
                                    .pair(
                                        token: otp.text.trim(),
                                        posId: posId.text.trim(),
                                        posName: posName.text.trim());
                                setState(() => error = result.isSuccess
                                    ? null
                                    : result.error!.userMessage);
                              }
                            : null))
              ]),
            ])),
          ],
        ]));
  }
}

String _mask(String value) => value.length <= 12
    ? value
    : '${value.substring(0, 8)}••••${value.substring(value.length - 4)}';

class PaymentEntryScreen extends ConsumerStatefulWidget {
  const PaymentEntryScreen({super.key});
  @override
  ConsumerState<PaymentEntryScreen> createState() => _PaymentEntryScreenState();
}

class _PaymentEntryScreenState extends ConsumerState<PaymentEntryScreen> {
  final form = GlobalKey<FormState>();
  final base = TextEditingController(text: '12500');
  final tip = TextEditingController(text: '1500');
  final service = TextEditingController(text: '0');
  final userCode = TextEditingController(text: 'demo-user');
  final remoteIdentity = TextEditingController(text: 'demo-pos');
  final requestId = TextEditingController(text: 'REQ-DEMO-001');
  TipMode tipMode = TipMode.omitted;
  PaymentMethod method = PaymentMethod.auto;
  @override
  void dispose() {
    for (final c in [base, tip, service, userCode, remoteIdentity, requestId]) {
      c.dispose();
    }
    super.dispose();
  }

  double value(TextEditingController c) =>
      double.tryParse(c.text.replaceAll(',', '.')) ?? 0;
  @override
  Widget build(BuildContext context) {
    final controller = ref.watch(simulatorControllerProvider);
    final total = value(base) +
        value(service) +
        (tipMode == TipMode.custom ? value(tip) : 0);
    final wide = MediaQuery.sizeOf(context).width >= 760;
    return TerminalPageScaffold(
        title: 'Payment entry',
        subtitle: 'Build a simulator request without duplicating engine rules',
        status: controller.engine.runtimeState.status,
        action: PrimaryTerminalButton(
            label: 'Start Payment',
            icon: Icons.play_arrow_rounded,
            onPressed: () {
              if (!(form.currentState?.validate() ?? false)) return;
              final request = PaymentRequest(
                  requestId: requestId.text.trim(),
                  base: value(base),
                  tip: tipMode == TipMode.omitted
                      ? null
                      : tipMode == TipMode.explicitZero
                          ? 0
                          : value(tip),
                  service: value(service),
                  paymentMethod: method,
                  userCode: userCode.text.trim(),
                  remoteIdentity: remoteIdentity.text.trim());
              ref.read(simulatorControllerProvider).preparePayment(request);
              context.push('/card-presentation');
            }),
        child: Form(
            key: form,
            child: _ResponsivePair(
                wide: wide,
                firstFlex: 3,
                secondFlex: 2,
                first: Column(children: [
                  TerminalPanel(
                      child: Column(children: [
                    TextFormField(
                        controller: base,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        decoration: const InputDecoration(
                            labelText: 'Base amount',
                            suffixText: 'HUF',
                            border: OutlineInputBorder()),
                        validator: (v) => (double.tryParse(v ?? '') ?? 0) <= 0
                            ? 'Enter an amount greater than zero'
                            : null),
                    const SizedBox(height: 12),
                    TextFormField(
                        controller: service,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        decoration: const InputDecoration(
                            labelText: 'Service charge',
                            suffixText: 'HUF',
                            border: OutlineInputBorder())),
                    const SizedBox(height: 18),
                    const Align(
                        alignment: Alignment.centerLeft,
                        child: Text('Tip transmission mode',
                            style: TextStyle(fontWeight: FontWeight.w800))),
                    RadioGroup<TipMode>(
                      groupValue: tipMode,
                      onChanged: (v) => setState(() => tipMode = v!),
                      child: const Column(children: [
                        RadioListTile(
                            value: TipMode.omitted,
                            title: Text('Omit tip field'),
                            subtitle:
                                Text('The request JSON contains no tip key')),
                        RadioListTile(
                            value: TipMode.explicitZero,
                            title: Text('Send tip = 0'),
                            subtitle:
                                Text('The request explicitly includes zero')),
                        RadioListTile(
                            value: TipMode.custom,
                            title: Text('Send custom positive tip')),
                      ]),
                    ),
                    if (tipMode == TipMode.custom)
                      TextFormField(
                          controller: tip,
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          decoration: const InputDecoration(
                              labelText: 'Tip amount',
                              suffixText: 'HUF',
                              border: OutlineInputBorder()),
                          validator: (v) => tipMode == TipMode.custom &&
                                  (double.tryParse(v ?? '') ?? 0) <= 0
                              ? 'Custom tip must be positive'
                              : null),
                    const SizedBox(height: 12),
                    DropdownButtonFormField(
                        initialValue: method,
                        decoration: const InputDecoration(
                            labelText: 'Payment method',
                            border: OutlineInputBorder()),
                        items: PaymentMethod.values
                            .map((m) =>
                                DropdownMenuItem(value: m, child: Text(m.wire)))
                            .toList(),
                        onChanged: (v) => setState(() => method = v!)),
                    const SizedBox(height: 12),
                    TextFormField(
                        controller: userCode,
                        decoration: const InputDecoration(
                            labelText: 'userCode',
                            border: OutlineInputBorder())),
                    const SizedBox(height: 12),
                    TextFormField(
                        controller: remoteIdentity,
                        decoration: const InputDecoration(
                            labelText: 'remoteIdentity',
                            border: OutlineInputBorder())),
                    const SizedBox(height: 12),
                    TextFormField(
                        controller: requestId,
                        decoration: const InputDecoration(
                            labelText: 'requestId',
                            border: OutlineInputBorder())),
                  ])),
                ]),
                second: Column(children: [
                  TerminalPanel(
                      child: Column(children: [
                    AmountDisplay(amount: total),
                    const Divider(height: 28),
                    _DataRow('Base', money(value(base))),
                    _DataRow(
                        'Tip',
                        tipMode == TipMode.omitted
                            ? 'Omitted'
                            : money(
                                tipMode == TipMode.custom ? value(tip) : 0)),
                    _DataRow('Service', money(value(service))),
                    _DataRow('Method', method.wire)
                  ])),
                  const SizedBox(height: 16),
                  TerminalPanel(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                        const Text('Selected test card',
                            style: TextStyle(fontWeight: FontWeight.w800)),
                        const SizedBox(height: 12),
                        PaymentCardVisual(
                            card: controller.selectedCard, selected: true),
                        TextButton(
                            onPressed: () => context.push('/cards'),
                            child: const Text('Change Test Card'))
                      ])),
                  const SizedBox(height: 16),
                  TerminalPanel(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                        const Text('Selected scenario',
                            style: TextStyle(fontWeight: FontWeight.w800)),
                        const SizedBox(height: 8),
                        Text(controller.selectedScenario.name),
                        TextButton(
                            onPressed: () => context.push('/scenarios'),
                            child: const Text('Change Scenario'))
                      ])),
                ]))));
  }
}

class CardsScreen extends ConsumerStatefulWidget {
  const CardsScreen({super.key});
  @override
  ConsumerState<CardsScreen> createState() => _CardsScreenState();
}

class _CardsScreenState extends ConsumerState<CardsScreen> {
  String query = '';
  SimulatorScenario? resultFilter;
  CardInteractionMethod? interactionFilter;
  @override
  Widget build(BuildContext context) {
    final controller = ref.watch(simulatorControllerProvider);
    final cards = DemoCards.all
        .where((card) =>
            (query.isEmpty ||
                '${card.displayName} ${card.last4}'
                    .toLowerCase()
                    .contains(query.toLowerCase())) &&
            (resultFilter == null || card.defaultScenario == resultFilter) &&
            (interactionFilter == null ||
                card.interactionMethod == interactionFilter))
        .toList();
    final columns = MediaQuery.sizeOf(context).width >= 760 ? 2 : 1;
    return TerminalPageScaffold(
        title: 'Test Cards Library',
        subtitle: '12 fictional cards; no complete or usable PAN is stored',
        status: controller.engine.runtimeState.status,
        child: Column(children: [
          TerminalPanel(
              child: Column(children: [
            TextField(
                onChanged: (v) => setState(() => query = v),
                decoration: const InputDecoration(
                    labelText: 'Search cards',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder())),
            const SizedBox(height: 12),
            Wrap(spacing: 10, runSpacing: 10, children: [
              DropdownButton<SimulatorScenario?>(
                  value: resultFilter,
                  hint: const Text('All results'),
                  items: [
                    const DropdownMenuItem(
                        value: null, child: Text('All results')),
                    ...SimulatorScenario.values.map(
                        (s) => DropdownMenuItem(value: s, child: Text(s.wire)))
                  ],
                  onChanged: (v) => setState(() => resultFilter = v)),
              DropdownButton<CardInteractionMethod?>(
                  value: interactionFilter,
                  hint: const Text('All interactions'),
                  items: [
                    const DropdownMenuItem(
                        value: null, child: Text('All interactions')),
                    ...CardInteractionMethod.values.map(
                        (s) => DropdownMenuItem(value: s, child: Text(s.wire)))
                  ],
                  onChanged: (v) => setState(() => interactionFilter = v)),
            ]),
          ])),
          const SizedBox(height: 16),
          GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: cards.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: columns,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: .46),
              itemBuilder: (context, index) {
                final card = cards[index];
                final selected = controller.selectedCard.id == card.id;
                return TerminalPanel(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                      PaymentCardVisual(card: card, selected: selected),
                      const SizedBox(height: 14),
                      Row(children: [
                        Expanded(
                            child: Text(card.displayName,
                                style: const TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w800))),
                        if (selected)
                          const Chip(
                              label: Text('SELECTED'),
                              avatar:
                                  Icon(Icons.check, color: AppColors.hpSuccess))
                      ]),
                      _DataRow('Last four', card.last4),
                      _DataRow('Interaction', card.interactionMethod.wire),
                      _DataRow(
                          'PIN',
                          card.requiresPin
                              ? card.pinBehavior.wire
                              : 'Not required'),
                      _DataRow('Expected result', card.defaultScenario.wire),
                      _DataRow(
                          'Methods',
                          card.supportedPaymentMethods
                              .map((e) => e.wire)
                              .join(', ')),
                      _DataRow('Signature',
                          card.requireSignature ? 'Required' : 'Not required'),
                      const SizedBox(height: 6),
                      Text(card.developerNotes,
                          style: const TextStyle(color: AppColors.hpTextMuted)),
                      const Spacer(),
                      PrimaryTerminalButton(
                          label: selected ? 'Card Selected' : 'Select Card',
                          icon: Icons.credit_card,
                          onPressed: selected
                              ? null
                              : () => ref
                                  .read(simulatorControllerProvider)
                                  .selectCard(card)),
                    ]));
              }),
        ]));
  }
}

class CardPresentationScreen extends ConsumerStatefulWidget {
  const CardPresentationScreen({super.key});

  @override
  ConsumerState<CardPresentationScreen> createState() =>
      _CardPresentationScreenState();
}

class _CardPresentationScreenState
    extends ConsumerState<CardPresentationScreen> {
  CardPresentationVisualState visualState = CardPresentationVisualState.present;
  bool advancing = false;

  Future<void> advance() async {
    final c = ref.read(simulatorControllerProvider);
    final card = c.selectedCard;
    if (c.pendingRequest == null || advancing) return;
    if (card.id == 'contactless-fallback' &&
        visualState == CardPresentationVisualState.present) {
      setState(
          () => visualState = CardPresentationVisualState.contactlessFailed);
      return;
    }
    if (visualState == CardPresentationVisualState.contactlessFailed) {
      setState(() => visualState = CardPresentationVisualState.insertFallback);
      return;
    }
    setState(() {
      visualState = CardPresentationVisualState.reading;
      advancing = true;
    });
    if (!MediaQuery.disableAnimationsOf(context)) {
      await Future<void>.delayed(const Duration(milliseconds: 520));
    }
    if (!mounted) return;
    final needsPin = card.requiresPin || c.selectedScenario.requiresPin;
    context.go(needsPin ? '/pin' : '/processing');
  }

  @override
  Widget build(BuildContext context) {
    final c = ref.watch(simulatorControllerProvider);
    final card = c.selectedCard;
    final request = c.pendingRequest;
    final instruction = switch (visualState) {
      CardPresentationVisualState.contactlessFailed => 'Use chip instead',
      CardPresentationVisualState.insertFallback => 'Insert card',
      CardPresentationVisualState.reading => 'Reading card',
      CardPresentationVisualState.removeCard => 'Remove card',
      CardPresentationVisualState.present => switch (card.interactionMethod) {
          CardInteractionMethod.contactless => 'Tap card',
          CardInteractionMethod.insert => 'Insert card',
          CardInteractionMethod.swipe => 'Swipe card'
        },
    };
    return TerminalPageScaffold(
        title: 'Present card',
        subtitle: 'Customer-facing terminal interaction',
        status: c.engine.runtimeState.status,
        action: PrimaryTerminalButton(
            label: instruction,
            icon: card.interactionMethod == CardInteractionMethod.contactless
                ? Icons.contactless_rounded
                : Icons.credit_card_rounded,
            loading: advancing,
            onPressed: request == null ? null : advance),
        child: Center(
            child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 760),
                child: Column(children: [
                  if (request != null)
                    AmountDisplay(
                        amount: request.base +
                            (request.tip ?? 0) +
                            request.service),
                  const SizedBox(height: 18),
                  TerminalReaderScene(card: card, state: visualState),
                  const SizedBox(height: 18),
                  Text(instruction,
                      style: const TextStyle(
                          fontSize: 24, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 6),
                  Text(
                      visualState ==
                              CardPresentationVisualState.contactlessFailed
                          ? 'Contactless failed locally. Insert the same demo card.'
                          : 'Follow the direction shown on the simulated reader.',
                      textAlign: TextAlign.center),
                  const SizedBox(height: 8),
                  Text('Scenario: ${c.selectedScenario.name}',
                      style: const TextStyle(color: AppColors.hpTextMuted)),
                  const SizedBox(height: 12),
                  SecondaryTerminalButton(
                      label: 'Customer cancel',
                      icon: Icons.close_rounded,
                      onPressed: () {
                        ref.read(simulatorControllerProvider).cancelPayment();
                        context.go('/processing');
                      }),
                ]))));
  }
}

class PinScreen extends ConsumerStatefulWidget {
  const PinScreen({super.key});
  @override
  ConsumerState<PinScreen> createState() => _PinScreenState();
}

class _PinScreenState extends ConsumerState<PinScreen> {
  String? feedback;
  @override
  void dispose() {
    Future.microtask(() => ref.read(simulatorControllerProvider).clearPin());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = ref.watch(simulatorControllerProvider);
    final r = c.pendingRequest;
    return TerminalPageScaffold(
        title: 'Enter PIN',
        subtitle: 'Demo PIN input is never recorded or placed in JSON',
        status: c.engine.runtimeState.status,
        child: Center(
            child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 500),
                child: Column(children: [
                  if (r != null)
                    AmountDisplay(amount: r.base + (r.tip ?? 0) + r.service),
                  const SizedBox(height: 18),
                  TerminalPanel(
                      child: Column(children: [
                    Text('Attempt ${c.pinAttempts + 1}',
                        style: const TextStyle(color: AppColors.hpTextMuted)),
                    if (feedback != null)
                      Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Text(feedback!,
                              style: const TextStyle(
                                  color: AppColors.hpDeclined,
                                  fontWeight: FontWeight.w700))),
                    NumericPinPad(
                        length: c.pin.length,
                        onDigit: c.appendPin,
                        onDelete: c.deletePin,
                        onConfirm: () {
                          final accepted =
                              ref.read(simulatorControllerProvider).submitPin();
                          if (accepted) {
                            context.go('/processing');
                          } else {
                            setState(() => feedback =
                                c.selectedCard.pinBehavior ==
                                        PinBehavior.blocked
                                    ? 'PIN blocked'
                                    : 'Incorrect PIN. Try again.');
                          }
                        }),
                    const SizedBox(height: 12),
                    SecondaryTerminalButton(
                        label: 'Cancel payment',
                        icon: Icons.close,
                        onPressed: () {
                          c.cancelPayment();
                          context.go('/processing');
                        }),
                  ])),
                  const SizedBox(height: 12),
                  ExpansionTile(
                      title: const Text(
                          'Developer PIN hint (disabled by default)'),
                      children: [
                        SwitchListTile(
                            value: c.developerDetailsEnabled,
                            onChanged: (_) {},
                            title: const Text('Enable in Terminal Settings'))
                      ]),
                ]))));
  }
}

class ProcessingScreen extends ConsumerStatefulWidget {
  const ProcessingScreen({super.key});
  @override
  ConsumerState<ProcessingScreen> createState() => _ProcessingScreenState();
}

class _ProcessingScreenState extends ConsumerState<ProcessingScreen> {
  int step = 0;
  Timer? stepTimer;
  @override
  void initState() {
    super.initState();
    Future.microtask(_run);
  }

  Future<void> _run() async {
    final c = ref.read(simulatorControllerProvider);
    stepTimer = Timer.periodic(const Duration(milliseconds: 120), (_) {
      if (mounted) setState(() => step++);
    });
    await c.executePaymentOnce();
    stepTimer?.cancel();
    if (mounted) context.go('/result');
  }

  @override
  void dispose() {
    stepTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = ref.watch(simulatorControllerProvider);
    final r = c.pendingRequest;
    return PopScope(
        canPop: false,
        child: TerminalPageScaffold(
            title: 'Processing payment',
            subtitle: 'Keep the card near the terminal',
            status: TerminalStatus.busy,
            child: Center(
                child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 600),
                    child: Column(children: [
                      if (r != null)
                        AmountDisplay(
                            amount: r.base + (r.tip ?? 0) + r.service),
                      const SizedBox(height: 18),
                      TerminalPanel(
                          child: ProcessingStepView(
                              current: step.clamp(
                                  0,
                                  c.selectedCard.requiresPin ||
                                          c.selectedScenario.requiresPin
                                      ? 5
                                      : 4),
                              pinRequired: c.selectedCard.requiresPin ||
                                  c.selectedScenario.requiresPin)),
                      const SizedBox(height: 18),
                      const Text(
                          'Transaction execution is guarded against widget rebuilds and navigation retries.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: AppColors.hpTextMuted)),
                    ])))));
  }
}

class ResultScreen extends ConsumerWidget {
  const ResultScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = ref.watch(simulatorControllerProvider);
    final tx = c.resultTransaction;
    final recoverable =
        tx?.status == TransactionStatus.timedOut || c.resultError?.code == 3012;
    return TerminalPageScaffold(
        title: 'Transaction result',
        subtitle: 'A simulator outcome — no real money was processed',
        status: c.engine.runtimeState.status,
        child: Center(
            child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TransactionResultView(
                          transaction: tx, error: c.resultError),
                      const SizedBox(height: 16),
                      if (tx?.isSuccessful == true) ...[
                        TerminalPanel(
                            child: Column(children: [
                          _DataRow('Base', money(tx!.baseAmount)),
                          _DataRow('Approved tip', money(tx.tipAmount)),
                          _DataRow('Service', money(tx.serviceAmount)),
                          _DataRow('Transaction ID', tx.transactionId),
                          _DataRow(
                              'Card', '${tx.cardType} ${tx.maskedCardNumber}')
                        ])),
                        const SizedBox(height: 12),
                        PrimaryTerminalButton(
                            label: 'View receipt',
                            icon: Icons.receipt_long,
                            onPressed: () => context.push('/receipt')),
                      ] else ...[
                        if (recoverable)
                          SecondaryTerminalButton(
                              label: 'Check Last Transaction',
                              icon: Icons.manage_search,
                              onPressed: () => context.push('/history')),
                        const SizedBox(height: 10),
                        PrimaryTerminalButton(
                            label: 'Retry Payment',
                            icon: Icons.refresh,
                            onPressed: () => context.go('/payment')),
                      ],
                      const SizedBox(height: 10),
                      SecondaryTerminalButton(
                          label: 'New payment',
                          icon: Icons.add_card,
                          onPressed: () => context.go('/payment')),
                      const SizedBox(height: 10),
                      SecondaryTerminalButton(
                          label: 'Return to Terminal',
                          icon: Icons.home_outlined,
                          onPressed: () => context.go('/home')),
                      const SizedBox(height: 14),
                      DeveloperDetailsPanel(
                          requestJson: c.requestJson(),
                          responseJson: c.responseJson(),
                          transaction: tx),
                    ]))));
  }
}

class ReceiptScreen extends ConsumerWidget {
  const ReceiptScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = ref.watch(simulatorControllerProvider);
    final tx = c.resultTransaction ?? c.engine.lastTransaction;
    if (tx == null) return const NotFoundScreen(path: '/receipt');
    final paper = ReceiptPaper(transaction: tx);
    return TerminalPageScaffold(
        title: 'Receipt preview',
        subtitle: 'For simulator testing only; not legally or fiscally valid',
        status: c.engine.runtimeState.status,
        child: Center(
            child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 620),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      paper,
                      const SizedBox(height: 16),
                      Wrap(spacing: 10, runSpacing: 10, children: [
                        OutlinedButton.icon(
                            onPressed: () => Clipboard.setData(
                                ClipboardData(text: paper.receiptText)),
                            icon: const Icon(Icons.copy),
                            label: const Text('Copy receipt text')),
                        OutlinedButton.icon(
                            onPressed: () => Clipboard.setData(
                                ClipboardData(text: c.responseJson())),
                            icon: const Icon(Icons.data_object),
                            label: const Text('Copy response JSON')),
                        OutlinedButton.icon(
                            onPressed: () => ScaffoldMessenger.of(context)
                                .showSnackBar(const SnackBar(
                                    content:
                                        Text('Simulated print preview ready'))),
                            icon: const Icon(Icons.print_outlined),
                            label: const Text('Simulated print preview'))
                      ]),
                      const SizedBox(height: 12),
                      SecondaryTerminalButton(
                          label: 'Return to result',
                          onPressed: () => context.go('/result')),
                      const SizedBox(height: 10),
                      PrimaryTerminalButton(
                          label: 'Return to terminal',
                          onPressed: () => context.go('/home')),
                    ]))));
  }
}

class ScenarioStudioScreen extends ConsumerStatefulWidget {
  const ScenarioStudioScreen({super.key});
  @override
  ConsumerState<ScenarioStudioScreen> createState() =>
      _ScenarioStudioScreenState();
}

class _ScenarioStudioScreenState extends ConsumerState<ScenarioStudioScreen> {
  late ScenarioPreset draft;
  late SimulatorSpeed speed;
  final json = TextEditingController(text: '{\n  "status": "APPROVED"\n}');
  String? jsonError;
  @override
  void initState() {
    super.initState();
    final c = ref.read(simulatorControllerProvider);
    draft = c.selectedScenario;
    speed = c.speed;
  }

  @override
  void dispose() {
    json.dispose();
    super.dispose();
  }

  void validateJson() {
    try {
      if (jsonDecode(json.text) is! Map) {
        throw const FormatException('JSON response must be an object');
      }
      setState(() => jsonError = null);
    } catch (e) {
      setState(() => jsonError = 'Invalid JSON syntax');
    }
  }

  ScenarioPreset configuredDraft() {
    if (draft.scenario != SimulatorScenario.custom) return draft;
    return draft.copyWith(
        customResponse:
            Map<String, dynamic>.from(jsonDecode(json.text) as Map));
  }

  @override
  Widget build(BuildContext context) {
    final c = ref.watch(simulatorControllerProvider);
    final wide = MediaQuery.sizeOf(context).width >= 780;
    Widget statusField(String label, TerminalStatus current,
            ValueChanged<TerminalStatus> onChanged) =>
        Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: DropdownButtonFormField<TerminalStatus>(
                key: ValueKey('$label-${current.wire}'),
                initialValue: current,
                isExpanded: true,
                decoration: InputDecoration(
                    labelText: label, border: const OutlineInputBorder()),
                items: TerminalStatus.values
                    .map((status) => DropdownMenuItem(
                        value: status, child: Text(status.wire)))
                    .toList(),
                onChanged: (value) => onChanged(value!)));
    final editor = TerminalPanel(
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      DropdownButtonFormField(
          key: ValueKey(draft.id),
          isExpanded: true,
          initialValue: draft,
          decoration: const InputDecoration(
              labelText: 'Scenario preset', border: OutlineInputBorder()),
          items: ScenarioPresets.all
              .map((s) => DropdownMenuItem(value: s, child: Text(s.name)))
              .toList(),
          onChanged: (v) => setState(() {
                draft = v!;
                json.text = const JsonEncoder.withIndent(' ')
                    .convert(draft.customResponse ?? {'status': 'APPROVED'});
                jsonError = null;
              })),
      const SizedBox(height: 12),
      DropdownButtonFormField(
          key: ValueKey(speed),
          isExpanded: true,
          initialValue: speed,
          decoration: const InputDecoration(
              labelText: 'Simulator speed', border: OutlineInputBorder()),
          items: SimulatorSpeed.values
              .map((s) => DropdownMenuItem(value: s, child: Text(s.wire)))
              .toList(),
          onChanged: (v) => setState(() => speed = v!)),
      const SizedBox(height: 12),
      DropdownButtonFormField(
          key: ValueKey(c.selectedCard.id),
          isExpanded: true,
          initialValue: c.selectedCard,
          decoration: const InputDecoration(
              labelText: 'Selected test card', border: OutlineInputBorder()),
          items: DemoCards.all
              .map((card) =>
                  DropdownMenuItem(value: card, child: Text(card.displayName)))
              .toList(),
          onChanged: (v) =>
              ref.read(simulatorControllerProvider).selectCard(v!)),
      const SizedBox(height: 16),
      Text('Scenario delay: ${draft.delay.inMilliseconds} ms',
          style: const TextStyle(fontWeight: FontWeight.w700)),
      Slider(
          value: draft.delay.inMilliseconds.clamp(0, 3000).toDouble(),
          max: 3000,
          divisions: 12,
          label: '${draft.delay.inMilliseconds} ms',
          onChanged: (value) => setState(() => draft =
              draft.copyWith(delay: Duration(milliseconds: value.round())))),
      statusField(
          'Status before transaction',
          draft.terminalStatusBefore,
          (value) => setState(
              () => draft = draft.copyWith(terminalStatusBefore: value))),
      statusField(
          'Status during transaction',
          draft.terminalStatusDuring,
          (value) => setState(
              () => draft = draft.copyWith(terminalStatusDuring: value))),
      statusField(
          'Status after transaction',
          draft.terminalStatusAfter,
          (value) => setState(
              () => draft = draft.copyWith(terminalStatusAfter: value))),
      DropdownButtonFormField<PinBehavior>(
          key: ValueKey('pin-${draft.pinBehavior.wire}'),
          initialValue: draft.pinBehavior,
          isExpanded: true,
          decoration: const InputDecoration(
              labelText: 'PIN behavior', border: OutlineInputBorder()),
          items: PinBehavior.values
              .map((behavior) =>
                  DropdownMenuItem(value: behavior, child: Text(behavior.wire)))
              .toList(),
          onChanged: (value) => setState(() => draft = draft.copyWith(
              pinBehavior: value,
              requiresPin: value != PinBehavior.notRequired))),
      SwitchListTile(
          contentPadding: EdgeInsets.zero,
          value: draft.requireSignature,
          title: const Text('Signature required'),
          onChanged: (value) =>
              setState(() => draft = draft.copyWith(requireSignature: value))),
      TextFormField(
          initialValue: draft.processor,
          decoration: const InputDecoration(
              labelText: 'Processor', border: OutlineInputBorder()),
          onChanged: (value) => draft = draft.copyWith(processor: value)),
      const SizedBox(height: 10),
      TextFormField(
          initialValue: draft.responseErrorCode,
          decoration: const InputDecoration(
              labelText: 'Error code', border: OutlineInputBorder()),
          onChanged: (value) => draft = draft.copyWith(
              responseErrorCode: value,
              clearResponseErrorCode: value.trim().isEmpty)),
      const SizedBox(height: 10),
      TextFormField(
          initialValue: draft.responseErrorMessage,
          decoration: const InputDecoration(
              labelText: 'Error message', border: OutlineInputBorder()),
          onChanged: (value) => draft = draft.copyWith(
              responseErrorMessage: value,
              clearResponseErrorMessage: value.trim().isEmpty)),
      SwitchListTile(
          contentPadding: EdgeInsets.zero,
          value: draft.receiptEnabled,
          title: const Text('Receipt enabled'),
          onChanged: (value) =>
              setState(() => draft = draft.copyWith(receiptEnabled: value))),
      if (draft.scenario == SimulatorScenario.custom) ...[
        const SizedBox(height: 12),
        TextField(
            controller: json,
            minLines: 6,
            maxLines: 12,
            style: const TextStyle(fontFamily: 'monospace'),
            decoration: InputDecoration(
                labelText: 'Custom JSON response',
                border: const OutlineInputBorder(),
                errorText: jsonError),
            onChanged: (_) => validateJson()),
        Row(children: [
          TextButton(
              onPressed: () {
                json.text = '{\n  "status": "APPROVED"\n}';
                validateJson();
              },
              child: const Text('Reset')),
          TextButton(
              onPressed: () =>
                  Clipboard.setData(ClipboardData(text: json.text)),
              child: const Text('Copy')),
          TextButton(
              onPressed: validateJson, child: const Text('Format & validate'))
        ])
      ],
      const SizedBox(height: 16),
      Row(children: [
        Expanded(
            child: SecondaryTerminalButton(
                label: 'Reset to Preset',
                icon: Icons.restore,
                onPressed: () => setState(() {
                      draft = c.selectedScenario;
                      speed = c.speed;
                    }))),
        const SizedBox(width: 10),
        Expanded(
            child: PrimaryTerminalButton(
                label: 'Save temporary configuration',
                icon: Icons.save_outlined,
                onPressed: jsonError == null
                    ? () {
                        final ctrl = ref.read(simulatorControllerProvider);
                        ctrl.speed = speed;
                        ctrl.selectScenario(configuredDraft());
                      }
                    : null))
      ]),
    ]));
    final preview = TerminalPanel(
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      const Text('Expected flow preview',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
      const SizedBox(height: 12),
      Text(draft.description),
      const SizedBox(height: 18),
      _StateTransition('Before', draft.terminalStatusBefore),
      const Icon(Icons.arrow_downward, color: AppColors.hpBorder),
      _StateTransition('During', draft.terminalStatusDuring),
      const Icon(Icons.arrow_downward, color: AppColors.hpBorder),
      _StateTransition('After', draft.terminalStatusAfter),
      const Divider(height: 28),
      _DataRow('Card', c.selectedCard.displayName),
      _DataRow('PIN', draft.pinBehavior.wire),
      _DataRow('Result', draft.scenario.wire)
    ]));
    return TerminalPageScaffold(
        title: 'Scenario Studio',
        subtitle:
            'Configure a focused terminal test without a dashboard-style interface',
        status: c.engine.runtimeState.status,
        action: PrimaryTerminalButton(
            label: 'Run Scenario',
            icon: Icons.play_arrow,
            onPressed: jsonError == null
                ? () {
                    final ctrl = ref.read(simulatorControllerProvider);
                    ctrl.setSpeed(speed);
                    ctrl.selectScenario(configuredDraft());
                    context.go('/payment');
                  }
                : null),
        child: _ResponsivePair(wide: wide, first: editor, second: preview));
  }
}

class _StateTransition extends StatelessWidget {
  const _StateTransition(this.label, this.status);
  final String label;
  final TerminalStatus status;
  @override
  Widget build(BuildContext context) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(children: [
        Expanded(
            child: Text(label,
                style: const TextStyle(fontWeight: FontWeight.w700))),
        TerminalStatusChip(status: status)
      ]));
}

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});
  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  String query = '';
  TransactionType? type;
  TransactionStatus? status;
  @override
  Widget build(BuildContext context) {
    final c = ref.watch(simulatorControllerProvider);
    final items = c.engine.transactionHistory.reversed
        .where((t) =>
            (query.isEmpty ||
                '${t.requestId} ${t.transactionId}'
                    .toLowerCase()
                    .contains(query.toLowerCase())) &&
            (type == null || t.type == type) &&
            (status == null || t.status == status))
        .toList();
    return TerminalPageScaffold(
        title: 'Transaction history',
        subtitle:
            'Auditable simulator payments, failures, cancellations, refunds and voids',
        status: c.engine.runtimeState.status,
        child: Column(children: [
          TerminalPanel(
              child: Column(children: [
            TextField(
                onChanged: (v) => setState(() => query = v),
                decoration: const InputDecoration(
                    labelText: 'Search request or transaction ID',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder())),
            const SizedBox(height: 10),
            Wrap(spacing: 12, children: [
              DropdownButton<TransactionType?>(
                  value: type,
                  hint: const Text('All types'),
                  items: [
                    const DropdownMenuItem(
                        value: null, child: Text('All types')),
                    ...TransactionType.values.map(
                        (v) => DropdownMenuItem(value: v, child: Text(v.wire)))
                  ],
                  onChanged: (v) => setState(() => type = v)),
              DropdownButton<TransactionStatus?>(
                  value: status,
                  hint: const Text('All statuses'),
                  items: [
                    const DropdownMenuItem(
                        value: null, child: Text('All statuses')),
                    ...TransactionStatus.values.map(
                        (v) => DropdownMenuItem(value: v, child: Text(v.wire)))
                  ],
                  onChanged: (v) => setState(() => status = v))
            ])
          ])),
          const SizedBox(height: 16),
          if (items.isEmpty)
            const TerminalPanel(
                child: Padding(
                    padding: EdgeInsets.all(30),
                    child: Column(children: [
                      Icon(Icons.receipt_long_outlined,
                          size: 54, color: AppColors.hpBorder),
                      SizedBox(height: 12),
                      Text('No matching transactions')
                    ]))),
          for (final tx in items) ...[
            TerminalPanel(
                child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                        backgroundColor: (tx.isSuccessful
                                ? AppColors.hpSuccess
                                : tx.status == TransactionStatus.cancelled
                                    ? AppColors.hpWarning
                                    : AppColors.hpDeclined)
                            .withValues(alpha: .15),
                        child: Icon(
                            tx.isSuccessful
                                ? Icons.check
                                : tx.status == TransactionStatus.cancelled
                                    ? Icons.close
                                    : Icons.error_outline,
                            color: tx.isSuccessful
                                ? AppColors.hpSuccess
                                : tx.status == TransactionStatus.cancelled
                                    ? AppColors.hpWarning
                                    : AppColors.hpDeclined)),
                    title: Text('${tx.type.wire} • ${money(tx.totalAmount)}',
                        style: const TextStyle(fontWeight: FontWeight.w800)),
                    subtitle: Text(
                        '${tx.createdAt.toLocal()}\n${tx.cardNumberLast4} • ${tx.requestId}'),
                    isThreeLine: true,
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.push('/history/${tx.transactionId}'))),
            const SizedBox(height: 10)
          ],
          if (c.engine.transactionHistory.isNotEmpty)
            SecondaryTerminalButton(
                label: 'Clear history',
                icon: Icons.delete_outline,
                onPressed: () => _confirm(
                    context,
                    'Clear transaction history?',
                    'This removes all simulator history records.',
                    () =>
                        ref.read(simulatorControllerProvider).clearHistory())),
        ]));
  }
}

class TransactionDetailScreen extends ConsumerWidget {
  const TransactionDetailScreen({super.key, required this.transactionId});
  final String transactionId;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = ref.watch(simulatorControllerProvider);
    Transaction? tx;
    for (final item in c.engine.transactionHistory) {
      if (item.transactionId == transactionId) tx = item;
    }
    if (tx == null) return NotFoundScreen(path: '/history/$transactionId');
    final t = tx;
    return TerminalPageScaffold(
        title: 'Transaction detail',
        subtitle: t.transactionId,
        status: c.engine.runtimeState.status,
        child: Center(
            child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TransactionResultView(transaction: t),
                      const SizedBox(height: 16),
                      TerminalPanel(
                          child: Column(children: [
                        _DataRow('Type', t.type.wire),
                        _DataRow('Status', t.status.wire),
                        _DataRow('Created', t.createdAt.toLocal().toString()),
                        _DataRow('Request ID', t.requestId),
                        _DataRow('External ID', t.externalId),
                        _DataRow('Card', '${t.cardType} ${t.maskedCardNumber}'),
                        _DataRow('Refunded', money(t.refundedAmount))
                      ])),
                      const SizedBox(height: 12),
                      if (t.receiptData != null)
                        PrimaryTerminalButton(
                            label: 'Open receipt',
                            icon: Icons.receipt_long,
                            onPressed: () {
                              c.resultTransaction = t;
                              context.push('/receipt');
                            }),
                      const SizedBox(height: 10),
                      SecondaryTerminalButton(
                          label: 'Repeat test setup',
                          icon: Icons.replay,
                          onPressed: () {
                            c.preparePayment(PaymentRequest(
                                requestId: '${t.requestId}-REPEAT',
                                base: t.baseAmount,
                                tip: t.tipAmount,
                                service: t.serviceAmount,
                                paymentMethod: t.paymentMethod,
                                userCode: t.userCode,
                                remoteIdentity: t.remoteIdentity));
                            context.go('/payment');
                          }),
                      DeveloperDetailsPanel(
                          requestJson: prettyJson({'requestId': t.requestId}),
                          responseJson: prettyJson(t.toJson()),
                          transaction: t)
                    ]))));
  }
}

/// Deterministic result renderer used by the visual QA catalogue.
class DeveloperResultPreviewScreen extends StatefulWidget {
  const DeveloperResultPreviewScreen({super.key, required this.kind});
  final String kind;

  @override
  State<DeveloperResultPreviewScreen> createState() =>
      _DeveloperResultPreviewScreenState();
}

class _DeveloperResultPreviewScreenState
    extends State<DeveloperResultPreviewScreen> {
  late Transaction transaction;

  @override
  void initState() {
    super.initState();
    transaction = _createTransaction();
  }

  @override
  void didUpdateWidget(covariant DeveloperResultPreviewScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.kind != widget.kind) {
      transaction = _createTransaction();
    }
  }

  Transaction _createTransaction() {
    final engine = SimulatorEngine();
    if (widget.kind == 'timeout') {
      engine.selectedScenario =
          ScenarioPresets.all.firstWhere((preset) => preset.id == 'timeout');
    }
    final saleResult = engine.processPayment(const PaymentRequest(
        requestId: 'VISUAL-QA-SALE',
        base: 12500,
        service: 0,
        paymentMethod: PaymentMethod.bank,
        userCode: 'visual-qa'));
    final sale = saleResult.value ?? engine.transactionHistory.last;
    return switch (widget.kind) {
      'refund' => engine
          .processRefund(RefundRequest(
              requestId: 'VISUAL-QA-REFUND',
              amount: 2500,
              paymentMethod: PaymentMethod.bank,
              userCode: 'visual-qa',
              originalTransactionId: sale.transactionId))
          .value!,
      'void' => engine
          .voidLastTransaction(VoidRequest(
              requestId: 'VISUAL-QA-VOID',
              lastTransactionId: sale.transactionId,
              userCode: 'visual-qa'))
          .value!,
      'timeout' => sale,
      _ => sale,
    };
  }

  @override
  Widget build(BuildContext context) => TerminalPageScaffold(
      title: 'Visual QA result',
      subtitle: 'Deterministic simulator-only developer preview',
      status: TerminalStatus.ready,
      child: Center(
          child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: TransactionResultView(transaction: transaction))));
}

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = ref.watch(simulatorControllerProvider);
    final api = ref.watch(apiControllerProvider);
    final config = c.engine.config;
    return TerminalPageScaffold(
        title: 'Terminal settings',
        subtitle: 'Simulator identity, session behavior and local demo data',
        status: c.engine.runtimeState.status,
        child: Column(children: [
          _SettingsSection('Terminal', Icons.point_of_sale, [
            _DataRow('Terminal ID', config.terminalId),
            _DataRow('Device name', config.deviceName),
            _DataRow('Currency', config.currency),
            _DataRow('Integration mode',
                config.integrationModeEnabled ? 'Enabled' : 'Disabled'),
            _DataRow('Terminal status', c.engine.runtimeState.status.wire),
            _DataRow('App version', config.appVersion)
          ]),
          _SettingsSection('Tipping', Icons.volunteer_activism_outlined, [
            SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: config.tippingEnabled,
                onChanged: (v) {
                  c.setTippingEnabled(v);
                },
                title: const Text('Tipping enabled')),
            ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Maximum tip amount'),
                trailing: Text(money(config.maximumTipAmount)),
                onTap: () => _editNumber(
                    context,
                    'Maximum tip amount',
                    config.maximumTipAmount,
                    (value) => c.setTipLimits(amount: value))),
            ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Maximum tip percentage'),
                trailing:
                    Text('${config.maximumTipPercentage.toStringAsFixed(0)}%'),
                onTap: () => _editNumber(
                    context,
                    'Maximum tip percentage',
                    config.maximumTipPercentage,
                    (value) => c.setTipLimits(percentage: value)))
          ]),
          _SettingsSection('Pairing / session', Icons.link, [
            _DataRow(
                'Active session', c.engine.isSessionValid ? 'Active' : 'None'),
            if (c.engine.pairingSession != null)
              SecondaryTerminalButton(
                  label: 'Invalidate session',
                  onPressed: () => _confirm(
                      context,
                      'Invalidate session?',
                      'The paired POS will need a new session.',
                      c.invalidateSession)),
            const SizedBox(height: 8),
            SecondaryTerminalButton(
                label: 'Generate new OTP',
                onPressed: () {
                  c.generateOtp();
                  context.push('/pairing');
                }),
            const SizedBox(height: 8),
            _DataRow('Fake certificate', _mask(config.certificateFingerprint))
          ]),
          _SettingsSection('Simulator', Icons.tune, [
            DropdownButtonFormField(
                initialValue: c.speed,
                decoration: const InputDecoration(
                    labelText: 'Selected speed', border: OutlineInputBorder()),
                items: SimulatorSpeed.values
                    .map((s) => DropdownMenuItem(value: s, child: Text(s.wire)))
                    .toList(),
                onChanged: (v) {
                  c.setSpeed(v!);
                }),
            SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: c.developerDetailsEnabled,
                onChanged: (v) {
                  c.setDeveloperDetailsEnabled(v);
                },
                title: const Text('Developer details enabled')),
            SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: api.isRunning,
                onChanged: !api.isSupported || api.working
                    ? null
                    : (value) => value ? api.start() : api.stop(),
                title: const Text('Local API simulator'),
                subtitle: Text(api.isSupported
                    ? api.isRunning
                        ? 'http://${api.server.address}:${api.server.boundPort} · UDP ${api.discoveryPort}'
                        : 'HTTP ${api.port} · UDP discovery ${api.discoveryPort}'
                    : 'Unavailable in browsers; use Android or desktop')),
            const SizedBox(height: 8),
            SecondaryTerminalButton(
                label: 'Open API monitor',
                icon: Icons.lan_rounded,
                onPressed: () => context.push('/api-monitor'))
          ]),
          _SettingsSection('Data', Icons.storage_outlined, [
            SecondaryTerminalButton(
                label: 'Clear last transaction',
                onPressed: () => _confirm(context, 'Clear last transaction?',
                    'History remains available.', c.clearLastTransaction)),
            const SizedBox(height: 8),
            SecondaryTerminalButton(
                label: 'Clear history',
                onPressed: () => _confirm(
                    context,
                    'Clear all history?',
                    'This removes all simulator transactions.',
                    c.clearHistory)),
            const SizedBox(height: 8),
            PrimaryTerminalButton(
                label: 'Reset simulator',
                icon: Icons.restart_alt,
                onPressed: () => _confirm(
                    context,
                    'Reset simulator?',
                    'Pairing, settings, history and temporary flow state will be reset.',
                    c.reset))
          ]),
        ]));
  }
}

class _SettingsSection extends StatelessWidget {
  const _SettingsSection(this.title, this.icon, this.children);
  final String title;
  final IconData icon;
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TerminalPanel(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          Icon(icon, color: AppColors.hpOrange),
          const SizedBox(width: 10),
          Text(title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800))
        ]),
        const Divider(height: 26),
        ...children
      ])));
}

Future<void> _confirm(BuildContext context, String title, String message,
    VoidCallback action) async {
  final ok = await showDialog<bool>(
          context: context,
          builder: (_) =>
              AlertDialog(title: Text(title), content: Text(message), actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Cancel')),
                FilledButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('Confirm'))
              ])) ??
      false;
  if (ok) action();
}

Future<void> _editNumber(BuildContext context, String title, double current,
    ValueChanged<double> onSave) async {
  final field = TextEditingController(text: current.toStringAsFixed(0));
  final value = await showDialog<double>(
      context: context,
      builder: (dialogContext) => AlertDialog(
              title: Text(title),
              content: TextField(
                  controller: field,
                  autofocus: true,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                      labelText: 'Value', border: OutlineInputBorder())),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(dialogContext),
                    child: const Text('Cancel')),
                FilledButton(
                    onPressed: () {
                      final parsed = double.tryParse(field.text);
                      if (parsed != null && parsed >= 0) {
                        Navigator.pop(dialogContext, parsed);
                      }
                    },
                    child: const Text('Save'))
              ]));
  field.dispose();
  if (value != null) onSave(value);
}

class DeveloperDocsScreen extends StatefulWidget {
  const DeveloperDocsScreen({super.key});
  @override
  State<DeveloperDocsScreen> createState() => _DeveloperDocsScreenState();
}

class _DeveloperDocsScreenState extends State<DeveloperDocsScreen> {
  String query = '';
  static const topics = <String, String>{
    'Simulator overview':
        'HelloPay Simulator reproduces terminal states and integration flows. It never processes real money or stores real card information.',
    'Supported actions':
        'Pair, pay, refund, void, check terminal status, inspect last transaction, receipts, scenarios and test cards.',
    'Pairing flow':
        'Generate a six-digit short-lived OTP, validate it once, and create a simulated session.',
    'Payment request':
        '{"requestId":"REQ-1","base":12500,"tip":0,"service":0,"paymentMethod":"BANK"}',
    'Payment response':
        '{"transactionId":"TXN-...","status":"SUCCESS","totalAmount":12500}',
    'Refund request':
        '{"requestId":"REF-1","amount":5000,"originalTransactionId":"TXN-..."}',
    'Void request': '{"requestId":"VOID-1","lastTransactionId":"TXN-..."}',
    'Terminal status':
        'READY, BUSY, ERROR_STATE and INACTIVE are communicated using text, icon and color.',
    'Last transaction':
        'Returns the most recent simulator transaction, including failures and customer cancellation for recovery testing.',
    'Tipping behavior':
        'An omitted tip field differs from an explicit tip of zero. SZÉP, EP and SoftPOS prohibit positive tips.',
    'Error catalog':
        'Errors expose a simulator code, stable name, user-facing message and recovery guidance.',
    'Recovery testing':
        'Timeout scenarios support checking the last transaction before retrying.',
    'Test card catalog':
        'All 12 cards are fictional, masked and non-usable. They select interaction, PIN and outcome behavior.',
    'Scenario catalog':
        'Presets cover approval, rejection, cancellation, timeout, busy terminal, session errors, refund and void outcomes.',
    'Limitations':
        'This is a simulator. The local HTTP API is intended only for private development networks. Refund linking by original transaction ID is simulator-specific behavior.',
  };
  @override
  Widget build(BuildContext context) {
    final visible = topics.entries
        .where((e) =>
            query.isEmpty ||
            '${e.key} ${e.value}'.toLowerCase().contains(query.toLowerCase()))
        .toList();
    return TerminalPageScaffold(
        title: 'Developer Documentation',
        subtitle: 'In-app integration reference for the visual simulator',
        child: Column(children: [
          const TerminalPanel(
              child: Row(children: [
            Icon(Icons.science_outlined, color: AppColors.hpOrange),
            SizedBox(width: 12),
            Expanded(
                child: Text(
                    'SIMULATOR ONLY — no real money, card processing, or production protocol endpoint is present.',
                    style: TextStyle(fontWeight: FontWeight.w800)))
          ])),
          const SizedBox(height: 14),
          TextField(
              onChanged: (v) => setState(() => query = v),
              decoration: const InputDecoration(
                  labelText: 'Search documentation',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder())),
          const SizedBox(height: 14),
          for (final entry in visible)
            Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: TerminalPanel(
                    child: ExpansionTile(
                        tilePadding: EdgeInsets.zero,
                        title: Text(entry.key,
                            style:
                                const TextStyle(fontWeight: FontWeight.w800)),
                        children: [
                      Align(
                          alignment: Alignment.centerLeft,
                          child: entry.value.trimLeft().startsWith('{')
                              ? Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(14),
                                  color: AppColors.hpSurfaceMuted,
                                  child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Expanded(
                                            child: SelectableText(entry.value,
                                                style: const TextStyle(
                                                    fontFamily: 'monospace'))),
                                        IconButton(
                                            onPressed: () => Clipboard.setData(
                                                ClipboardData(
                                                    text: entry.value)),
                                            icon: const Icon(Icons.copy))
                                      ]))
                              : Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: Text(entry.value,
                                      style: const TextStyle(height: 1.5))))
                    ]))),
        ]));
  }
}

class NotFoundScreen extends StatelessWidget {
  const NotFoundScreen({super.key, required this.path});
  final String path;
  @override
  Widget build(BuildContext context) => TerminalPageScaffold(
      title: 'Page unavailable',
      subtitle: path,
      showHeader: false,
      child: Center(
          child: Column(children: [
        const Icon(Icons.search_off_rounded,
            size: 70, color: AppColors.hpTextMuted),
        const SizedBox(height: 12),
        const Text(
            'The requested simulator page or transaction was not found.'),
        const SizedBox(height: 18),
        PrimaryTerminalButton(
            label: 'Return to terminal', onPressed: () => context.go('/home'))
      ])));
}

class _DataRow extends StatelessWidget {
  const _DataRow(this.label, this.value);
  final String label, value;
  @override
  Widget build(BuildContext context) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(
            child: Text(label,
                style: const TextStyle(color: AppColors.hpTextMuted))),
        const SizedBox(width: 12),
        Flexible(
            child: Text(value,
                textAlign: TextAlign.end,
                style: const TextStyle(fontWeight: FontWeight.w700)))
      ]));
}

class _ResponsivePair extends StatelessWidget {
  const _ResponsivePair({
    required this.wide,
    required this.first,
    required this.second,
    this.firstFlex = 1,
    this.secondFlex = 1,
  });
  final bool wide;
  final Widget first, second;
  final int firstFlex, secondFlex;
  @override
  Widget build(BuildContext context) => wide
      ? Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(flex: firstFlex, child: first),
          const SizedBox(width: 16),
          Expanded(flex: secondFlex, child: second),
        ])
      : Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          first,
          const SizedBox(height: 16),
          second,
        ]);
}
