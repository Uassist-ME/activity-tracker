import 'dart:async';

import 'package:flutter/material.dart';

import 'package:activity_tracker/features/auth/data/auth_storage.dart';
import 'package:activity_tracker/features/auth/presentation/login_screen.dart';

class TrackerScreen extends StatefulWidget {
  const TrackerScreen({super.key});

  @override
  State<TrackerScreen> createState() => _TrackerScreenState();
}

class _TrackerScreenState extends State<TrackerScreen> {
  static const _green = Color(0xFF4CAF50);
  static const _red = Color(0xFFE53935);

  final _storage = AuthStorage();

  Duration _baseElapsed = Duration.zero;
  DateTime? _startedAt;
  Timer? _ticker;

  Future<void> _logout() async {
    _ticker?.cancel();
    _ticker = null;
    await _storage.clearToken();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  bool get _running => _startedAt != null;

  Duration get _currentElapsed {
    final start = _startedAt;
    if (start == null) return _baseElapsed;
    return _baseElapsed + DateTime.now().difference(start);
  }

  void _toggle() {
    setState(() {
      if (_running) {
        _baseElapsed = _currentElapsed;
        _startedAt = null;
        _ticker?.cancel();
        _ticker = null;
      } else {
        _startedAt = DateTime.now();
        _ticker = Timer.periodic(
          const Duration(seconds: 1),
          (_) => setState(() {}),
        );
      }
    });
  }

  String _format(Duration d) {
    String two(int n) => n.toString().padLeft(2, '0');
    final h = two(d.inHours);
    final m = two(d.inMinutes.remainder(60));
    final s = two(d.inSeconds.remainder(60));
    return '$h:$m:$s';
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final elapsed = _format(_currentElapsed);
    final buttonColor = _running ? _red : _green;
    final buttonLabel = _running ? 'STOP' : 'START';

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text('Projects & Tasks'),
        actions: [
          IconButton(
            tooltip: 'Log out',
            icon: const Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 48),
          child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  elapsed,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 56,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: _toggle,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: buttonColor,
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(56),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                    ),
                  ),
                  child: Text(buttonLabel),
                ),
              ],
            ),
          ),
        ),
    );
  }
}
