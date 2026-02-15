import 'dart:io';
import 'package:shadow_log/shadow_log.dart';
import 'package:flutter/services.dart';

/// Service for managing iOS alternate app icons
/// This is a free native iOS feature - no payment required
class AppIconService {
  static const MethodChannel _channel = MethodChannel('app_icon_channel');

  /// Available icon options
  static const List<AppIconOption> availableIcons = [
    AppIconOption(
      id: 'AppIcon',
      name: 'Default',
      description: 'Gradient neural network',
      previewAsset: 'assets/icons/app_icon.png',
      isDefault: true,
    ),
    AppIconOption(
      id: 'AppIcon-Dark',
      name: 'Dark',
      description: 'Glowing dark theme',
      previewAsset: 'assets/icons/app_icon_dark.png',
    ),
    AppIconOption(
      id: 'AppIcon-Minimal',
      name: 'Minimal',
      description: 'Clean and simple',
      previewAsset: 'assets/icons/app_icon_minimal.png',
    ),
  ];

  /// Check if alternate icons are supported (iOS only)
  static bool get isSupported => Platform.isIOS;

  /// Get currently active icon ID
  static Future<String?> getCurrentIcon() async {
    if (!isSupported) return null;

    try {
      final String? iconName = await _channel.invokeMethod(
        'getAlternateIconName',
      );
      return iconName ?? 'AppIcon';
    } catch (e) {
      return 'AppIcon';
    }
  }

  /// Set the app icon (null for default)
  static Future<bool> setIcon(String iconId) async {
    if (!isSupported) return false;

    try {
      final String? iconToSet = iconId == 'AppIcon' ? null : iconId;
      await _channel.invokeMethod('setAlternateIconName', {
        'iconName': iconToSet,
      });
      return true;
    } catch (e) {
      ShadowLog.e('Failed to set app icon: $e');
      return false;
    }
  }
}

class AppIconOption {
  final String id;
  final String name;
  final String description;
  final String previewAsset;
  final bool isDefault;

  const AppIconOption({
    required this.id,
    required this.name,
    required this.description,
    required this.previewAsset,
    this.isDefault = false,
  });
}
