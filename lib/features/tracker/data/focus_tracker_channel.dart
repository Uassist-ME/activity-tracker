import 'dart:io' show Platform;

import 'package:flutter/services.dart';

import 'package:activity_tracker/features/tracker/data/active_window_service.dart';

class FocusSample {
  FocusSample({required this.app, required this.title, this.url});

  final String app;
  final String title;
  final String? url;

  String get identity => '$app|$title|${url ?? ''}';

  String get detail {
    final cleaned = _stripAppSuffix(title);
    if (url != null && url!.isNotEmpty) {
      return cleaned.isEmpty ? url! : '$cleaned — $url';
    }
    return cleaned;
  }

  static final _trailingAppRegex = RegExp(
    r'\s*[-—–|]\s*(Google Chrome|Safari|Firefox|Arc|Microsoft Edge|Brave Browser|Microsoft Teams|Visual Studio Code)\s*$',
  );

  static String _stripAppSuffix(String title) {
    final trimmed = title.trim();
    if (trimmed.isEmpty) return '';
    return trimmed.replaceAll(_trailingAppRegex, '').trim();
  }
}

class PermissionStatus {
  PermissionStatus({required this.automation, required this.accessibility});

  final bool automation;
  final bool accessibility;

  bool get allRequiredGranted => automation && accessibility;

  static PermissionStatus allowed() =>
      PermissionStatus(automation: true, accessibility: true);
}

class FocusTrackerChannel {
  static const _channel = MethodChannel('activity_tracker/focus');

  final _macService = ActiveWindowService();

  // --- Focus sampling ---

  Future<FocusSample?> getFocus() async {
    if (Platform.isMacOS) return _getFocusMac();
    return _getFocusViaChannel();
  }

  Future<FocusSample?> _getFocusMac() async {
    final sample = await _macService.getActive();
    if (sample == null) return null;
    if (sample.appName.isEmpty && sample.windowTitle.isEmpty) return null;
    return FocusSample(app: sample.appName, title: sample.windowTitle);
  }

  Future<FocusSample?> _getFocusViaChannel() async {
    try {
      final result = await _channel.invokeMethod<Map<Object?, Object?>>(
        'getFocus',
      );
      if (result == null) return null;
      final app = (result['app'] as String?)?.trim() ?? '';
      final title = (result['title'] as String?)?.trim() ?? '';
      final url = (result['url'] as String?)?.trim();
      if (app.isEmpty && title.isEmpty) return null;
      return FocusSample(
        app: app,
        title: title,
        url: (url == null || url.isEmpty) ? null : url,
      );
    } on MissingPluginException {
      return null;
    } on PlatformException {
      return null;
    }
  }

  // --- Permissions ---

  Future<PermissionStatus> checkPermissions() async {
    if (!Platform.isMacOS) return PermissionStatus.allowed();
    final automation = await _macService.isAutomationGranted();
    bool accessibility = false;
    try {
      accessibility = (await _channel.invokeMethod<bool>(
            'checkAccessibility',
          )) ??
          false;
    } on MissingPluginException {
      // ignore
    } on PlatformException {
      // ignore
    }
    return PermissionStatus(
      automation: automation,
      accessibility: accessibility,
    );
  }

  Future<void> requestPermission({required String kind}) async {
    if (!Platform.isMacOS) return;
    if (kind == 'automation') {
      await _macService.requestAutomation();
    } else if (kind == 'accessibility') {
      try {
        await _channel.invokeMethod('requestAccessibility');
      } on MissingPluginException {
        // ignore
      } on PlatformException {
        // ignore
      }
    }
  }

  Future<void> openSystemSettings(String pane) async {
    if (!Platform.isMacOS) return;
    try {
      await _channel.invokeMethod('openSystemSettings', {'pane': pane});
    } on MissingPluginException {
      // ignore
    } on PlatformException {
      // ignore
    }
  }
}
