import 'package:ai_chat_bot/features/bookmarks/presentation/controllers/bookmarks_controller.dart';
import 'package:get/get.dart';

void ensureBookmarksDependencies() {
  if (!Get.isRegistered<BookmarksController>()) {
    Get.lazyPut<BookmarksController>(() => BookmarksController(), fenix: true);
  }

  final controller = Get.find<BookmarksController>();
  if (controller.state.bookmarks.isEmpty && !controller.state.isLoading) {
    controller.loadBookmarks();
  }
}
