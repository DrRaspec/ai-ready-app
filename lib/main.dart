import 'package:ai_chat_bot/app/app.dart';
import 'package:ai_chat_bot/app/app_initializer.dart';
import 'package:ai_chat_bot/features/settings/presentation/bloc/settings_state.dart';
import 'package:flutter/material.dart';

import 'package:shared_preferences/shared_preferences.dart';

Future<void> main() async {
  await AppInitializer.initialize();

  final prefs = await SharedPreferences.getInstance();
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

  runApp(App(initialTheme: initialTheme, initialSettings: initialSettings));
}
