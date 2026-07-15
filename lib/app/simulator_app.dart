import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../screens/terminal_screens.dart';
import '../theme/app_theme.dart';

class HelloPaySimulatorApp extends StatefulWidget {
  const HelloPaySimulatorApp({super.key});

  @override
  State<HelloPaySimulatorApp> createState() => _HelloPaySimulatorAppState();
}

class _HelloPaySimulatorAppState extends State<HelloPaySimulatorApp> {
  late final GoRouter _router = GoRouter(
    initialLocation: '/',
    errorBuilder: (context, state) => NotFoundScreen(path: state.uri.path),
    routes: [
      GoRoute(path: '/', builder: (_, __) => const SplashScreen()),
      GoRoute(path: '/home', builder: (_, __) => const HomeScreen()),
      GoRoute(path: '/pairing', builder: (_, __) => const PairingScreen()),
      GoRoute(path: '/payment', builder: (_, __) => const PaymentEntryScreen()),
      GoRoute(path: '/cards', builder: (_, __) => const CardsScreen()),
      GoRoute(
          path: '/card-presentation',
          builder: (_, __) => const CardPresentationScreen()),
      GoRoute(path: '/pin', builder: (_, __) => const PinScreen()),
      GoRoute(
          path: '/processing', builder: (_, __) => const ProcessingScreen()),
      GoRoute(path: '/result', builder: (_, __) => const ResultScreen()),
      GoRoute(path: '/receipt', builder: (_, __) => const ReceiptScreen()),
      GoRoute(
          path: '/scenarios', builder: (_, __) => const ScenarioStudioScreen()),
      GoRoute(path: '/history', builder: (_, __) => const HistoryScreen()),
      GoRoute(
        path: '/history/:transactionId',
        builder: (_, state) => TransactionDetailScreen(
          transactionId: state.pathParameters['transactionId']!,
        ),
      ),
      GoRoute(path: '/settings', builder: (_, __) => const SettingsScreen()),
      GoRoute(
          path: '/developer-docs',
          builder: (_, __) => const DeveloperDocsScreen()),
    ],
  );

  @override
  Widget build(BuildContext context) => MaterialApp.router(
        title: 'HelloPay Simulator',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        routerConfig: _router,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: MediaQuery.textScalerOf(context).clamp(
              minScaleFactor: 0.8,
              maxScaleFactor: 2,
            ),
          ),
          child: child ?? const SizedBox.shrink(),
        ),
      );
}
