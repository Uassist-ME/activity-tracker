import 'package:flutter/material.dart';

import 'package:activity_tracker/core/theme/app_theme.dart';
import 'package:activity_tracker/features/auth/data/auth_storage.dart';
import 'package:activity_tracker/features/auth/presentation/login_screen.dart';
import 'package:activity_tracker/features/tracker/presentation/tracker_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ActivityTrackerApp());
}

class ActivityTrackerApp extends StatefulWidget {
  const ActivityTrackerApp({super.key});

  @override
  State<ActivityTrackerApp> createState() => _ActivityTrackerAppState();
}

class _ActivityTrackerAppState extends State<ActivityTrackerApp> {
  final _storage = AuthStorage();
  Future<String?>? _initialToken;

  @override
  void initState() {
    super.initState();
    _initialToken = _storage.getToken();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Activity Tracker',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      home: FutureBuilder<String?>(
        future: _initialToken,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Scaffold();
          }
          final token = snapshot.data;
          if (token == null || token.isEmpty) {
            return const LoginScreen();
          }
          return const TrackerScreen();
        },
      ),
    );
  }
}
