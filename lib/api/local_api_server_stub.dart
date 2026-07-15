import 'api_dispatcher.dart';

class LocalApiServer {
  LocalApiServer(this.dispatcher);
  final SimulatorApiDispatcher dispatcher;
  bool get isRunning => false;
  int? get boundPort => null;
  String? get address => null;
  Future<void> start(
          {String host = '0.0.0.0',
          int port = 8443,
          int discoveryPort = 38383}) =>
      Future.error(UnsupportedError('Local sockets are unavailable on web.'));
  Future<void> stop() async {}
}
