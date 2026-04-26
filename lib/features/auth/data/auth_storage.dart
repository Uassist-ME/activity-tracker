import 'package:shared_preferences/shared_preferences.dart';

class AuthStorage {
  static const _tokenKey = 'auth_token';
  static const _deviceRegisteredKey = 'device_registered_fingerprint';
  static const _deviceIdKey = 'device_id';
  static const _sessionIdKey = 'session_id';

  Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_deviceRegisteredKey);
    await prefs.remove(_deviceIdKey);
    await prefs.remove(_sessionIdKey);
  }

  Future<void> saveSessionId(String sessionId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_sessionIdKey, sessionId);
  }

  Future<String?> getSessionId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_sessionIdKey);
  }

  Future<void> clearSessionId() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_sessionIdKey);
  }

  Future<void> saveDeviceId(String deviceId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_deviceIdKey, deviceId);
  }

  Future<String?> getDeviceId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_deviceIdKey);
  }

  Future<String?> getRegisteredDeviceFingerprint() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_deviceRegisteredKey);
  }

  Future<void> markDeviceRegistered(String fingerprint) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_deviceRegisteredKey, fingerprint);
  }
}
