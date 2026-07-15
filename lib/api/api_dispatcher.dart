import 'dart:async';
import 'dart:convert';

import '../domain/models.dart';
import '../domain/enums.dart';
import '../domain/simulator_engine.dart';
import '../domain/simulator_error.dart';

class ApiResponse {
  const ApiResponse(this.statusCode, this.body);
  final int statusCode;
  final Json body;
}

class ApiExchange {
  ApiExchange(
      {required this.method,
      required this.path,
      required this.request,
      required this.response,
      required this.statusCode,
      required this.createdAt});
  final String method, path;
  final Json request, response;
  final int statusCode;
  final DateTime createdAt;
}

class SimulatorApiDispatcher {
  SimulatorApiDispatcher(this.engine, {this.artificialDelay = Duration.zero});
  final SimulatorEngine engine;
  Duration artificialDelay;
  final List<ApiExchange> exchanges = [];
  final Map<String, ApiResponse> _idempotency = {};
  bool _financialRequestActive = false;
  void Function()? onChanged;

  Future<ApiResponse> dispatch(String method, String path, Json body) async {
    final normalizedMethod = method.toUpperCase();
    final cleanPath = _canonicalPath(path.split('?').first);
    final requestId = body['requestId']?.toString() ??
        (body['payload'] is Map
            ? (body['payload'] as Map)['requestId']?.toString()
            : null) ??
        'REQ-${DateTime.now().microsecondsSinceEpoch}';
    final financial = normalizedMethod == 'POST' &&
        const {
          '/api/payment',
          '/api/refund',
          '/api/void',
          '/api/storno',
          '/api/close',
          '/api/closeBatch'
        }.contains(cleanPath);
    if (financial && _idempotency.containsKey(requestId)) {
      return _record(
          normalizedMethod, cleanPath, body, _idempotency[requestId]!);
    }
    if (financial && _financialRequestActive) {
      return _record(normalizedMethod, cleanPath, body,
          _failure(requestId, ErrorCatalog.lookup(1011), 409));
    }
    if (financial) _financialRequestActive = true;
    ApiResponse response;
    try {
      if (artificialDelay > Duration.zero) {
        await Future<void>.delayed(artificialDelay);
      }
      response = _route(normalizedMethod, cleanPath, body, requestId);
      if (financial) _idempotency[requestId] = response;
    } on FormatException catch (error) {
      response = _invalid(requestId, error.message);
    } catch (error) {
      response = _invalid(requestId, error.toString());
    } finally {
      if (financial) _financialRequestActive = false;
    }
    return _record(normalizedMethod, cleanPath, body, response);
  }

  ApiResponse _route(String method, String path, Json body, String requestId) {
    if (method == 'GET' && path == '/api/health') {
      return _success(requestId, engine.checkHealth());
    }
    if (method == 'GET' && path == '/api/terminalId') {
      return _success(requestId, {'terminalId': engine.getTerminalId()});
    }
    if (method == 'GET' && path == '/api/status') {
      return _success(requestId, {'status': engine.getTerminalStatus().wire});
    }
    if (method == 'GET' && path == '/api/tipping') {
      return _success(requestId, engine.getTippingConfiguration());
    }
    if (method == 'GET' && path == '/api/lastTransaction') {
      return _success(
          requestId, {'transaction': engine.getLastTransaction()?.toJson()});
    }
    if (method != 'POST') {
      return ApiResponse(
          404, _envelope(requestId, 1008, 'Unsupported endpoint'));
    }
    if (path == '/api/pair') {
      final result = engine.createPairingSession(
          token: _required(body, 'token'),
          posId: _required(body, 'posId'),
          posName: _required(body, 'posName'));
      return _result(requestId, result, (value) => {'session': value.toJson()});
    }
    if (path == '/api/otpHandshake') {
      final otp = engine.generateOtp();
      return _success(requestId,
          {'token': otp.value, 'expiresAt': otp.expiresAt.toIso8601String()});
    }
    final sessionError = _validateSession(body);
    if (sessionError != null) return _failure(requestId, sessionError, 401);
    final payload = body['payload'] is Map
        ? Map<String, dynamic>.from(body['payload'] as Map)
        : Map<String, dynamic>.from(body);
    payload.putIfAbsent('requestId', () => requestId);
    if (path == '/api/lastTransaction') {
      return _success(
          requestId, {'transaction': engine.getLastTransaction()?.toJson()});
    }
    if (path == '/api/tipping') {
      return _success(requestId, engine.getTippingConfiguration());
    }
    if (path == '/api/terminalId') {
      return _success(requestId, {'terminalId': engine.getTerminalId()});
    }
    if (path == '/api/status') {
      return _success(requestId, {'status': engine.getTerminalStatus().wire});
    }
    if (path == '/api/payment') {
      return _result(
          requestId,
          engine.processPayment(PaymentRequest.fromJson(payload),
              sessionRequired: true),
          (value) => {'transaction': value.toJson()});
    }
    if (path == '/api/refund') {
      return _result(
          requestId,
          engine.processRefund(RefundRequest.fromJson(payload)),
          (value) => {'transaction': value.toJson()});
    }
    if (path == '/api/void' || path == '/api/storno') {
      return _result(
          requestId,
          engine.voidLastTransaction(VoidRequest.fromJson(payload)),
          (value) => {'transaction': value.toJson()});
    }
    if (path == '/api/close' || path == '/api/closeBatch') {
      return _success(requestId, {'settlement': engine.closeBatch().toJson()});
    }
    return ApiResponse(404, _envelope(requestId, 1008, 'Unsupported endpoint'));
  }

  String _canonicalPath(String path) => switch (path) {
        '/api/v1/health' => '/api/health',
        '/api/v1/pair' => '/api/pair',
        '/api/v1/execute/payment' => '/api/payment',
        '/api/v1/execute/refund' => '/api/refund',
        '/api/v1/execute/voidLastTransaction' => '/api/void',
        '/api/v1/execute/storno' => '/api/storno',
        '/api/v1/execute/close' => '/api/close',
        '/api/v1/execute/closeBatch' => '/api/closeBatch',
        '/api/v1/execute/getLastTransaction' => '/api/lastTransaction',
        '/api/v1/execute/getTippingConfiguration' => '/api/tipping',
        '/api/v1/execute/getTerminalId' => '/api/terminalId',
        '/api/v1/execute/getTerminalStatus' => '/api/status',
        '/api/v1/execute/otpHandshake' => '/api/otpHandshake',
        _ => path,
      };

  SimulatorError? _validateSession(Json body) {
    if (!engine.isSessionValid) return ErrorCatalog.lookup(3004);
    if (body['sessionId']?.toString() != engine.pairingSession?.sessionId) {
      return ErrorCatalog.lookup(3005);
    }
    return null;
  }

  String _required(Json body, String key) {
    final value = body[key]?.toString().trim() ?? '';
    if (value.isEmpty) throw FormatException('Missing $key');
    return value;
  }

  ApiResponse _result<T>(
          String id, SimulatorResult<T> result, Json Function(T) encode) =>
      result.isSuccess
          ? _success(id, encode(result.value as T))
          : _failure(id, result.error!, 422);
  ApiResponse _success(String id, Json data) =>
      ApiResponse(200, {..._envelope(id, 0, null), ...data});
  ApiResponse _failure(String id, SimulatorError error, int status) =>
      ApiResponse(status, {
        ..._envelope(id, error.code, error.userMessage),
        'error': error.toJson()
      });
  ApiResponse _invalid(String id, String message) =>
      ApiResponse(400, _envelope(id, 3011, message));
  Json _envelope(String id, int code, String? message) => {
        'requestId': id,
        'errorCode': code,
        'errorMessage': message,
        'timestamp': DateTime.now().toUtc().toIso8601String()
      };

  ApiResponse _record(
      String method, String path, Json request, ApiResponse response) {
    exchanges.insert(
        0,
        ApiExchange(
            method: method,
            path: path,
            request: sanitizeJson(request),
            response: sanitizeJson(response.body),
            statusCode: response.statusCode,
            createdAt: DateTime.now().toUtc()));
    if (exchanges.length > 200) exchanges.removeLast();
    onChanged?.call();
    return response;
  }

  void clear() {
    exchanges.clear();
    onChanged?.call();
  }
}

Json sanitizeJson(Map value) => value.map((key, raw) {
      final lower = key.toString().toLowerCase();
      if (lower.contains('pin') ||
          lower == 'token' ||
          lower.contains('secret') ||
          lower.contains('fingerprint') ||
          lower.contains('certificate')) {
        return MapEntry(key.toString(), '[REDACTED]');
      }
      if (raw is Map) return MapEntry(key.toString(), sanitizeJson(raw));
      if (raw is List) {
        return MapEntry(
            key.toString(),
            raw
                .map((item) => item is Map ? sanitizeJson(item) : item)
                .toList());
      }
      return MapEntry(key.toString(), raw);
    });

String prettyApiJson(Object? value) =>
    const JsonEncoder.withIndent('  ').convert(value);
