import 'dart:io';

class ActiveWindowSample {
  ActiveWindowSample({required this.appName, required this.windowTitle});

  final String appName;
  final String windowTitle;
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
    return frontApp & "|||" & winTitle
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
    return ActiveWindowSample(
      appName: parts[0].trim(),
      windowTitle: parts[1].trim(),
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
