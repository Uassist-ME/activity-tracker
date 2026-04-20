import 'dart:convert';

import 'package:http/http.dart' as http;

import 'package:activity_tracker/core/config/env.dart';
import 'package:activity_tracker/features/auth/data/auth_storage.dart';
import 'package:activity_tracker/features/tracker/domain/activity_event.dart';

class ActivityApi {
  ActivityApi({http.Client? client, AuthStorage? storage})
      : _client = client ?? http.Client(),
        _storage = storage ?? AuthStorage();

  final http.Client _client;
  final AuthStorage _storage;

  Future<void> postEvents(List<ActivityEvent> events) async {
    if (events.isEmpty) return;
    final token = await _storage.getToken();
    final uri = Uri.parse('${Env.apiUrl}/events');
    final response = await _client.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'events': events.map((e) => e.toJson()).toList(),
      }),
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('postEvents failed: ${response.statusCode} ${response.body}');
    }
  }
}
