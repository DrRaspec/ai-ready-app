import 'dart:convert';
import 'dart:math';

import 'package:ai_chat_bot/core/storage/token_storage.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DeviceIdProvider {
  DeviceIdProvider({
    required TokenStorage tokenStorage,
    DeviceInfoPlugin? deviceInfo,
  }) : _tokenStorage = tokenStorage,
       _deviceInfo = deviceInfo ?? DeviceInfoPlugin();

  static const _storageKey = 'device_id';
  final TokenStorage _tokenStorage;
  final DeviceInfoPlugin _deviceInfo;

  Future<String> getDeviceId() async {
    final secureCached = await _tokenStorage.readDeviceId();
    if (secureCached != null && secureCached.isNotEmpty) {
      return secureCached;
    }

    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getString(_storageKey);
    if (cached != null && cached.isNotEmpty) {
      await _tokenStorage.writeDeviceId(cached);
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
              id =
                  dyn.identifierForVendor ??
                  dyn.vendorIdentifier ??
                  dyn.utsname?.machine;
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
    await _tokenStorage.writeDeviceId(id);
    await prefs.setString(_storageKey, id);
    return id;
  }

  Future<String?> getDeviceName() async {
    try {
      if (kIsWeb) {
        final info = await _deviceInfo.webBrowserInfo;
        final dyn = info as dynamic;
        final browser = dyn.browserName?.toString();
        final vendor = dyn.vendor?.toString();
        if (browser != null && browser.isNotEmpty) return browser;
        if (vendor != null && vendor.isNotEmpty) return vendor;
        return 'Web Browser';
      }

      switch (defaultTargetPlatform) {
        case TargetPlatform.android:
          final info = await _deviceInfo.androidInfo;
          final model = info.model.trim();
          if (model.isNotEmpty) return model;
          return 'Android Device';
        case TargetPlatform.iOS:
          final info = await _deviceInfo.iosInfo;
          final model = info.utsname.machine.trim();
          if (model.isNotEmpty) return model;
          return 'iOS Device';
        case TargetPlatform.macOS:
          final info = await _deviceInfo.macOsInfo;
          final model = info.model.trim();
          if (model.isNotEmpty) return model;
          return 'macOS Device';
        case TargetPlatform.windows:
          final info = await _deviceInfo.windowsInfo;
          final name = info.computerName.trim();
          if (name.isNotEmpty) return name;
          return 'Windows Device';
        case TargetPlatform.linux:
          final info = await _deviceInfo.linuxInfo;
          final name = info.prettyName.trim();
          if (name.isNotEmpty) return name;
          return 'Linux Device';
        case TargetPlatform.fuchsia:
          return 'Fuchsia Device';
      }
    } catch (_) {
      return null;
    }
  }

  Future<String> getDeviceType() async {
    if (kIsWeb) {
      return 'WEB';
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
      case TargetPlatform.iOS:
        return 'MOBILE';
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
      case TargetPlatform.linux:
        return 'DESKTOP';
      case TargetPlatform.fuchsia:
        return 'MOBILE';
    }
  }

  String _generateFallbackId() {
    final rand = Random.secure();
    final bytes = List<int>.generate(16, (_) => rand.nextInt(256));
    return base64UrlEncode(bytes);
  }
}
