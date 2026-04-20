import 'dart:async';

import 'package:flutter/material.dart';

import 'package:activity_tracker/features/auth/presentation/login_screen.dart';
import 'package:activity_tracker/features/tracker/data/focus_tracker_channel.dart';

class PermissionsScreen extends StatefulWidget {
  const PermissionsScreen({super.key, required this.initialStatus});

  final PermissionStatus initialStatus;

  @override
  State<PermissionsScreen> createState() => _PermissionsScreenState();
}

class _PermissionsScreenState extends State<PermissionsScreen> {
  final _channel = FocusTrackerChannel();
  late PermissionStatus _status;
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _status = widget.initialStatus;
    _ticker = Timer.periodic(const Duration(seconds: 2), (_) => _refresh());
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  Future<void> _refresh() async {
    final next = await _channel.checkPermissions();
    if (!mounted) return;
    setState(() => _status = next);
  }

  Future<void> _grant(String kind) async {
    await _channel.requestPermission(kind: kind);
    await _refresh();
  }

  Future<void> _openSettings(String pane) async {
    await _channel.openSystemSettings(pane);
  }

  void _continue() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final canContinue = _status.allRequiredGranted;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Permissions required',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Activity Tracker needs two macOS permissions to read the active app and its window title. Both are one-time toggles in System Settings.',
                style: TextStyle(color: Colors.white70, fontSize: 13),
              ),
              const SizedBox(height: 20),
              _PermissionRow(
                title: 'Automation — System Events',
                subtitle: 'Lets the app ask macOS which app is frontmost.',
                granted: _status.automation,
                onGrant: () => _grant('automation'),
                onOpenSettings: () => _openSettings('automation'),
              ),
              const SizedBox(height: 12),
              _PermissionRow(
                title: 'Accessibility',
                subtitle:
                    'Required to read window titles (tab name, chat name, file name).',
                granted: _status.accessibility,
                onGrant: () => _grant('accessibility'),
                onOpenSettings: () => _openSettings('accessibility'),
              ),
              const SizedBox(height: 12),
              const Text(
                'If you change a permission in System Settings, quit and relaunch the app.',
                style: TextStyle(color: Colors.white38, fontSize: 11),
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: canContinue ? _continue : null,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Continue',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PermissionRow extends StatelessWidget {
  const _PermissionRow({
    required this.title,
    required this.subtitle,
    required this.granted,
    required this.onGrant,
    required this.onOpenSettings,
  });

  final String title;
  final String subtitle;
  final bool granted;
  final Future<void> Function() onGrant;
  final Future<void> Function() onOpenSettings;

  @override
  Widget build(BuildContext context) {
    final icon = granted ? Icons.check_circle : Icons.error_outline;
    final iconColor =
        granted ? const Color(0xFF4CAF50) : const Color(0xFFE57373);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: iconColor),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(color: Colors.white60, fontSize: 12),
                ),
              ],
            ),
          ),
          if (!granted) ...[
            TextButton(onPressed: onGrant, child: const Text('Grant')),
            TextButton(
              onPressed: onOpenSettings,
              child: const Text('Open Settings'),
            ),
          ],
        ],
      ),
    );
  }
}
