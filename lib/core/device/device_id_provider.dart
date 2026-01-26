import 'dart:convert';
import 'dart:math';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DeviceIdProvider {
  DeviceIdProvider({DeviceInfoPlugin? deviceInfo})
      : _deviceInfo = deviceInfo ?? DeviceInfoPlugin();

  static const _storageKey = 'device_id';
  final DeviceInfoPlugin _deviceInfo;

  Future<String> getDeviceId() async {
    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getString(_storageKey);
    if (cached != null && cached.isNotEmpty) {
      return cached;
    }

    String? id;

    try {
      if (kIsWeb) {
        final info = await _deviceInfo.webBrowserInfo;
        final dyn = info as dynamic;
        id = dyn.userAgent ?? dyn.vendor ?? dyn.browserName;
      } else {
        switch (defaultTargetPlatform) {
          case TargetPlatform.android:
            final info = await _deviceInfo.androidInfo;
            try {
              final dyn = info as dynamic;
              id = dyn.androidId ?? dyn.id ?? dyn.fingerprint;
            } catch (_) {
              id = null;
            }
            break;
          case TargetPlatform.iOS:
            final info = await _deviceInfo.iosInfo;
            try {
              final dyn = info as dynamic;
              id = dyn.identifierForVendor ?? dyn.vendorIdentifier ?? dyn.utsname?.machine;
            } catch (_) {
              id = null;
            }
            break;
          case TargetPlatform.macOS:
            final info = await _deviceInfo.macOsInfo;
            try {
              final dyn = info as dynamic;
              id = dyn.systemGUID ?? dyn.hostName ?? dyn.computerName;
            } catch (_) {
              id = null;
            }
            break;
          case TargetPlatform.windows:
            final info = await _deviceInfo.windowsInfo;
            try {
              final dyn = info as dynamic;
              id = dyn.deviceId ?? dyn.machineId ?? dyn.productName;
            } catch (_) {
              id = null;
            }
            break;
          case TargetPlatform.linux:
            final info = await _deviceInfo.linuxInfo;
            try {
              final dyn = info as dynamic;
              id = dyn.machineId ?? dyn.id ?? dyn.name;
            } catch (_) {
              id = null;
            }
            break;
          case TargetPlatform.fuchsia:
            id = null;
            break;
        }
      }
    } catch (_) {
      id = null;
    }

    id ??= _generateFallbackId();
    await prefs.setString(_storageKey, id);
    return id;
  }

  String _generateFallbackId() {
    final rand = Random.secure();
    final bytes = List<int>.generate(16, (_) => rand.nextInt(256));
    return base64UrlEncode(bytes);
  }
}
