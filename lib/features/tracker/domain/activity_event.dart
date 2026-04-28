import 'package:activity_tracker/core/util/uuid.dart';

class ActivityEvent {
  ActivityEvent({
    String? clientEventId,
    required this.app,
    required this.title,
    required this.detail,
    required this.startedAt,
    required this.endedAt,
    this.url,
    this.domain,
  }) : clientEventId = clientEventId ?? uuidV4();

  final String clientEventId;
  final String app;
  final String title;
  final String detail;
  final String? url;
  final String? domain;
  final DateTime startedAt;
  final DateTime endedAt;

  Duration get duration => endedAt.difference(startedAt);

  Map<String, dynamic> toJson() => {
        'app': app,
        'title': title,
        'detail': detail,
        if (url != null) 'url': url,
        if (domain != null) 'domain': domain,
        'started_at': startedAt.toUtc().toIso8601String(),
        'ended_at': endedAt.toUtc().toIso8601String(),
        'duration_seconds': duration.inSeconds,
      };

  /// Maps the local "completed focus session" model to the backend
  /// `activity-events` schema as a `focus_changed` event occurring at
  /// `startedAt` (the moment focus moved to this window).
  Map<String, dynamic> toBackendJson() => {
        'clientEventId': clientEventId,
        'eventType': 'focus_changed',
        'occurredAt': startedAt.toUtc().toIso8601String(),
        'windowTitle': title,
        'rawAppName': app,
        if (domain != null) 'rawDomain': domain,
      };
}
