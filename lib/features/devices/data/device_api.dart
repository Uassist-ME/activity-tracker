import 'dart:convert';

import 'package:http/http.dart' as http;

import 'package:activity_tracker/core/config/env.dart';
import 'package:activity_tracker/features/auth/data/auth_storage.dart';
import 'package:activity_tracker/features/tracker/data/device_info_service.dart';

sealed class DeviceRegisterResult {
  const DeviceRegisterResult();
}

class DeviceRegisterSuccess extends DeviceRegisterResult {
  final String? deviceId;
  const DeviceRegisterSuccess({this.deviceId});
}

class DeviceRegisterSkipped extends DeviceRegisterResult {
  final String? deviceId;
  const DeviceRegisterSkipped({this.deviceId});
}

class DeviceRegisterFailure extends DeviceRegisterResult {
  final int? statusCode;
  final String message;
  const DeviceRegisterFailure(this.message, {this.statusCode});
}

class DeviceApi {
  DeviceApi({
    http.Client? client,
    AuthStorage? storage,
    DeviceInfoService? deviceInfoService,
  })  : _client = client ?? http.Client(),
        _storage = storage ?? AuthStorage(),
        _deviceInfoService = deviceInfoService ?? DeviceInfoService();

  final http.Client _client;
  final AuthStorage _storage;
  final DeviceInfoService _deviceInfoService;

  Future<DeviceRegisterResult> registerCurrent({
    String? token,
    bool force = false,
  }) async {
    final authToken = token ?? await _storage.getToken();
    if (authToken == null || authToken.isEmpty) {
      return const DeviceRegisterFailure('Missing auth token');
    }

    final snapshot = await _deviceInfoService.read();
    final fingerprint = snapshot.fingerprint();

    if (!force) {
      final last = await _storage.getRegisteredDeviceFingerprint();
      if (last == fingerprint) {
        final cachedId = await _storage.getDeviceId();
        return DeviceRegisterSkipped(deviceId: cachedId);
      }
    }

    final uri = Uri.parse('${Env.apiUrl}/devices/register');
    try {
      final response = await _client.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
        body: jsonEncode(snapshot.toRegisterPayload()),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final deviceId = _extractDeviceId(response.body);
        await _persist(fingerprint, deviceId);
        return DeviceRegisterSuccess(deviceId: deviceId);
      }

      // Treat conflict (already registered) as success — backend has the record.
      if (response.statusCode == 409) {
        final deviceId = _extractDeviceId(response.body);
        await _persist(fingerprint, deviceId);
        return DeviceRegisterSuccess(deviceId: deviceId);
      }

      return DeviceRegisterFailure(
        'Server returned ${response.statusCode}: ${response.body}',
        statusCode: response.statusCode,
      );
    } catch (e) {
      return DeviceRegisterFailure(e.toString());
    }
  }

  Future<void> _persist(String fingerprint, String? deviceId) async {
    await _storage.markDeviceRegistered(fingerprint);
    if (deviceId != null && deviceId.isNotEmpty) {
      await _storage.saveDeviceId(deviceId);
    }
  }

  String? _extractDeviceId(String body) {
    if (body.isEmpty) return null;
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) {
        final candidate = decoded['deviceId'] ??
            decoded['id'] ??
            (decoded['device'] is Map<String, dynamic>
                ? (decoded['device'] as Map<String, dynamic>)['id']
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
