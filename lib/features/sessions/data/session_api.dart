import 'dart:convert';

import 'package:http/http.dart' as http;

import 'package:activity_tracker/core/config/env.dart';
import 'package:activity_tracker/features/auth/data/auth_storage.dart';

sealed class SessionStartResult {
  const SessionStartResult();
}

class SessionStartSuccess extends SessionStartResult {
  final String sessionId;
  const SessionStartSuccess(this.sessionId);
}

class SessionStartMissingPrereq extends SessionStartResult {
  final String reason;
  const SessionStartMissingPrereq(this.reason);
}

class SessionStartFailure extends SessionStartResult {
  final int? statusCode;
  final String message;
  const SessionStartFailure(this.message, {this.statusCode});
}

class SessionApi {
  SessionApi({http.Client? client, AuthStorage? storage})
      : _client = client ?? http.Client(),
        _storage = storage ?? AuthStorage();

  final http.Client _client;
  final AuthStorage _storage;

  Future<SessionStartResult> start() async {
    final token = await _storage.getToken();
    if (token == null || token.isEmpty) {
      return const SessionStartMissingPrereq('Missing auth token');
    }
    final deviceId = await _storage.getDeviceId();
    if (deviceId == null || deviceId.isEmpty) {
      return const SessionStartMissingPrereq('Missing device id');
    }

    final uri = Uri.parse('${Env.apiUrl}/sessions/start');
    try {
      final response = await _client.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
          'X-Device-Id': deviceId,
        },
        body: jsonEncode({'deviceId': deviceId}),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final id = _extractSessionId(response.body);
        if (id == null) {
          return const SessionStartFailure('Response missing sessionId');
        }
        await _storage.saveSessionId(id);
        return SessionStartSuccess(id);
      }

      return SessionStartFailure(
        'Server returned ${response.statusCode}: ${response.body}',
        statusCode: response.statusCode,
      );
    } catch (e) {
      return SessionStartFailure(e.toString());
    }
  }

  String? _extractSessionId(String body) {
    if (body.isEmpty) return null;
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) {
        final candidate = decoded['sessionId'] ??
            decoded['id'] ??
            (decoded['session'] is Map<String, dynamic>
                ? (decoded['session'] as Map<String, dynamic>)['id']
                : null);
        if (candidate is String && candidate.isNotEmpty) return candidate;
        if (candidate is num) return candidate.toString();
      }
    } catch (_) {
      // non-JSON body — ignore
    }
    return null;
  }
}
