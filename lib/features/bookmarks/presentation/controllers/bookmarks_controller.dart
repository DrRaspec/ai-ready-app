import 'package:get/get.dart';
import 'package:ai_chat_bot/core/storage/local_storage.dart';
import 'bookmarks_state.dart';

class BookmarksController extends GetxController {
  final Rx<BookmarksState> rxState;

  BookmarksState get state => rxState.value;

  void _setState(BookmarksState newState) {
    rxState.value = newState;
  }

  BookmarksController() : rxState = const BookmarksState().obs;

  /// Load all bookmarks from local storage
  void loadBookmarks() {
    _setState(state.copyWith(isLoading: true));

    final bookmarksData = LocalStorage.getAllBookmarks();
    final bookmarks = bookmarksData.map((data) {
      return BookmarkItem.fromMap(data);
    }).toList();

    final bookmarkedIds = bookmarks.map((b) => b.id).toSet();

    _setState(
      state.copyWith(
        bookmarks: bookmarks,
        bookmarkedIds: bookmarkedIds,
        isLoading: false,
      ),
    );
  }

  /// Toggle bookmark on a message
  Future<void> toggleBookmark({
    required String messageId,
    required String content,
    required String role,
    String? conversationId,
    String? conversationTitle,
  }) async {
    if (state.bookmarkedIds.contains(messageId)) {
      // Remove bookmark
      await LocalStorage.removeBookmark(messageId);

      final updatedBookmarks = state.bookmarks
          .where((b) => b.id != messageId)
          .toList();
      final updatedIds = Set<String>.from(state.bookmarkedIds)
        ..remove(messageId);

      _setState(
        state.copyWith(bookmarks: updatedBookmarks, bookmarkedIds: updatedIds),
      );
    } else {
      // Add bookmark
      await LocalStorage.addBookmark(
        messageId: messageId,
        content: content,
        role: role,
        conversationId: conversationId,
        conversationTitle: conversationTitle,
      );

      final newBookmark = BookmarkItem(
        id: messageId,
        content: content,
        role: role,
        conversationId: conversationId,
        conversationTitle: conversationTitle,
        bookmarkedAt: DateTime.now(),
      );

      _setState(
        state.copyWith(
          bookmarks: [newBookmark, ...state.bookmarks],
          bookmarkedIds: {...state.bookmarkedIds, messageId},
        ),
      );
    }
  }

  /// Check if message is bookmarked
  bool isBookmarked(String messageId) {
    return state.bookmarkedIds.contains(messageId);
  }

  /// Remove bookmark
  Future<void> removeBookmark(String messageId) async {
    await LocalStorage.removeBookmark(messageId);

    final updatedBookmarks = state.bookmarks
        .where((b) => b.id != messageId)
        .toList();
    final updatedIds = Set<String>.from(state.bookmarkedIds)..remove(messageId);

    _setState(
      state.copyWith(bookmarks: updatedBookmarks, bookmarkedIds: updatedIds),
    );
  }
}
