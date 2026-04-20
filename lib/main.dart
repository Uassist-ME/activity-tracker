import 'dart:io' show Platform;

import 'package:flutter/material.dart';

import 'package:activity_tracker/core/theme/app_theme.dart';
import 'package:activity_tracker/features/auth/data/auth_storage.dart';
import 'package:activity_tracker/features/auth/presentation/login_screen.dart';
import 'package:activity_tracker/features/permissions/presentation/permissions_screen.dart';
import 'package:activity_tracker/features/tracker/data/focus_tracker_channel.dart';
import 'package:activity_tracker/features/tracker/presentation/tracker_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ActivityTrackerApp());
}

class _Bootstrap {
  _Bootstrap({required this.token, required this.permissions});
  final String? token;
  final PermissionStatus permissions;
}

class ActivityTrackerApp extends StatefulWidget {
  const ActivityTrackerApp({super.key});

  @override
  State<ActivityTrackerApp> createState() => _ActivityTrackerAppState();
}

class _ActivityTrackerAppState extends State<ActivityTrackerApp> {
  final _storage = AuthStorage();
  final _channel = FocusTrackerChannel();
  Future<_Bootstrap>? _bootstrap;

  @override
  void initState() {
    super.initState();
    _bootstrap = _load();
  }

  Future<_Bootstrap> _load() async {
    final results = await Future.wait([
      _storage.getToken(),
      _channel.checkPermissions(),
    ]);
    return _Bootstrap(
      token: results[0] as String?,
      permissions: results[1] as PermissionStatus,
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Activity Tracker',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      home: FutureBuilder<_Bootstrap>(
        future: _bootstrap,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done ||
              snapshot.data == null) {
            return const Scaffold();
          }
          final state = snapshot.data!;
          final token = state.token;
          if (token != null && token.isNotEmpty) {
            return const TrackerScreen();
          }
          if (Platform.isMacOS && !state.permissions.allRequiredGranted) {
            return PermissionsScreen(initialStatus: state.permissions);
          }
          return const LoginScreen();
        },
      ),
    );
  }
}
