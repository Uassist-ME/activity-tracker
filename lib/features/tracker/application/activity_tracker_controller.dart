import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';

import 'package:activity_tracker/features/auth/data/auth_storage.dart';
import 'package:activity_tracker/features/tracker/data/activity_event_api.dart';
import 'package:activity_tracker/features/tracker/data/focus_tracker_channel.dart';
import 'package:activity_tracker/features/tracker/domain/activity_event.dart';

class ActivityTrackerController extends ChangeNotifier {
  ActivityTrackerController({
    FocusTrackerChannel? channel,
    ActivityEventApi? eventApi,
    AuthStorage? storage,
  })  : _channel = channel ?? FocusTrackerChannel(),
        _eventApi = eventApi ?? ActivityEventApi(),
        _storage = storage ?? AuthStorage();

  static const _pollInterval = Duration(seconds: 2);
  static const _flushInterval = Duration(seconds: 30);

  final FocusTrackerChannel _channel;
  final ActivityEventApi _eventApi;
  final AuthStorage _storage;

  final List<ActivityEvent> _events = [];
  final List<ActivityEvent> _unsent = [];

  Timer? _ticker;
  Timer? _flushTimer;
  bool _flushing = false;
  bool _running = false;

  // Currently-open session (not yet pushed into _events).
  FocusSample? _openSample;
  DateTime? _openStart;
  DateTime? _lastTick;

  bool get isRunning => _running;
  List<ActivityEvent> get events => List.unmodifiable(_events);
  int get activityCount => _events.length + (_openSample != null ? 1 : 0);

  /// Snapshot combining committed events + the in-progress session so the UI
  /// can render a live-growing row for the currently-focused window.
  List<ActivityEvent> get visibleEvents {
    final now = _lastTick ?? DateTime.now();
    final open = _openSample;
    final start = _openStart;
    final list = [..._events];
    if (open != null && start != null) {
      list.add(
        ActivityEvent(
          app: open.app,
          title: open.title,
          detail: open.detail,
          url: open.url,
          domain: open.domain,
          startedAt: start,
          endedAt: now,
        ),
      );
    }
    return list.reversed.toList(growable: false);
  }

  Future<void> start() async {
    if (_running) return;
    _events.clear();
    _unsent.clear();
    _openSample = null;
    _openStart = null;
    _lastTick = null;
    _running = true;
    notifyListeners();
    await _tick();
    _ticker = Timer.periodic(_pollInterval, (_) => _tick());
    _flushTimer = Timer.periodic(_flushInterval, (_) => _flush());
  }

  Future<void> stop() async {
    if (!_running) return;
    _running = false;
    _ticker?.cancel();
    _ticker = null;
    _flushTimer?.cancel();
    _flushTimer = null;
    _closeOpen(DateTime.now());
    notifyListeners();
    await _flush();
  }

  Future<void> _flush() async {
    if (_flushing) return;
    if (_unsent.isEmpty) return;
    final sessionId = await _storage.getSessionId();
    if (sessionId == null || sessionId.isEmpty) return;

    _flushing = true;
    try {
      final batch = _unsent
          .take(ActivityEventApi.maxBatchSize)
          .toList(growable: false);
      await _eventApi.postBatch(sessionId: sessionId, events: batch);
      _unsent.removeRange(0, batch.length);
    } catch (e) {
      developer.log(
        'activity-events flush failed; will retry next tick: $e',
        name: 'tracker.flush',
      );
    } finally {
      _flushing = false;
    }
  }

  Future<void> _tick() async {
    if (!_running) return;
    final sample = await _channel.getFocus();
    final now = DateTime.now();
    _lastTick = now;
    if (sample == null) {
      // Lost focus / unsupported platform — keep the previous open session growing.
      notifyListeners();
      return;
    }
    final open = _openSample;
    if (open == null) {
      _openSample = sample;
      _openStart = now;
    } else if (open.identity != sample.identity) {
      _closeOpen(now);
      _openSample = sample;
      _openStart = now;
    }
    notifyListeners();
  }

  void _closeOpen(DateTime end) {
    final open = _openSample;
    final start = _openStart;
    if (open == null || start == null) return;
    final event = ActivityEvent(
      app: open.app,
      title: open.title,
      detail: open.detail,
      url: open.url,
      domain: open.domain,
      startedAt: start,
      endedAt: end,
    );
    _events.add(event);
    _unsent.add(event);
    _openSample = null;
    _openStart = null;
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _flushTimer?.cancel();
    super.dispose();
  }
}
