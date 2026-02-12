import 'package:ai_chat_bot/core/di/dependency_injection.dart';
import 'package:ai_chat_bot/features/bookmarks/bookmarks_dependencies.dart';
import 'package:ai_chat_bot/features/chat/data/chat_repository.dart';
import 'package:ai_chat_bot/features/chat/data/folder_repository.dart';
import 'package:ai_chat_bot/features/chat/presentation/controllers/chat_controller.dart';
import 'package:ai_chat_bot/features/chat/presentation/controllers/folder_controller.dart';
import 'package:ai_chat_bot/features/chat/presentation/controllers/folder_state.dart';
import 'package:ai_chat_bot/features/chat/presentation/controllers/usage_controller.dart';
import 'package:get/get.dart';

void ensureChatDependencies() {
  if (!Get.isRegistered<ChatController>()) {
    Get.lazyPut<ChatController>(
      () => ChatController(di<ChatRepository>()),
      fenix: true,
    );
  }

  if (!Get.isRegistered<FolderController>()) {
    Get.lazyPut<FolderController>(
      () => FolderController(di<FolderRepository>()),
      fenix: true,
    );
  }

  ensureBookmarksDependencies();

  final folderController = Get.find<FolderController>();
  if (folderController.state is FolderInitial) {
    folderController.loadFolders();
  }
}

void ensureUsageDependencies() {
  ensureChatDependencies();

  if (!Get.isRegistered<UsageController>()) {
    Get.lazyPut<UsageController>(
      () => UsageController(Get.find<ChatController>()),
      fenix: true,
    );
  }
}
