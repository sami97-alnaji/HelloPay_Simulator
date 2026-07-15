import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/simulator_app.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  FlutterError.onError = (details) {
    if (kDebugMode) FlutterError.presentError(details);
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    if (kDebugMode) debugPrint('Unhandled simulator error');
    return true;
  };
  ErrorWidget.builder = (_) => const Material(
        color: Colors.white,
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'The simulator could not display this screen. Return to the terminal and try again.',
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      );
  runApp(const ProviderScope(child: HelloPaySimulatorApp()));
}
