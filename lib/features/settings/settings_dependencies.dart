import 'package:ai_chat_bot/core/di/dependency_injection.dart';
import 'package:ai_chat_bot/features/auth/data/auth_repository.dart';
import 'package:ai_chat_bot/features/settings/presentation/controllers/personalization_controller.dart';
import 'package:get/get.dart';

void ensurePersonalizationDependencies() {
  if (!Get.isRegistered<PersonalizationController>()) {
    Get.lazyPut<PersonalizationController>(
      () => PersonalizationController(di<AuthRepository>()),
      fenix: true,
    );
  }
}
