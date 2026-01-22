import 'package:ai_chat_bot/bootstrap.dart';
import 'package:ai_chat_bot/core/config/env_config.dart';
import 'package:ai_chat_bot/core/config/env_loader.dart';
import 'package:ai_chat_bot/core/logging/app_logger.dart';
import 'package:flutter/material.dart';

class AppInitializer {
  static Future<void> initialize() async {
    WidgetsFlutterBinding.ensureInitialized();

    await EnvLoader.load();
    AppLogger.i('API base URL: ${EnvConfig.apiBaseUrl}');
    // Fallback console log for environments where developer.log isn't visible
    debugPrint('API base URL: ${EnvConfig.apiBaseUrl}');
    await setupDI();

    AppLogger.i('App initialized');
  }
}
