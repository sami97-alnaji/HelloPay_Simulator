import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../state/simulator_providers.dart';
import 'api_dispatcher.dart';
import 'local_api_server.dart';

class ApiController extends ChangeNotifier {
  ApiController(this.dispatcher) : server = LocalApiServer(dispatcher) {
    dispatcher.onChanged = notifyListeners;
  }
  final SimulatorApiDispatcher dispatcher;
  late final LocalApiServer server;
  String host = '0.0.0.0';
  int port = 8443;
  int discoveryPort = 38383;
  bool paused = false;
  bool working = false;
  String? lastError;
  bool get isSupported => !kIsWeb;
  bool get isRunning => server.isRunning;
  List<ApiExchange> get exchanges => dispatcher.exchanges;

  Future<void> start() async {
    if (!isSupported || working || isRunning) return;
    working = true;
    lastError = null;
    notifyListeners();
    try {
      await server.start(host: host, port: port, discoveryPort: discoveryPort);
    } catch (error) {
      lastError = error.toString();
    } finally {
      working = false;
      notifyListeners();
    }
  }

  Future<void> stop() async {
    working = true;
    notifyListeners();
    await server.stop();
    working = false;
    notifyListeners();
  }

  void clear() => dispatcher.clear();
  void setPaused(bool value) {
    paused = value;
    notifyListeners();
  }

  void updatePort(int value) {
    if (!isRunning) {
      port = value;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    dispatcher.onChanged = null;
    server.stop();
    super.dispose();
  }
}

final apiControllerProvider = ChangeNotifierProvider<ApiController>((ref) {
  final engine = ref.read(simulatorControllerProvider).engine;
  return ApiController(SimulatorApiDispatcher(engine));
});
