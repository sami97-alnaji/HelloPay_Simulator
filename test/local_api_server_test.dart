import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hellopay_simulator/api/api_dispatcher.dart';
import 'package:hellopay_simulator/api/local_api_server_io.dart';
import 'package:hellopay_simulator/domain/simulator_engine.dart';

void main() {
  late SimulatorEngine engine;
  late SimulatorApiDispatcher dispatcher;
  late LocalApiServer server;
  late HttpClient client;

  Future<Map<String, dynamic>> call(String method, String path,
      [Map<String, dynamic>? body, int? expectedStatus]) async {
    final request = await client.openUrl(
        method, Uri.parse('http://127.0.0.1:${server.boundPort}$path'));
    request.headers.contentType = ContentType.json;
    if (body != null) request.write(jsonEncode(body));
    final response = await request.close();
    final decoded = jsonDecode(await utf8.decoder.bind(response).join())
        as Map<String, dynamic>;
    if (expectedStatus != null) expect(response.statusCode, expectedStatus);
    return decoded;
  }

  Future<String> pair() async {
    final token = engine.generateOtp().value;
    final response = await call(
        'POST',
        '/api/pair',
        {
          'requestId': 'PAIR-1',
          'token': token,
          'posId': 'POS-1',
          'posName': 'Test POS'
        },
        200);
    return (response['session'] as Map)['sessionId'].toString();
  }

  setUp(() async {
    engine = SimulatorEngine();
    dispatcher = SimulatorApiDispatcher(engine);
    server = LocalApiServer(dispatcher);
    client = HttpClient();
    await server.start(host: '127.0.0.1', port: 0, discoveryPort: -1);
  });
  tearDown(() async {
    client.close(force: true);
    await server.stop();
  });

  test('real HTTP health endpoint returns standard envelope', () async {
    final response = await call('GET', '/api/health', null, 200);
    expect(response['healthy'], isTrue);
    expect(response['errorCode'], 0);
  });

  test('pair creates a session through an actual HTTP request', () async {
    final session = await pair();
    expect(session, startsWith('PS-'));
    expect(engine.isSessionValid, isTrue);
  });

  test('invalid pairing token is rejected', () async {
    final response = await call(
        'POST',
        '/api/pair',
        {'requestId': 'P', 'token': '000000', 'posId': 'P', 'posName': 'POS'},
        422);
    expect(response['errorCode'], 3001);
  });

  test('payment requires an active matching session', () async {
    final response = await call('POST', '/api/payment',
        {'requestId': 'PAY-0', 'sessionId': 'missing', 'payload': {}}, 401);
    expect(response['errorCode'], 3004);
  });

  test('payment, last transaction and close batch share one engine', () async {
    final session = await pair();
    final payment = await call(
        'POST',
        '/api/payment',
        {
          'requestId': 'PAY-1',
          'sessionId': session,
          'payload': {
            'base': 1200,
            'service': 0,
            'paymentMethod': 'BANK',
            'userCode': 'demo'
          }
        },
        200);
    expect((payment['transaction'] as Map)['totalAmount'], 1200);
    final last = await call('GET', '/api/lastTransaction', null, 200);
    expect((last['transaction'] as Map)['requestId'], 'PAY-1');
    final close = await call('POST', '/api/closeBatch',
        {'requestId': 'CLOSE-1', 'sessionId': session, 'payload': {}}, 200);
    expect((close['settlement'] as Map)['paymentCount'], 1);
  });

  test('idempotent requestId does not duplicate a payment', () async {
    final session = await pair();
    final request = {
      'requestId': 'IDEMPOTENT',
      'sessionId': session,
      'payload': {'base': 500, 'service': 0, 'paymentMethod': 'BANK'}
    };
    final first = await call('POST', '/api/payment', request, 200);
    final second = await call('POST', '/api/payment', request, 200);
    expect((first['transaction'] as Map)['transactionId'],
        (second['transaction'] as Map)['transactionId']);
    expect(engine.transactionHistory, hasLength(1));
  });

  test('concurrent financial request receives terminal busy', () async {
    final session = await pair();
    dispatcher.artificialDelay = const Duration(milliseconds: 80);
    final first = call('POST', '/api/payment', {
      'requestId': 'A',
      'sessionId': session,
      'payload': {'base': 1, 'service': 0, 'paymentMethod': 'BANK'}
    });
    await Future<void>.delayed(const Duration(milliseconds: 10));
    final second = await call(
        'POST',
        '/api/payment',
        {
          'requestId': 'B',
          'sessionId': session,
          'payload': {'base': 1, 'service': 0, 'paymentMethod': 'BANK'}
        },
        409);
    expect(second['errorCode'], 1011);
    await first;
  });

  test('unsupported endpoint returns 404', () async {
    final response = await call('GET', '/api/unknown', null, 404);
    expect(response['errorCode'], 1008);
  });

  test('server start is idempotent and stop releases state', () async {
    final port = server.boundPort;
    await server.start(host: '127.0.0.1', port: 0, discoveryPort: -1);
    expect(server.boundPort, port);
    await server.stop();
    expect(server.isRunning, isFalse);
  });

  test('monitor sanitizes tokens and nested PIN values', () async {
    await dispatcher.dispatch('POST', '/api/pair', {
      'requestId': 'SAFE',
      'token': '123456',
      'posId': 'P',
      'posName': 'POS',
      'payload': {'pin': '9999'}
    });
    final logged = dispatcher.exchanges.first.request;
    expect(logged['token'], '[REDACTED]');
    expect((logged['payload'] as Map)['pin'], '[REDACTED]');
  });

  test('discovery payload publishes endpoint metadata only', () {
    final payload = discoveryPayload('HP-SIM-001', 8443);
    expect(payload['service'], 'HelloPay Simulator');
    expect(payload['port'], 8443);
    expect(payload.containsKey('token'), isFalse);
  });
}
