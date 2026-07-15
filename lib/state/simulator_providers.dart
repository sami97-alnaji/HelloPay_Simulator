import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/models.dart';
import '../domain/simulator_engine.dart';
import 'simulator_controller.dart';

final simulatorControllerProvider =
    ChangeNotifierProvider<SimulatorController>((ref) => SimulatorController());
final simulatorEngineProvider = Provider<SimulatorEngine>(
    (ref) => ref.watch(simulatorControllerProvider).engine);
final terminalStateProvider = Provider<TerminalRuntimeState>(
    (ref) => ref.watch(simulatorControllerProvider).engine.runtimeState);
final pairingStateProvider = Provider<PairingSession?>(
    (ref) => ref.watch(simulatorControllerProvider).engine.pairingSession);
final selectedCardProvider = Provider<DemoCard>(
    (ref) => ref.watch(simulatorControllerProvider).selectedCard);
final selectedScenarioProvider = Provider<ScenarioPreset>(
    (ref) => ref.watch(simulatorControllerProvider).selectedScenario);
final currentTransactionProvider = Provider<Transaction?>(
    (ref) => ref.watch(simulatorControllerProvider).engine.activeTransaction);
final transactionHistoryProvider = Provider<List<Transaction>>((ref) =>
    List.unmodifiable(
        ref.watch(simulatorControllerProvider).engine.transactionHistory));
final simulatorSettingsProvider = Provider<TerminalConfig>(
    (ref) => ref.watch(simulatorControllerProvider).engine.config);
