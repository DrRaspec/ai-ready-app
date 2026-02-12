import 'package:ai_chat_bot/core/di/app_dependencies.dart';
import 'package:ai_chat_bot/core/theme/theme_state.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ai_chat_bot/features/gamification/presentation/widgets/achievement_listener.dart';

import '../core/theme/app_theme.dart';
import '../core/theme/theme_controller.dart';
import '../features/settings/presentation/controllers/settings_controller.dart';
import '../features/settings/presentation/controllers/settings_state.dart';
import '../core/routers/app_routes.dart';

class App extends StatelessWidget {
  static bool _controllersInitialized = false;

  final ThemeMode initialTheme;
  final SettingsState? initialSettings;

  const App({
    super.key,
    this.initialTheme = ThemeMode.system,
    this.initialSettings,
  });

  void _ensureControllers() {
    if (_controllersInitialized) return;

    ensureAppDependencies(
      initialTheme: initialTheme,
      initialSettings: initialSettings,
    );

    _controllersInitialized = true;
  }

  @override
  Widget build(BuildContext context) {
    _ensureControllers();

    final themeController = Get.find<ThemeController>();
    final settingsController = Get.find<SettingsController>();

    return Obx(() {
      final ThemeState themeState = themeController.state;
      final SettingsState settingsState = settingsController.state;

      return MaterialApp.router(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(fontFamily: settingsState.fontFamily),
        darkTheme: AppTheme.dark(fontFamily: settingsState.fontFamily),
        themeMode: themeState.mode,
        routerConfig: appRouter,
        builder: (context, child) {
          final mediaQuery = MediaQuery.of(context);
          return MediaQuery(
            data: mediaQuery.copyWith(
              textScaler: TextScaler.linear(settingsState.textScaleFactor),
            ),
            child: AchievementListener(child: child!),
          );
        },
      );
    });
  }
}
