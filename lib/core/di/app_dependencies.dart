import 'package:ai_chat_bot/core/di/dependency_injection.dart';
import 'package:ai_chat_bot/core/storage/token_storage.dart';
import 'package:ai_chat_bot/core/theme/theme_controller.dart';
import 'package:ai_chat_bot/features/auth/data/auth_repository.dart';
import 'package:ai_chat_bot/features/auth/presentation/controllers/auth_controller.dart';
import 'package:ai_chat_bot/features/gamification/data/gamification_repository.dart';
import 'package:ai_chat_bot/features/gamification/presentation/controllers/gamification_controller.dart';
import 'package:ai_chat_bot/features/settings/presentation/controllers/settings_controller.dart';
import 'package:ai_chat_bot/features/settings/presentation/controllers/settings_state.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

void ensureAppDependencies({
  required ThemeMode initialTheme,
  SettingsState? initialSettings,
}) {
  if (!Get.isRegistered<ThemeController>()) {
    Get.put(ThemeController(initialTheme: initialTheme), permanent: true);
  }

  if (!Get.isRegistered<SettingsController>()) {
    Get.put(SettingsController(initialState: initialSettings), permanent: true);
  }

  if (!Get.isRegistered<AuthController>()) {
    final authController = AuthController(
      tokenStorage: di<TokenStorage>(),
      authRepository: di<AuthRepository>(),
    );
    authController.appStarted();
    Get.put(authController, permanent: true);
  }

  if (!Get.isRegistered<GamificationController>()) {
    final gamificationController = GamificationController(
      di<GamificationRepository>(),
      di<SharedPreferences>(),
    );
    gamificationController.checkStatus();
    Get.put(gamificationController, permanent: true);
  }
}
