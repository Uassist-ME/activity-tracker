import 'dart:io' show Platform;

import 'package:device_info_plus/device_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';

class DeviceInfoSnapshot {
  DeviceInfoSnapshot({
    required this.name,
    required this.type,
    required this.os,
    required this.osVersion,
    required this.appVersion,
  });

  final String name;
  final String type;
  final String os;
  final String osVersion;
  final String appVersion;
}

class DeviceInfoService {
  final _deviceInfo = DeviceInfoPlugin();

  Future<DeviceInfoSnapshot> read() async {
    final pkg = await PackageInfo.fromPlatform();
    final appVersion = pkg.buildNumber.isEmpty
        ? pkg.version
        : '${pkg.version}+${pkg.buildNumber}';

    if (Platform.isMacOS) {
      final info = await _deviceInfo.macOsInfo;
      return DeviceInfoSnapshot(
        name: info.computerName,
        type: _macType(info.model),
        os: 'macOS',
        osVersion: info.osRelease,
        appVersion: appVersion,
      );
    }
    if (Platform.isWindows) {
      final info = await _deviceInfo.windowsInfo;
      return DeviceInfoSnapshot(
        name: info.computerName,
        type: 'PC',
        os: info.productName.isNotEmpty ? info.productName : 'Windows',
        osVersion: '${info.displayVersion} (build ${info.buildNumber})'.trim(),
        appVersion: appVersion,
      );
    }
    return DeviceInfoSnapshot(
      name: Platform.localHostname,
      type: 'Unknown',
      os: Platform.operatingSystem,
      osVersion: Platform.operatingSystemVersion,
      appVersion: appVersion,
    );
  }

  String _macType(String model) {
    final m = model.toLowerCase();
    if (m.contains('book')) return 'Laptop';
    if (m.contains('mac')) return 'Desktop';
    return 'Mac';
  }
}
