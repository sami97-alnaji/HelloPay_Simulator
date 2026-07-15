import 'dart:convert';
import 'dart:io';

Future<Map<String, dynamic>> request(String method, Uri uri,
    [Map<String, dynamic>? body]) async {
  final client = HttpClient();
  try {
    final call = await client.openUrl(method, uri);
    call.headers.contentType = ContentType.json;
    if (body != null) call.write(jsonEncode(body));
    final response = await call.close();
    return jsonDecode(await utf8.decoder.bind(response).join())
        as Map<String, dynamic>;
  } finally {
    client.close(force: true);
  }
}

Object? safeOutput(Object? value) {
  if (value is Map) {
    return value.map((key, nested) {
      final name = key.toString().toLowerCase();
      return MapEntry(
          key.toString(),
          name.contains('token') ||
                  name.contains('pin') ||
                  name.contains('secret') ||
                  name.contains('fingerprint') ||
                  name.contains('certificate')
              ? '[REDACTED]'
              : safeOutput(nested));
    });
  }
  if (value is List) return value.map(safeOutput).toList();
  return value;
}

Future<void> main(List<String> args) async {
  final host = args.isEmpty ? '127.0.0.1' : args.first;
  final port = args.length < 2 ? 8443 : int.parse(args[1]);
  final base = Uri.parse('http://$host:$port');
  void printResponse(String name, Map<String, dynamic> response) {
    stdout.writeln('$name:');
    stdout.writeln(
        const JsonEncoder.withIndent('  ').convert(safeOutput(response)));
  }

  final health = await request('GET', base.resolve('/api/v1/health'));
  printResponse('health', health);

  final otp = await request(
      'POST',
      base.resolve('/api/v1/execute/otpHandshake'),
      {'requestId': 'EXAMPLE-OTP'});
  final pair = await request('POST', base.resolve('/api/v1/pair'), {
    'requestId': 'EXAMPLE-PAIR',
    'token': otp['token'],
    'posId': 'EXAMPLE-POS',
    'posName': 'Standalone Dart Client'
  });
  printResponse('pair', pair);
  final sessionId = (pair['session'] as Map)['sessionId'].toString();
  final session = {'sessionId': sessionId};

  final payment =
      await request('POST', base.resolve('/api/v1/execute/payment'), {
    'requestId': 'EXAMPLE-PAYMENT-1',
    ...session,
    'payload': {'base': 1250, 'service': 0, 'paymentMethod': 'BANK'},
  });
  printResponse('payment', payment);
  final paymentId = (payment['transaction'] as Map)['transactionId'];

  final status =
      await request('POST', base.resolve('/api/v1/execute/getTerminalStatus'), {
    'requestId': 'EXAMPLE-STATUS',
    ...session,
  });
  printResponse('status', status);
  final last = await request(
      'POST', base.resolve('/api/v1/execute/getLastTransaction'), {
    'requestId': 'EXAMPLE-LAST',
    ...session,
  });
  printResponse('getLastTransaction', last);

  final refund = await request('POST', base.resolve('/api/v1/execute/refund'), {
    'requestId': 'EXAMPLE-REFUND',
    ...session,
    'payload': {
      'amount': 250,
      'paymentMethod': 'BANK',
      'userCode': 'demo',
      'originalTransactionId': paymentId,
    },
  });
  printResponse('refund', refund);

  final voidSale =
      await request('POST', base.resolve('/api/v1/execute/payment'), {
    'requestId': 'EXAMPLE-PAYMENT-2',
    ...session,
    'payload': {'base': 500, 'service': 0, 'paymentMethod': 'BANK'},
  });
  final voidResponse = await request(
      'POST', base.resolve('/api/v1/execute/voidLastTransaction'), {
    'requestId': 'EXAMPLE-VOID',
    ...session,
    'payload': {
      'lastTransactionId': (voidSale['transaction'] as Map)['transactionId'],
      'userCode': 'demo',
    },
  });
  printResponse('void', voidResponse);
}
