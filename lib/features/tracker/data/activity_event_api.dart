import 'dart:convert';

import 'package:http/http.dart' as http;

import 'package:activity_tracker/core/config/env.dart';
import 'package:activity_tracker/features/auth/data/auth_storage.dart';
import 'package:activity_tracker/features/tracker/domain/activity_event.dart';

class ActivityEventApi {
  ActivityEventApi({http.Client? client, AuthStorage? storage})
      : _client = client ?? http.Client(),
        _storage = storage ?? AuthStorage();

  final http.Client _client;
  final AuthStorage _storage;

  static const int maxBatchSize = 500;

  /// Sends a single batch (1..[maxBatchSize] events). Throws on failure so
  /// callers can keep the events queued for the next flush attempt.
  Future<void> postBatch({
    required String sessionId,
    required List<ActivityEvent> events,
  }) async {
    if (events.isEmpty) return;
    if (events.length > maxBatchSize) {
      throw ArgumentError('Batch size ${events.length} exceeds $maxBatchSize');
    }
    final token = await _storage.getToken();
    if (token == null || token.isEmpty) {
      throw StateError('Missing auth token');
    }

    final uri = Uri.parse('${Env.apiUrl}/activity-events');
    final response = await _client.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'sessionId': sessionId,
        'events': events.map((e) => e.toBackendJson()).toList(),
      }),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw HttpException(
        'activity-events POST failed: ${response.statusCode} ${response.body}',
      );
    }
  }
}

class HttpException implements Exception {
  HttpException(this.message);
  final String message;
  @override
  String toString() => message;
}
