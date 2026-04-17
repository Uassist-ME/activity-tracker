import 'dart:convert';

import 'package:http/http.dart' as http;

import 'package:activity_tracker/core/config/env.dart';

sealed class LoginResult {
  const LoginResult();
}

class LoginSuccess extends LoginResult {
  final String token;
  const LoginSuccess(this.token);
}

class LoginInvalidCredentials extends LoginResult {
  const LoginInvalidCredentials();
}

class LoginError extends LoginResult {
  final String message;
  const LoginError(this.message);
}

class AuthApi {
  final http.Client _client;

  AuthApi({http.Client? client}) : _client = client ?? http.Client();

  Future<LoginResult> login({
    required String email,
    required String password,
  }) async {
    final uri = Uri.parse('${Env.apiUrl}/auth/login');

    try {
      final response = await _client.post(
        uri,
        headers: const {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      if (response.statusCode == 200) {
        final token = _extractToken(response.body);
        return LoginSuccess(token);
      }

      if (response.statusCode == 401) {
        return const LoginInvalidCredentials();
      }

      return LoginError('Server returned ${response.statusCode}');
    } catch (e) {
      return LoginError(e.toString());
    }
  }

  String _extractToken(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) {
        final candidate = decoded['token'] ?? decoded['access_token'];
        if (candidate is String && candidate.isNotEmpty) return candidate;
      }
    } catch (_) {
      // fall through — keep raw body as placeholder token
    }
    return body;
  }
}
