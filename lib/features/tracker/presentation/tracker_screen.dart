import 'package:flutter/material.dart';

import 'package:activity_tracker/features/auth/data/auth_storage.dart';
import 'package:activity_tracker/features/auth/presentation/login_screen.dart';
import 'package:activity_tracker/features/sessions/data/session_api.dart';
import 'package:activity_tracker/features/tracker/application/activity_tracker_controller.dart';
import 'package:activity_tracker/features/tracker/presentation/widgets/activity_list.dart';
import 'package:activity_tracker/features/tracker/presentation/widgets/device_info_card.dart';

class TrackerScreen extends StatefulWidget {
  const TrackerScreen({super.key});

  @override
  State<TrackerScreen> createState() => _TrackerScreenState();
}

class _TrackerScreenState extends State<TrackerScreen> {
  static const _accent = Color(0xFFBFC7FF);

  final _storage = AuthStorage();
  final _controller = ActivityTrackerController();
  final _sessionApi = SessionApi();
  bool _starting = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onControllerChanged);
  }

  void _onControllerChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _logout() async {
    await _controller.stop();
    await _storage.clearToken();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  Future<void> _toggle() async {
    if (_starting) return;
    if (_controller.isRunning) {
      await _controller.stop();
      await _storage.clearSessionId();
      return;
    }

    setState(() => _starting = true);
    final result = await _sessionApi.start();
    if (!mounted) return;
    setState(() => _starting = false);

    switch (result) {
      case SessionStartSuccess():
        await _controller.start();
      case SessionStartMissingPrereq(:final reason):
        _showError('Cannot start session: $reason');
      case SessionStartFailure(:final message, :final statusCode):
        _showError('Failed to start session (${statusCode ?? '—'}): $message');
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerChanged);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final running = _controller.isRunning;
    final events = _controller.visibleEvents;
    final count = _controller.activityCount;

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text('App Tracking'),
        actions: [
          IconButton(
            tooltip: 'Log out',
            icon: const Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const DeviceInfoCard(),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerLeft,
              child: _TrackToggleButton(
                running: running,
                busy: _starting,
                color: _accent,
                onPressed: _starting ? null : _toggle,
              ),
            ),
            const SizedBox(height: 16),
            _StatusBanner(running: running, count: count),
            const SizedBox(height: 16),
            Expanded(
              child: SingleChildScrollView(
                child: ActivityList(events: events),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TrackToggleButton extends StatelessWidget {
  const _TrackToggleButton({
    required this.running,
    required this.busy,
    required this.color,
    required this.onPressed,
  });

  final bool running;
  final bool busy;
  final Color color;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final label = busy
        ? 'Starting…'
        : running
            ? 'Stop Tracking'
            : 'Start Tracking';
    final icon = running ? Icons.stop : Icons.play_arrow;
    return TextButton.icon(
      onPressed: onPressed,
      icon: busy
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.black87,
              ),
            )
          : Icon(icon, color: Colors.black87),
      label: Text(
        label,
        style: const TextStyle(
          color: Colors.black87,
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
      ),
      style: TextButton.styleFrom(
        backgroundColor: color,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        shape: const StadiumBorder(),
      ),
    );
  }
}

class _StatusBanner extends StatelessWidget {
  const _StatusBanner({required this.running, required this.count});

  final bool running;
  final int count;

  @override
  Widget build(BuildContext context) {
    final label = running ? 'Tracking in progress' : 'Tracking finished';
    final icon = running ? Icons.radio_button_checked : Icons.check_circle_outline;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.white70),
          const SizedBox(width: 10),
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const Spacer(),
          Text(
            '$count ${count == 1 ? 'activity recorded' : 'activities recorded'}',
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
        ],
      ),
    );
  }
}
