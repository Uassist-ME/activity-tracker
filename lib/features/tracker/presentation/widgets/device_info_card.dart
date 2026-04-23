import 'package:flutter/material.dart';

import 'package:activity_tracker/features/tracker/data/device_info_service.dart';

class DeviceInfoCard extends StatefulWidget {
  const DeviceInfoCard({super.key});

  @override
  State<DeviceInfoCard> createState() => _DeviceInfoCardState();
}

class _DeviceInfoCardState extends State<DeviceInfoCard> {
  late final Future<DeviceInfoSnapshot> _future;

  @override
  void initState() {
    super.initState();
    _future = DeviceInfoService().read();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
      ),
      child: FutureBuilder<DeviceInfoSnapshot>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Row(
              children: [
                SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                SizedBox(width: 10),
                Text(
                  'Loading device info...',
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ],
            );
          }
          if (snap.hasError || snap.data == null) {
            return Text(
              'Device info unavailable: ${snap.error ?? 'no data'}',
              style: const TextStyle(color: Colors.white70, fontSize: 13),
            );
          }
          final info = snap.data!;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: const [
                  Icon(Icons.devices_other, size: 18, color: Colors.white70),
                  SizedBox(width: 8),
                  Text(
                    'Device',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _row('Name', info.name),
              _row('Type', info.type),
              _row('OS', info.os),
              _row('OS Version', info.osVersion),
              _row('App Version', info.appVersion),
            ],
          );
        },
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(color: Colors.white, fontSize: 13),
          children: [
            TextSpan(
              text: '$label: ',
              style: const TextStyle(color: Colors.white54),
            ),
            TextSpan(text: value),
          ],
        ),
      ),
    );
  }
}
