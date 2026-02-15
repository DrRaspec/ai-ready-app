import 'package:ai_chat_bot/app/app.dart';
import 'package:ai_chat_bot/core/di/dependency_injection.dart';
import 'package:ai_chat_bot/app/app_initializer.dart';
import 'package:ai_chat_bot/features/settings/presentation/bloc/settings_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_adaptive_kit/flutter_adaptive_kit.dart';

import 'package:shared_preferences/shared_preferences.dart';

Future<void> main() async {
  await AppInitializer.initialize();

  final prefs = await SharedPreferences.getInstance();
  di.registerSingleton<SharedPreferences>(prefs);

  final savedThemeMode = prefs.getString('theme_mode');
  final initialTheme = savedThemeMode != null
      ? ThemeMode.values.firstWhere(
          (e) => e.toString() == savedThemeMode,
          orElse: () => ThemeMode.system,
        )
      : ThemeMode.system;

  // Load Settings
  final textScale = prefs.getDouble('text_scale_factor') ?? 1.0;
  final fontFamily = prefs.getString('font_family') ?? 'Inter';
  final initialSettings = SettingsState(
    textScaleFactor: textScale,
    fontFamily: fontFamily,
  );

  runApp(
    AdaptiveScope(
      breakpoints: AdaptiveBreakpoints.withLandscape(
        phone: 600,
        tablet: 1024,
        desktop: 1440,
        landscapePhone: 700,
        landscapeTablet: 1200,
        landscapeDesktop: 1600,
      ),
      designSize: const DesignSize(
        phone: Size(390, 844),
        tablet: Size(1024, 1366),
        desktop: Size(1440, 900),
      ),
      child: App(initialTheme: initialTheme, initialSettings: initialSettings),
    ),
  );
}
