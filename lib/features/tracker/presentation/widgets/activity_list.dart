import 'package:flutter/material.dart';

import 'package:activity_tracker/features/tracker/domain/activity_event.dart';

class ActivityList extends StatelessWidget {
  const ActivityList({super.key, required this.events});

  final List<ActivityEvent> events;

  static String formatDuration(Duration d) {
    if (d.inHours > 0) {
      final m = d.inMinutes.remainder(60);
      return '${d.inHours}h ${m}m';
    }
    if (d.inMinutes > 0) {
      final s = d.inSeconds.remainder(60);
      return '${d.inMinutes}m ${s}s';
    }
    final seconds = d.inSeconds < 1 ? 1 : d.inSeconds;
    return '${seconds}s';
  }

  @override
  Widget build(BuildContext context) {
    if (events.isEmpty) {
      return const SizedBox.shrink();
    }
    final divider = Divider(
      height: 1,
      color: Colors.white.withValues(alpha: 0.08),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _HeaderRow(),
        divider,
        for (var i = 0; i < events.length; i++) ...[
          _ActivityRow(event: events[i]),
          if (i < events.length - 1) divider,
        ],
      ],
    );
  }
}

class _HeaderRow extends StatelessWidget {
  const _HeaderRow();

  @override
  Widget build(BuildContext context) {
    const style = TextStyle(
      color: Colors.white70,
      fontSize: 13,
      fontWeight: FontWeight.w500,
    );
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 4, vertical: 12),
      child: Row(
        children: [
          SizedBox(width: 110, child: Text('App', style: style)),
          Expanded(child: Text('Detail', style: style)),
          SizedBox(width: 160, child: Text('Domain', style: style)),
          SizedBox(width: 72, child: Text('Time', style: style, textAlign: TextAlign.right)),
        ],
      ),
    );
  }
}

class _ActivityRow extends StatelessWidget {
  const _ActivityRow({required this.event});

  final ActivityEvent event;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              event.app,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            child: Text(
              event.detail,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
          SizedBox(
            width: 160,
            child: Text(
              event.domain ?? '',
              style: const TextStyle(color: Colors.white, fontSize: 14),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
          SizedBox(
            width: 72,
            child: Text(
              ActivityList.formatDuration(event.duration),
              textAlign: TextAlign.right,
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}
