import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../domain/enums.dart';
import '../domain/models.dart';
import '../theme/app_theme.dart';

String money(num value, [String currency = 'HUF']) =>
    '${value.toStringAsFixed(value % 1 == 0 ? 0 : 2)} $currency';

class TerminalPageScaffold extends StatelessWidget {
  const TerminalPageScaffold({
    super.key,
    required this.title,
    required this.child,
    this.subtitle,
    this.status,
    this.action,
    this.showHeader = true,
  });

  final String title;
  final String? subtitle;
  final TerminalStatus? status;
  final Widget child;
  final Widget? action;
  final bool showHeader;

  @override
  Widget build(BuildContext context) => Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              if (showHeader) BrandedTerminalHeader(status: status),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) => SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 1040),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (Navigator.of(context).canPop()) ...[
                                  IconButton(
                                    tooltip: 'Back',
                                    onPressed: () =>
                                        Navigator.of(context).pop(),
                                    icon: const Icon(Icons.arrow_back_rounded),
                                  ),
                                  const SizedBox(width: 4),
                                ],
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(title,
                                          style: Theme.of(context)
                                              .textTheme
                                              .headlineMedium),
                                      if (subtitle != null) ...[
                                        const SizedBox(height: 5),
                                        Text(subtitle!,
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodyMedium
                                                ?.copyWith(
                                                    color:
                                                        AppColors.hpTextMuted)),
                                      ],
                                    ],
                                  ),
                                ),
                                if (status != null)
                                  TerminalStatusChip(status: status!),
                              ],
                            ),
                            const SizedBox(height: 20),
                            child,
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              if (action != null)
                SafeArea(
                  top: false,
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                    decoration: const BoxDecoration(
                      color: AppColors.hpSurface,
                      border:
                          Border(top: BorderSide(color: AppColors.hpBorder)),
                    ),
                    child: Center(
                        child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 1040),
                            child: action!)),
                  ),
                ),
            ],
          ),
        ),
      );
}

class BrandedTerminalHeader extends StatelessWidget {
  const BrandedTerminalHeader({super.key, this.status});
  final TerminalStatus? status;

  @override
  Widget build(BuildContext context) => ConstrainedBox(
        constraints: BoxConstraints(
            minHeight: MediaQuery.sizeOf(context).width < 600 ? 94 : 112),
        child: CustomPaint(
          painter: _HeaderPainter(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: const BoxDecoration(
                      color: AppColors.hpOrange, shape: BoxShape.circle),
                  child: const Icon(Icons.point_of_sale_rounded,
                      color: Colors.white),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('HelloPay Simulator',
                          style: TextStyle(
                              fontSize: 20, fontWeight: FontWeight.w800)),
                      Text('Integration Terminal',
                          style: TextStyle(color: AppColors.hpTextMuted)),
                    ],
                  ),
                ),
                if (status != null)
                  TerminalStatusChip(status: status!, compact: true),
              ],
            ),
          ),
        ),
      );
}

class _HeaderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
        Offset.zero & size, Paint()..color = AppColors.hpSurfaceMuted);
    final lime = Path()
      ..moveTo(size.width * .47, 0)
      ..quadraticBezierTo(
          size.width * .65, size.height * .82, size.width, size.height * .25)
      ..lineTo(size.width, 0)
      ..close();
    canvas.drawPath(
        lime, Paint()..color = AppColors.hpYellowGreen.withValues(alpha: .55));
    final green = Path()
      ..moveTo(size.width * .64, 0)
      ..quadraticBezierTo(
          size.width * .82, size.height * .72, size.width, size.height * .5)
      ..lineTo(size.width, 0)
      ..close();
    canvas.drawPath(
        green, Paint()..color = AppColors.hpGreen.withValues(alpha: .82));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class TerminalStatusChip extends StatelessWidget {
  const TerminalStatusChip(
      {super.key, required this.status, this.compact = false});
  final TerminalStatus status;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final (color, icon) = switch (status) {
      TerminalStatus.ready => (AppColors.hpSuccess, Icons.check_circle_outline),
      TerminalStatus.busy => (AppColors.hpWarning, Icons.hourglass_top_rounded),
      TerminalStatus.errorState => (AppColors.hpDeclined, Icons.error_outline),
      TerminalStatus.inactive => (
          AppColors.hpTextMuted,
          Icons.power_settings_new
        ),
    };
    return Semantics(
      label: 'Terminal status ${status.wire}',
      child: Container(
        padding: EdgeInsets.symmetric(
            horizontal: compact ? 9 : 12, vertical: compact ? 6 : 8),
        decoration: BoxDecoration(
            color: color.withValues(alpha: .12),
            border: Border.all(color: color),
            borderRadius: BorderRadius.circular(999)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 17, color: color),
          const SizedBox(width: 6),
          Text(status.wire,
              style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w800,
                  fontSize: compact ? 11 : 12))
        ]),
      ),
    );
  }
}

class TerminalPanel extends StatelessWidget {
  const TerminalPanel(
      {super.key,
      required this.child,
      this.padding = const EdgeInsets.all(18)});
  final Widget child;
  final EdgeInsets padding;
  @override
  Widget build(BuildContext context) => Container(
        padding: padding,
        decoration: BoxDecoration(
          color: AppColors.hpSurface,
          border: Border.all(color: AppColors.hpBorder),
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [
            BoxShadow(
                color: Color(0x10000000), blurRadius: 14, offset: Offset(0, 5))
          ],
        ),
        child: child,
      );
}

class PrimaryTerminalButton extends StatelessWidget {
  const PrimaryTerminalButton(
      {super.key,
      required this.label,
      required this.onPressed,
      this.icon,
      this.loading = false});
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool loading;
  @override
  Widget build(BuildContext context) => ElevatedButton.icon(
        onPressed: loading ? null : onPressed,
        icon: loading
            ? const SizedBox.square(
                dimension: 20, child: CircularProgressIndicator(strokeWidth: 2))
            : Icon(icon ?? Icons.arrow_forward_rounded),
        label: Text(label),
      );
}

class SecondaryTerminalButton extends StatelessWidget {
  const SecondaryTerminalButton(
      {super.key, required this.label, required this.onPressed, this.icon});
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  @override
  Widget build(BuildContext context) => OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon ?? Icons.arrow_forward_rounded),
        label: Text(label),
        style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(48),
            side: const BorderSide(color: AppColors.hpBorder),
            foregroundColor: AppColors.hpText),
      );
}

class AmountDisplay extends StatelessWidget {
  const AmountDisplay(
      {super.key,
      required this.amount,
      this.currency = 'HUF',
      this.label = 'Total'});
  final double amount;
  final String currency;
  final String label;
  @override
  Widget build(BuildContext context) => Semantics(
      label: '$label ${money(amount, currency)}',
      child: Column(children: [
        Text(label, style: const TextStyle(color: AppColors.hpTextMuted)),
        const SizedBox(height: 4),
        FittedBox(
            child: Text(money(amount, currency),
                style: const TextStyle(
                    fontSize: 42,
                    fontWeight: FontWeight.w800,
                    fontFeatures: [FontFeature.tabularFigures()])))
      ]));
}

class PaymentCardVisual extends StatelessWidget {
  const PaymentCardVisual(
      {super.key, required this.card, this.selected = false});
  final DemoCard card;
  final bool selected;
  Color get color => switch (card.visualVariant) {
        'green' => const Color(0xFF3F7F3C),
        'blue' => const Color(0xFF415B76),
        'red' => const Color(0xFF963E38),
        'orange' => const Color(0xFFC16D2E),
        'lime' => const Color(0xFF78972E),
        'black' => const Color(0xFF292929),
        _ => const Color(0xFF696969),
      };
  @override
  Widget build(BuildContext context) => AspectRatio(
        aspectRatio: 1.62,
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(16),
              border: selected
                  ? Border.all(color: AppColors.hpOrange, width: 4)
                  : null,
              boxShadow: const [
                BoxShadow(
                    color: Color(0x33000000),
                    blurRadius: 12,
                    offset: Offset(0, 7))
              ]),
          child: DefaultTextStyle(
            style: const TextStyle(color: Colors.white),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                const Icon(Icons.memory_rounded, color: Colors.amberAccent),
                const Spacer(),
                Icon(
                    card.interactionMethod == CardInteractionMethod.contactless
                        ? Icons.contactless_rounded
                        : Icons.credit_card_rounded,
                    color: Colors.white)
              ]),
              const Spacer(),
              Text(card.maskedPan,
                  style: const TextStyle(
                      fontSize: 16,
                      letterSpacing: 1.5,
                      fontWeight: FontWeight.w700)),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(
                    child: Text(card.cardholderName,
                        overflow: TextOverflow.ellipsis)),
                Text(card.expiryLabel)
              ]),
              const SizedBox(height: 6),
              Text(card.cardType,
                  style: const TextStyle(fontWeight: FontWeight.w800)),
            ]),
          ),
        ),
      );
}

class NumericPinPad extends StatelessWidget {
  const NumericPinPad(
      {super.key,
      required this.length,
      required this.onDigit,
      required this.onDelete,
      required this.onConfirm,
      this.enabled = true});
  final int length;
  final ValueChanged<String> onDigit;
  final VoidCallback onDelete;
  final VoidCallback onConfirm;
  final bool enabled;
  @override
  Widget build(BuildContext context) {
    final keys = [
      '1',
      '2',
      '3',
      '4',
      '5',
      '6',
      '7',
      '8',
      '9',
      'delete',
      '0',
      'confirm'
    ];
    return Column(children: [
      Semantics(
          label: '$length PIN digits entered',
          child: Text(List.filled(length, '●').join('  ').padRight(10, '○'),
              style: const TextStyle(fontSize: 28, letterSpacing: 5))),
      const SizedBox(height: 18),
      GridView.count(
        crossAxisCount: 3,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 1.7,
        children: keys
            .map((key) => Semantics(
                  button: true,
                  label: key,
                  child: FilledButton.tonal(
                    onPressed: !enabled
                        ? null
                        : key == 'delete'
                            ? onDelete
                            : key == 'confirm'
                                ? onConfirm
                                : () => onDigit(key),
                    style: FilledButton.styleFrom(
                        minimumSize: const Size(64, 52),
                        foregroundColor: AppColors.hpText,
                        backgroundColor: key == 'confirm'
                            ? AppColors.hpGreen.withValues(alpha: .2)
                            : AppColors.hpSurfaceMuted),
                    child: key == 'delete'
                        ? const Icon(Icons.backspace_outlined)
                        : key == 'confirm'
                            ? const Icon(Icons.check_rounded,
                                color: AppColors.hpSuccess)
                            : Text(key,
                                style: const TextStyle(
                                    fontSize: 22, fontWeight: FontWeight.w700)),
                  ),
                ))
            .toList(),
      ),
    ]);
  }
}

class ProcessingStepView extends StatelessWidget {
  const ProcessingStepView(
      {super.key, required this.current, required this.pinRequired});
  final int current;
  final bool pinRequired;
  @override
  Widget build(BuildContext context) {
    final steps = [
      'Reading card',
      'Verifying card',
      if (pinRequired) 'Verifying PIN',
      'Connecting to processor',
      'Authorizing payment',
      'Finalizing transaction'
    ];
    return Column(children: [
      for (var i = 0; i < steps.length; i++)
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: i < current
              ? const Icon(Icons.check_circle, color: AppColors.hpSuccess)
              : i == current
                  ? const SizedBox.square(
                      dimension: 24,
                      child: CircularProgressIndicator(strokeWidth: 3))
                  : const Icon(Icons.radio_button_unchecked,
                      color: AppColors.hpBorder),
          title: Text(steps[i],
              style: TextStyle(
                  fontWeight:
                      i == current ? FontWeight.w700 : FontWeight.w400)),
          trailing: Text(
              i < current
                  ? 'Complete'
                  : i == current
                      ? 'In progress'
                      : 'Pending',
              style:
                  const TextStyle(fontSize: 12, color: AppColors.hpTextMuted)),
        )
    ]);
  }
}

class TransactionResultView extends StatelessWidget {
  const TransactionResultView({super.key, this.transaction, this.error});
  final Transaction? transaction;
  final Object? error;
  @override
  Widget build(BuildContext context) {
    final approved = transaction?.isSuccessful == true;
    final cancelled = transaction?.status == TransactionStatus.cancelled;
    final timeout = transaction?.status == TransactionStatus.timedOut;
    final color = approved
        ? AppColors.hpSuccess
        : cancelled || timeout
            ? AppColors.hpWarning
            : AppColors.hpDeclined;
    final title = approved
        ? 'Payment approved'
        : cancelled
            ? 'Customer cancelled'
            : timeout
                ? 'Request timed out'
                : 'Payment declined';
    return Semantics(
        liveRegion: true,
        label: title,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
              color: color.withValues(alpha: .1),
              border: Border.all(color: color),
              borderRadius: BorderRadius.circular(14)),
          child: Column(children: [
            Icon(
                approved
                    ? Icons.check_circle_rounded
                    : cancelled
                        ? Icons.cancel_outlined
                        : timeout
                            ? Icons.timer_off_outlined
                            : Icons.highlight_off_rounded,
                color: color,
                size: 64),
            const SizedBox(height: 12),
            Text(title,
                style: TextStyle(
                    color: color, fontSize: 26, fontWeight: FontWeight.w800)),
            if (transaction != null) ...[
              const SizedBox(height: 8),
              AmountDisplay(amount: transaction!.totalAmount),
              const SizedBox(height: 8),
              Text(
                  transaction!.errorMessage ??
                      'Transaction ${transaction!.transactionId}',
                  textAlign: TextAlign.center)
            ]
          ]),
        ));
  }
}

class DeveloperDetailsPanel extends StatelessWidget {
  const DeveloperDetailsPanel(
      {super.key,
      required this.requestJson,
      required this.responseJson,
      this.transaction});
  final String requestJson;
  final String responseJson;
  final Transaction? transaction;
  @override
  Widget build(BuildContext context) => ExpansionTile(
        title: const Text('Developer details'),
        subtitle:
            Text(transaction?.transactionId ?? 'Request and response payloads'),
        childrenPadding: const EdgeInsets.all(12),
        children: [
          _CodeBlock(title: 'Request JSON', value: requestJson),
          const SizedBox(height: 12),
          _CodeBlock(title: 'Response JSON', value: responseJson),
        ],
      );
}

class _CodeBlock extends StatelessWidget {
  const _CodeBlock({required this.title, required this.value});
  final String title;
  final String value;
  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
            color: AppColors.hpSurfaceMuted,
            borderRadius: BorderRadius.circular(10)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(
                child: Text(title,
                    style: const TextStyle(fontWeight: FontWeight.w700))),
            IconButton(
                tooltip: 'Copy $title',
                onPressed: () => Clipboard.setData(ClipboardData(text: value)),
                icon: const Icon(Icons.copy_rounded))
          ]),
          SelectableText(value,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 12))
        ]),
      );
}

class ReceiptPaper extends StatelessWidget {
  const ReceiptPaper({super.key, required this.transaction});
  final Transaction transaction;
  String get receiptText => [
        'DEMO RECEIPT — NOT A REAL PAYMENT',
        'HelloPay Simulator',
        'Terminal HP-SIM-001',
        'Type: ${transaction.type.wire}',
        'Date: ${transaction.createdAt.toLocal()}',
        'Method: ${transaction.paymentMethod.wire}',
        'Base: ${money(transaction.baseAmount)}',
        'Tip: ${money(transaction.tipAmount)}',
        'Service: ${money(transaction.serviceAmount)}',
        'Total: ${money(transaction.totalAmount)}',
        'Card: ${transaction.cardType} ${transaction.maskedCardNumber}',
        'Transaction ID: ${transaction.transactionId}',
        'Request ID: ${transaction.requestId}',
        'External ID: ${transaction.externalId}',
        'Processor: ${transaction.paymentProcessor}',
        if (transaction.requireSignature) 'SIGNATURE REQUIRED',
        transaction.receiptData?.content ?? 'SIMULATOR RECEIPT',
      ].join('\n');
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(26),
        decoration: const BoxDecoration(
            color: Colors.white,
            boxShadow: [BoxShadow(color: Color(0x22000000), blurRadius: 18)]),
        child: Column(children: [
          const Text('DEMO RECEIPT — NOT A REAL PAYMENT',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontWeight: FontWeight.w900,
                  color: AppColors.hpDeclined,
                  fontSize: 17)),
          const Divider(height: 30),
          SelectableText(receiptText,
              style: const TextStyle(fontFamily: 'monospace', height: 1.6))
        ]),
      );
}

String prettyJson(Object? value) =>
    const JsonEncoder.withIndent('  ').convert(value);
