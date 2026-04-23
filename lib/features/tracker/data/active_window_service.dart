import 'dart:io';

class ActiveWindowSample {
  ActiveWindowSample({
    required this.appName,
    required this.windowTitle,
    this.url,
  });

  final String appName;
  final String windowTitle;
  final String? url;
}

class ActiveWindowService {
  static const _focusScript = '''
    tell application "System Events"
      set frontProc to first application process whose frontmost is true
      set frontApp to name of frontProc
      try
        set winTitle to name of front window of frontProc
      on error
        set winTitle to ""
      end try
    end tell
    set theURL to ""
    try
      if frontApp is "Safari" then
        tell application "Safari" to set theURL to URL of current tab of front window
      else if frontApp is in {"Google Chrome", "Google Chrome Canary", "Brave Browser", "Microsoft Edge", "Arc", "Vivaldi", "Opera"} then
        using terms from application "Google Chrome"
          tell application frontApp to set theURL to URL of active tab of front window
        end using terms from
      end if
    on error
      set theURL to ""
    end try
    return frontApp & "|||" & winTitle & "|||" & theURL
  ''';

  // A trivial query used to (a) probe whether Automation for System Events is
  // granted and (b) surface the first-time consent prompt.
  static const _pingScript =
      'tell application "System Events" to return ""';

  Future<ActiveWindowSample?> getActive() async {
    final result = await _runOsaScript(_focusScript);
    if (result == null) return null;
    final parts = result.split('|||');
    if (parts.length < 2) return null;
    final url = parts.length >= 3 ? parts[2].trim() : '';
    return ActiveWindowSample(
      appName: parts[0].trim(),
      windowTitle: parts[1].trim(),
      url: url.isEmpty ? null : url,
    );
  }

  Future<bool> isAutomationGranted() async {
    final result = await _runOsaScript(_pingScript);
    return result != null;
  }

  Future<void> requestAutomation() async {
    await _runOsaScript(_pingScript);
  }

  Future<String?> _runOsaScript(String source) async {
    try {
      final r = await Process.run('osascript', ['-e', source]);
      if (r.exitCode != 0) return null;
      final out = (r.stdout as String).trim();
      return out;
    } catch (_) {
      return null;
    }
  }
}
