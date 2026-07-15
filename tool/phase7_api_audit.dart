import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:hellopay_simulator/api/api_dispatcher.dart';
import 'package:hellopay_simulator/api/local_api_server_io.dart';
import 'package:hellopay_simulator/domain/demo_data.dart';
import 'package:hellopay_simulator/domain/simulator_engine.dart';

Future<void> main() async {
  final evidence = Directory('docs/audit/api')..createSync(recursive: true);
  final engine = SimulatorEngine();
  final dispatcher = SimulatorApiDispatcher(engine);
  final server = LocalApiServer(dispatcher);
  final rows = <Map<String, Object?>>[];
  await server.start(host: '127.0.0.1', port: 0, discoveryPort: 38383);
  final port = server.boundPort!;

  Future<Map<String, dynamic>> call(String name, String method, String path,
      [Map<String, dynamic>? body]) async {
    final client = HttpClient();
    final request =
        await client.openUrl(method, Uri.parse('http://127.0.0.1:$port$path'));
    request.headers.contentType = ContentType.json;
    if (body != null) request.write(jsonEncode(body));
    final response = await request.close();
    final decoded = jsonDecode(await utf8.decoder.bind(response).join())
        as Map<String, dynamic>;
    client.close(force: true);
    final safe = sanitizeJson(decoded);
    File('${evidence.path}${Platform.pathSeparator}$name-response.json')
        .writeAsStringSync(const JsonEncoder.withIndent('  ').convert(safe));
    rows.add({
      'name': name,
      'method': method,
      'path': path,
      'status': response.statusCode,
      'errorCode': decoded['errorCode'],
      'fields': decoded.keys.toList()
    });
    return decoded;
  }

  Future<void> rawMalformed() async {
    final client = HttpClient();
    final request = await client.openUrl(
        'POST', Uri.parse('http://127.0.0.1:$port/api/v1/pair'));
    request.headers.contentType = ContentType.json;
    request.write('{bad-json');
    final response = await request.close();
    final decoded = jsonDecode(await utf8.decoder.bind(response).join())
        as Map<String, dynamic>;
    client.close(force: true);
    File('${evidence.path}${Platform.pathSeparator}malformed-json-response.json')
        .writeAsStringSync(
            const JsonEncoder.withIndent('  ').convert(sanitizeJson(decoded)));
    rows.add({
      'name': 'malformed-json',
      'method': 'POST',
      'path': '/api/v1/pair',
      'status': response.statusCode,
      'errorCode': decoded['errorCode'],
      'fields': decoded.keys.toList()
    });
  }

  await call('health', 'GET', '/api/v1/health');
  final otp = await call('otp-handshake', 'POST',
      '/api/v1/execute/otpHandshake', {'requestId': 'AUDIT-OTP'});
  final pair = await call('pair', 'POST', '/api/v1/pair', {
    'requestId': 'AUDIT-PAIR',
    'token': otp['token'],
    'posId': 'AUDIT-POS',
    'posName': 'Phase 7 Audit'
  });
  final sessionId = (pair['session'] as Map)['sessionId'].toString();
  final session = {'sessionId': sessionId};
  final payment = await call('payment', 'POST', '/api/v1/execute/payment', {
    'requestId': 'AUDIT-PAY-1',
    ...session,
    'payload': {'base': 12500, 'service': 0, 'paymentMethod': 'BANK'}
  });
  final paymentId = (payment['transaction'] as Map)['transactionId'].toString();
  await call(
      'get-last-transaction',
      'POST',
      '/api/v1/execute/getLastTransaction',
      {'requestId': 'AUDIT-LAST', ...session});
  await call(
      'get-tipping-configuration',
      'POST',
      '/api/v1/execute/getTippingConfiguration',
      {'requestId': 'AUDIT-TIP', ...session});
  await call('get-terminal-id', 'POST', '/api/v1/execute/getTerminalId',
      {'requestId': 'AUDIT-ID', ...session});
  await call('get-terminal-status', 'POST', '/api/v1/execute/getTerminalStatus',
      {'requestId': 'AUDIT-STATUS', ...session});
  await call('refund', 'POST', '/api/v1/execute/refund', {
    'requestId': 'AUDIT-REFUND',
    ...session,
    'payload': {
      'amount': 1000,
      'paymentMethod': 'BANK',
      'userCode': 'audit',
      'originalTransactionId': paymentId
    }
  });
  final voidSale = await call('void-sale', 'POST', '/api/v1/execute/payment', {
    'requestId': 'AUDIT-PAY-2',
    ...session,
    'payload': {'base': 200, 'service': 0, 'paymentMethod': 'BANK'}
  });
  await call('void', 'POST', '/api/v1/execute/voidLastTransaction', {
    'requestId': 'AUDIT-VOID',
    ...session,
    'payload': {
      'lastTransactionId': (voidSale['transaction'] as Map)['transactionId'],
      'userCode': 'audit'
    }
  });
  final stornoSale =
      await call('storno-sale', 'POST', '/api/v1/execute/payment', {
    'requestId': 'AUDIT-PAY-3',
    ...session,
    'payload': {'base': 300, 'service': 0, 'paymentMethod': 'BANK'}
  });
  await call('storno', 'POST', '/api/v1/execute/storno', {
    'requestId': 'AUDIT-STORNO',
    ...session,
    'payload': {
      'lastTransactionId': (stornoSale['transaction'] as Map)['transactionId'],
      'userCode': 'audit'
    }
  });
  await call('close', 'POST', '/api/v1/execute/close',
      {'requestId': 'AUDIT-CLOSE', ...session});
  await call('close-batch', 'POST', '/api/v1/execute/closeBatch',
      {'requestId': 'AUDIT-CLOSE-BATCH', ...session});
  await rawMalformed();
  await call('missing-session', 'POST', '/api/v1/execute/payment', {
    'requestId': 'AUDIT-NO-SESSION',
    'payload': {'base': 1, 'service': 0, 'paymentMethod': 'BANK'}
  });
  await call('unknown-session', 'POST', '/api/v1/execute/payment', {
    'requestId': 'AUDIT-UNKNOWN-SESSION',
    'sessionId': 'PS-UNKNOWN',
    'payload': {'base': 1, 'service': 0, 'paymentMethod': 'BANK'}
  });
  await call('invalid-amount', 'POST', '/api/v1/execute/payment', {
    'requestId': 'AUDIT-ZERO',
    ...session,
    'payload': {'base': 0, 'service': 0, 'paymentMethod': 'BANK'}
  });
  await call('negative-tip', 'POST', '/api/v1/execute/payment', {
    'requestId': 'AUDIT-NEG-TIP',
    ...session,
    'payload': {'base': 10, 'tip': -1, 'service': 0, 'paymentMethod': 'BANK'}
  });
  engine.selectedCard = DemoCards.all.firstWhere((card) => card.id == 'szep');
  await call('forbidden-tip', 'POST', '/api/v1/execute/payment', {
    'requestId': 'AUDIT-SZEP-TIP',
    ...session,
    'payload': {'base': 10, 'tip': 1, 'service': 0, 'paymentMethod': 'SZEP'}
  });
  engine.config = engine.config.copyWith(integrationModeEnabled: false);
  await call('integration-disabled', 'POST', '/api/v1/execute/payment', {
    'requestId': 'AUDIT-DISABLED',
    ...session,
    'payload': {'base': 10, 'service': 0, 'paymentMethod': 'BANK'}
  });
  engine.config = engine.config.copyWith(integrationModeEnabled: true);
  engine.selectedCard = DemoCards.all.first;
  dispatcher.artificialDelay = const Duration(milliseconds: 100);
  final first = call('concurrent-first', 'POST', '/api/v1/execute/payment', {
    'requestId': 'AUDIT-CONCURRENT-A',
    ...session,
    'payload': {'base': 10, 'service': 0, 'paymentMethod': 'BANK'}
  });
  await Future<void>.delayed(const Duration(milliseconds: 10));
  await call('concurrent-busy', 'POST', '/api/v1/execute/payment', {
    'requestId': 'AUDIT-CONCURRENT-B',
    ...session,
    'payload': {'base': 10, 'service': 0, 'paymentMethod': 'BANK'}
  });
  await first;
  dispatcher.artificialDelay = Duration.zero;
  await call('unsupported-endpoint', 'POST', '/api/v1/execute/unsupported',
      {'requestId': 'AUDIT-UNSUPPORTED', ...session});
  engine.invalidateSession();
  await call('expired-session', 'POST', '/api/v1/execute/getTerminalStatus',
      {'requestId': 'AUDIT-EXPIRED', ...session});

  final receiver =
      await RawDatagramSocket.bind(InternetAddress.loopbackIPv4, 0);
  final udpResponse = Completer<Map<String, dynamic>>();
  receiver.listen((event) {
    if (event == RawSocketEvent.read) {
      final packet = receiver.receive();
      if (packet != null && !udpResponse.isCompleted) {
        udpResponse.complete(
            jsonDecode(utf8.decode(packet.data)) as Map<String, dynamic>);
      }
    }
  });
  receiver.send(
      utf8.encode(jsonEncode({'type': 'HELLOPAY_DISCOVERY', 'version': '1.0'})),
      InternetAddress.loopbackIPv4,
      38383);
  final discovery =
      await udpResponse.future.timeout(const Duration(seconds: 3));
  receiver.close();
  File('${evidence.path}${Platform.pathSeparator}udp-discovery-response.json')
      .writeAsStringSync(const JsonEncoder.withIndent('  ').convert(discovery));
  rows.add({
    'name': 'udp-discovery',
    'method': 'UDP',
    'path': '38383',
    'status': 'response',
    'errorCode': 0,
    'fields': discovery.keys.toList()
  });
  final initialPort = server.boundPort;
  await server.start(host: '127.0.0.1', port: 0, discoveryPort: 38383);
  rows.add({
    'name': 'duplicate-start',
    'method': 'lifecycle',
    'path': 'server.start',
    'status': server.boundPort == initialPort ? 'protected' : 'failed',
    'errorCode': 0,
    'fields': []
  });
  await server.stop();
  rows.add({
    'name': 'stop',
    'method': 'lifecycle',
    'path': 'server.stop',
    'status': server.isRunning ? 'failed' : 'stopped',
    'errorCode': 0,
    'fields': []
  });
  await server.start(host: '127.0.0.1', port: 0, discoveryPort: 38383);
  rows.add({
    'name': 'restart',
    'method': 'lifecycle',
    'path': 'server.start',
    'status': server.isRunning ? 'running' : 'failed',
    'errorCode': 0,
    'fields': []
  });
  await server.stop();
  File('${evidence.path}${Platform.pathSeparator}endpoint-matrix.json')
      .writeAsStringSync(const JsonEncoder.withIndent('  ').convert(rows));
}
