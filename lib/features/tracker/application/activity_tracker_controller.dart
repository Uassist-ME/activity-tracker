import 'dart:async';

import 'package:flutter/foundation.dart';

import 'package:activity_tracker/features/tracker/data/focus_tracker_channel.dart';
import 'package:activity_tracker/features/tracker/domain/activity_event.dart';

class ActivityTrackerController extends ChangeNotifier {
  ActivityTrackerController({FocusTrackerChannel? channel})
      : _channel = channel ?? FocusTrackerChannel();

  static const _pollInterval = Duration(seconds: 2);

  final FocusTrackerChannel _channel;
  final List<ActivityEvent> _events = [];

  Timer? _ticker;
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
    _openSample = null;
    _openStart = null;
    _lastTick = null;
    _running = true;
    notifyListeners();
    await _tick();
    _ticker = Timer.periodic(_pollInterval, (_) => _tick());
  }

  Future<void> stop() async {
    if (!_running) return;
    _running = false;
    _ticker?.cancel();
    _ticker = null;
    _closeOpen(DateTime.now());
    notifyListeners();

    // TODO(endpoint): enable when ${API_URL}/events exists.
    // try {
    //   await ActivityApi().postEvents(_events);
    // } catch (_) {
    //   // Swallow for now; retry/queue strategy to be designed when endpoint lands.
    // }
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
    _events.add(
      ActivityEvent(
        app: open.app,
        title: open.title,
        detail: open.detail,
        url: open.url,
        startedAt: start,
        endedAt: end,
      ),
    );
    _openSample = null;
    _openStart = null;
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }
}
