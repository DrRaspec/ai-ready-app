import 'package:ai_chat_bot/core/di/dependency_injection.dart';
import 'package:ai_chat_bot/core/storage/token_storage.dart';
import 'package:ai_chat_bot/features/auth/data/auth_repository.dart';
import 'package:ai_chat_bot/features/auth/presentation/controllers/auth_controller.dart';
import 'package:ai_chat_bot/features/auth/presentation/controllers/sessions_controller.dart';
import 'package:get/get.dart';

void ensureAuthDependencies() {
  if (!Get.isRegistered<AuthController>()) {
    final authController = AuthController(
      tokenStorage: di<TokenStorage>(),
      authRepository: di<AuthRepository>(),
    );
    authController.appStarted();
    Get.put(authController, permanent: true);
  }
}

void ensureSessionsDependencies() {
  if (!Get.isRegistered<SessionsController>()) {
    Get.lazyPut<SessionsController>(
      () => SessionsController(di<AuthRepository>()),
      fenix: true,
    );
  }
}
