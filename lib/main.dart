import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'theme/app_theme.dart';

void main() => runApp(const ProviderScope(child: HelloPaySimulatorApp()));

/// Phase 3 establishes the shared domain layer; terminal UI flows start later.
class HelloPaySimulatorApp extends StatelessWidget {
  const HelloPaySimulatorApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'HelloPay Simulator',
        theme: AppTheme.light(),
        home: const Scaffold(
          body: Center(child: Text('HelloPay Simulator')),
        ),
      );
}
