import 'package:ai_chat_bot/core/di/dependency_injection.dart';
import 'package:ai_chat_bot/features/auth/data/auth_repository.dart';
import 'package:ai_chat_bot/features/profile/presentation/controllers/profile_controller.dart';
import 'package:get/get.dart';

void ensureProfileDependencies() {
  if (!Get.isRegistered<ProfileController>()) {
    Get.lazyPut<ProfileController>(
      () => ProfileController(di<AuthRepository>()),
      fenix: true,
    );
  }
}
