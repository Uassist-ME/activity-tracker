class ActivityEvent {
  ActivityEvent({
    required this.app,
    required this.title,
    required this.detail,
    required this.startedAt,
    required this.endedAt,
    this.url,
    this.domain,
  });

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
}
