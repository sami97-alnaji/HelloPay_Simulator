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

Future<void> main(List<String> args) async {
  final host = args.isEmpty ? '127.0.0.1' : args.first;
  final port = args.length < 2 ? 8443 : int.parse(args[1]);
  final base = Uri.parse('http://$host:$port');
  final health = await request('GET', base.resolve('/api/health'));
  stdout.writeln(const JsonEncoder.withIndent('  ').convert(health));

  final otp = await request(
      'POST', base.resolve('/api/otpHandshake'), {'requestId': 'EXAMPLE-OTP'});
  final pair = await request('POST', base.resolve('/api/pair'), {
    'requestId': 'EXAMPLE-PAIR',
    'token': otp['token'],
    'posId': 'EXAMPLE-POS',
    'posName': 'Standalone Dart Client'
  });
  stdout.writeln(const JsonEncoder.withIndent('  ').convert(pair));
}
