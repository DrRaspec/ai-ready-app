import 'package:ai_chat_bot/core/di/dependency_injection.dart';
import 'package:ai_chat_bot/features/prompts/data/prompt_repository.dart';
import 'package:ai_chat_bot/features/prompts/presentation/controllers/prompt_controller.dart';
import 'package:get/get.dart';

void ensurePromptDependencies() {
  if (!Get.isRegistered<PromptController>()) {
    Get.lazyPut<PromptController>(
      () => PromptController(di<PromptRepository>()),
      fenix: true,
    );
  }
}
