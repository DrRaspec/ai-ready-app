import 'package:equatable/equatable.dart';

class BookmarkItem {
  final String id;
  final String content;
  final String role;
  final String? conversationId;
  final String? conversationTitle;
  final DateTime bookmarkedAt;

  BookmarkItem({
    required this.id,
    required this.content,
    required this.role,
    this.conversationId,
    this.conversationTitle,
    required this.bookmarkedAt,
  });

  factory BookmarkItem.fromMap(Map<dynamic, dynamic> map) {
    return BookmarkItem(
      id: map['id'] as String,
      content: map['content'] as String,
      role: map['role'] as String,
      conversationId: map['conversationId'] as String?,
      conversationTitle: map['conversationTitle'] as String?,
      bookmarkedAt: DateTime.parse(map['bookmarkedAt'] as String),
    );
  }
}

class BookmarksState extends Equatable {
  final List<BookmarkItem> bookmarks;
  final Set<String> bookmarkedIds;
  final bool isLoading;

  const BookmarksState({
    this.bookmarks = const [],
    this.bookmarkedIds = const {},
    this.isLoading = false,
  });

  BookmarksState copyWith({
    List<BookmarkItem>? bookmarks,
    Set<String>? bookmarkedIds,
    bool? isLoading,
  }) {
    return BookmarksState(
      bookmarks: bookmarks ?? this.bookmarks,
      bookmarkedIds: bookmarkedIds ?? this.bookmarkedIds,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  @override
  List<Object?> get props => [bookmarks, bookmarkedIds, isLoading];
}
