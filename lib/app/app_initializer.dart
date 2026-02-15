import 'package:ai_chat_bot/bootstrap.dart';
import 'package:ai_chat_bot/core/config/env_config.dart';
import 'package:ai_chat_bot/core/config/env.dart';
import 'package:ai_chat_bot/core/config/env_loader.dart';
import 'package:ai_chat_bot/core/logging/shadow_log_setup.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_adaptive_kit/flutter_adaptive_kit.dart';
import 'package:shadow_log/shadow_log.dart';

class AppInitializer {
  static Future<void> initialize() async {
    WidgetsFlutterBinding.ensureInitialized();
    await AdaptiveUtils.ensureScreenSize();
    ShadowLogSetup.initialize();

    await EnvLoader.load();
    final apiBaseUrl = EnvConfig.apiBaseUrl.trim();
    if (Env.isProduction && !apiBaseUrl.startsWith('https://')) {
      throw StateError('Production API_BASE_URL must use HTTPS.');
    }
    if (kDebugMode) {
      ShadowLog.i('API base URL: $apiBaseUrl');
    }
    await setupDI();

    ShadowLog.i('App initialized');
  }
}
