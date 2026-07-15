import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/api_controller.dart';
import '../api/api_dispatcher.dart';
import '../state/simulator_providers.dart';
import '../theme/app_theme.dart';
import '../widgets/terminal_widgets.dart';

class ApiMonitorScreen extends ConsumerWidget {
  const ApiMonitorScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final api = ref.watch(apiControllerProvider);
    final terminal = ref.watch(simulatorControllerProvider);
    return TerminalPageScaffold(
      title: 'Local API monitor',
      subtitle:
          'Sanitized requests and responses from the shared simulator engine',
      status: terminal.engine.runtimeState.status,
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        TerminalPanel(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
              Row(children: [
                Icon(api.isRunning ? Icons.lan_rounded : Icons.lan_outlined,
                    color: api.isRunning
                        ? AppColors.hpSuccess
                        : AppColors.hpTextMuted),
                const SizedBox(width: 10),
                Expanded(
                    child: Text(api.isRunning
                        ? 'Listening on http://${api.server.address}:${api.server.boundPort}'
                        : api.isSupported
                            ? 'Server stopped'
                            : 'Local sockets are unavailable in browsers')),
              ]),
              if (api.lastError != null)
                Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Text(api.lastError!,
                        style: const TextStyle(color: AppColors.hpDeclined))),
              const SizedBox(height: 12),
              Wrap(spacing: 10, runSpacing: 10, children: [
                FilledButton.icon(
                    onPressed: !api.isSupported || api.working
                        ? null
                        : api.isRunning
                            ? api.stop
                            : api.start,
                    icon: Icon(api.isRunning ? Icons.stop : Icons.play_arrow),
                    label: Text(api.isRunning ? 'Stop API' : 'Start API')),
                OutlinedButton.icon(
                    onPressed: api.clear,
                    icon: const Icon(Icons.delete_sweep_outlined),
                    label: const Text('Clear log')),
                FilterChip(
                    selected: api.paused,
                    onSelected: api.setPaused,
                    label: const Text('Pause view')),
              ])
            ])),
        const SizedBox(height: 16),
        if (api.exchanges.isEmpty)
          const TerminalPanel(
              child: Center(
                  child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text(
                          'No API traffic yet. Start the server and call /api/health.'))))
        else
          ...api.exchanges.map((entry) => _ExchangeTile(entry: entry)),
      ]),
    );
  }
}

class _ExchangeTile extends StatelessWidget {
  const _ExchangeTile({required this.entry});
  final ApiExchange entry;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: ExpansionTile(
            shape: RoundedRectangleBorder(
                side: const BorderSide(color: AppColors.hpBorder),
                borderRadius: BorderRadius.circular(12)),
            collapsedShape: RoundedRectangleBorder(
                side: const BorderSide(color: AppColors.hpBorder),
                borderRadius: BorderRadius.circular(12)),
            title: Text('${entry.method} ${entry.path}',
                style: const TextStyle(fontWeight: FontWeight.w800)),
            subtitle:
                Text('HTTP ${entry.statusCode} · ${entry.createdAt.toLocal()}'),
            trailing: Icon(
                entry.statusCode < 400
                    ? Icons.check_circle_outline
                    : Icons.error_outline,
                color: entry.statusCode < 400
                    ? AppColors.hpSuccess
                    : AppColors.hpDeclined),
            children: [
              Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text('Request',
                            style: TextStyle(fontWeight: FontWeight.w800)),
                        SelectableText(prettyApiJson(entry.request),
                            style: const TextStyle(fontFamily: 'monospace')),
                        const SizedBox(height: 12),
                        const Text('Response',
                            style: TextStyle(fontWeight: FontWeight.w800)),
                        SelectableText(prettyApiJson(entry.response),
                            style: const TextStyle(fontFamily: 'monospace')),
                        TextButton.icon(
                            onPressed: () => Clipboard.setData(ClipboardData(
                                    text: prettyApiJson({
                                  'request': entry.request,
                                  'response': entry.response
                                }))),
                            icon: const Icon(Icons.copy),
                            label: const Text('Copy sanitized exchange')),
                      ]))
            ]),
      );
}
