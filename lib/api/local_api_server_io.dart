import 'dart:convert';
import 'dart:io';

import 'api_dispatcher.dart';

class LocalApiServer {
  LocalApiServer(this.dispatcher);
  final SimulatorApiDispatcher dispatcher;
  HttpServer? _server;
  RawDatagramSocket? _udp;
  bool get isRunning => _server != null;
  int? get boundPort => _server?.port;
  String? get address => _server?.address.address;

  Future<void> start(
      {String host = '0.0.0.0',
      int port = 8443,
      int discoveryPort = 38383}) async {
    if (isRunning) return;
    _server = await HttpServer.bind(host, port, shared: false);
    _server!.listen(_handle, onError: (_) {});
    if (discoveryPort >= 0) {
      _udp =
          await RawDatagramSocket.bind(InternetAddress.anyIPv4, discoveryPort);
      _udp!.listen((event) {
        if (event != RawSocketEvent.read) return;
        final packet = _udp!.receive();
        if (packet == null) return;
        final text =
            utf8.decode(packet.data, allowMalformed: true).trim().toUpperCase();
        if (text == 'HELLOPAY_DISCOVER' || text.contains('DISCOVER')) {
          final response = utf8.encode(jsonEncode(discoveryPayload(
              dispatcher.engine.getTerminalId(), boundPort ?? port)));
          _udp!.send(response, packet.address, packet.port);
        }
      });
    }
  }

  Future<void> _handle(HttpRequest request) async {
    request.response.headers.contentType = ContentType.json;
    request.response.headers.set('Access-Control-Allow-Origin', '*');
    if (request.method == 'OPTIONS') {
      request.response.statusCode = 204;
      await request.response.close();
      return;
    }
    ApiResponse result;
    try {
      final text = await utf8.decoder.bind(request).join();
      final decoded =
          text.trim().isEmpty ? <String, dynamic>{} : jsonDecode(text);
      if (decoded is! Map) {
        throw const FormatException('JSON body must be an object');
      }
      result = await dispatcher.dispatch(
          request.method, request.uri.path, Map<String, dynamic>.from(decoded));
    } catch (error) {
      result = await dispatcher.dispatch(request.method, request.uri.path,
          {'malformedRequest': error.toString()});
      if (result.statusCode < 400) {
        result = const ApiResponse(
            400, {'errorCode': 3011, 'errorMessage': 'Malformed JSON'});
      }
    }
    request.response.statusCode = result.statusCode;
    request.response.write(jsonEncode(result.body));
    await request.response.close();
  }

  Future<void> stop() async {
    _udp?.close();
    _udp = null;
    await _server?.close(force: true);
    _server = null;
  }
}

Map<String, Object?> discoveryPayload(String terminalId, int port) => {
      'service': 'HelloPay Simulator',
      'terminalId': terminalId,
      'protocol': 'http',
      'port': port,
      'apiVersion': 'v1'
    };
