import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/demo_data.dart';
import '../domain/models.dart';
import '../domain/simulator_engine.dart';

final simulatorEngineProvider =
    Provider<SimulatorEngine>((ref) => SimulatorEngine());
final terminalStateProvider = Provider<TerminalRuntimeState>(
    (ref) => ref.watch(simulatorEngineProvider).runtimeState);
final pairingStateProvider = Provider<PairingSession?>(
    (ref) => ref.watch(simulatorEngineProvider).pairingSession);
final selectedCardProvider =
    StateProvider<DemoCard>((ref) => DemoCards.all.first);
final selectedScenarioProvider =
    StateProvider<ScenarioPreset>((ref) => ScenarioPresets.all.first);
final currentTransactionProvider = Provider<Transaction?>(
    (ref) => ref.watch(simulatorEngineProvider).activeTransaction);
final transactionHistoryProvider = Provider<List<Transaction>>((ref) =>
    List.unmodifiable(ref.watch(simulatorEngineProvider).transactionHistory));
final simulatorSettingsProvider = Provider<TerminalConfig>(
    (ref) => ref.watch(simulatorEngineProvider).config);
