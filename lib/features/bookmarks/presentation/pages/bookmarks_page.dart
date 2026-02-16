import 'package:ai_chat_bot/features/bookmarks/presentation/bloc/bookmarks_cubit.dart';
import 'package:ai_chat_bot/features/bookmarks/presentation/bloc/bookmarks_state.dart';
import 'package:ai_chat_bot/core/localization/app_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

enum _BookmarkRoleFilter { all, assistant, user }

class BookmarksPage extends StatefulWidget {
  const BookmarksPage({super.key});

  @override
  State<BookmarksPage> createState() => _BookmarksPageState();
}

class _BookmarksPageState extends State<BookmarksPage> {
  String _searchQuery = '';
  _BookmarkRoleFilter _roleFilter = _BookmarkRoleFilter.all;

  bool get _hasActiveFilters =>
      _searchQuery.isNotEmpty || _roleFilter != _BookmarkRoleFilter.all;

  @override
  void initState() {
    super.initState();
    context.read<BookmarksCubit>().loadBookmarks();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(context.t.bookmarks),
        actions: [
          if (_hasActiveFilters)
            IconButton(
              icon: const Icon(Icons.filter_alt_off_rounded),
              tooltip: context.t.tr('Clear filters', 'សម្អាតតម្រង'),
              onPressed: () {
                setState(() {
                  _searchQuery = '';
                  _roleFilter = _BookmarkRoleFilter.all;
                });
              },
            ),
          IconButton(
            icon: const Icon(Icons.search_rounded),
            onPressed: () {
              showSearch(
                context: context,
                delegate: _BookmarkSearchDelegate(
                  onSearch: (query) {
                    setState(() => _searchQuery = query);
                  },
                ),
              );
            },
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              colorScheme.primary.withValues(alpha: 0.1),
              theme.scaffoldBackgroundColor,
              theme.scaffoldBackgroundColor,
            ],
          ),
        ),
        child: BlocBuilder<BookmarksCubit, BookmarksState>(
          builder: (context, state) {
            if (state.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            final filteredBookmarks = _applyFilters(state.bookmarks);
            final sections = _groupByDate(filteredBookmarks);

            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                  child: _buildFilterChips(state.bookmarks),
                ),
                Expanded(
                  child: filteredBookmarks.isEmpty
                      ? _buildEmptyState(theme, colorScheme)
                      : AnimatedSwitcher(
                          duration: const Duration(milliseconds: 220),
                          child: ListView(
                            key: ValueKey(
                              '${_searchQuery}_${_roleFilter.name}_${filteredBookmarks.length}',
                            ),
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                            children: [
                              for (final section in sections) ...[
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                    4,
                                    6,
                                    4,
                                    8,
                                  ),
                                  child: Text(
                                    section.title,
                                    style: theme.textTheme.titleSmall?.copyWith(
                                      fontWeight: FontWeight.w700,
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ),
                                for (final bookmark in section.items)
                                  Dismissible(
                                    key: ValueKey(bookmark.id),
                                    direction: DismissDirection.endToStart,
                                    background: Container(
                                      margin: const EdgeInsets.only(bottom: 12),
                                      alignment: Alignment.centerRight,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 20,
                                      ),
                                      decoration: BoxDecoration(
                                        color: colorScheme.errorContainer,
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: Icon(
                                        Icons.delete_outline_rounded,
                                        color: colorScheme.onErrorContainer,
                                      ),
                                    ),
                                    onDismissed: (_) =>
                                        _removeBookmarkWithUndo(bookmark),
                                    child: _BookmarkCard(
                                      bookmark: bookmark,
                                      onRemove: () =>
                                          _removeBookmarkWithUndo(bookmark),
                                      onTap: () {
                                        if (bookmark.conversationId != null) {
                                          context.push(
                                            '/chat',
                                            extra: {
                                              'conversationId':
                                                  bookmark.conversationId,
                                              'messageId': bookmark.id,
                                            },
                                          );
                                        }
                                      },
                                    ),
                                  ),
                                const SizedBox(height: 2),
                              ],
                            ],
                          ),
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  List<BookmarkItem> _applyFilters(List<BookmarkItem> bookmarks) {
    Iterable<BookmarkItem> filtered = bookmarks;

    if (_roleFilter == _BookmarkRoleFilter.assistant) {
      filtered = filtered.where((b) => b.role == 'assistant');
    } else if (_roleFilter == _BookmarkRoleFilter.user) {
      filtered = filtered.where((b) => b.role != 'assistant');
    }

    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered = filtered.where(
        (b) =>
            b.content.toLowerCase().contains(query) ||
            (b.conversationTitle?.toLowerCase().contains(query) ?? false),
      );
    }

    final filteredList = filtered.toList()
      ..sort((a, b) => b.bookmarkedAt.compareTo(a.bookmarkedAt));
    return filteredList;
  }

  List<_BookmarkSection> _groupByDate(List<BookmarkItem> bookmarks) {
    final today = <BookmarkItem>[];
    final thisWeek = <BookmarkItem>[];
    final thisMonth = <BookmarkItem>[];
    final earlier = <BookmarkItem>[];

    for (final bookmark in bookmarks) {
      final daysOld = _daysOld(bookmark.bookmarkedAt);
      if (daysOld == 0) {
        today.add(bookmark);
      } else if (daysOld <= 7) {
        thisWeek.add(bookmark);
      } else if (daysOld <= 30) {
        thisMonth.add(bookmark);
      } else {
        earlier.add(bookmark);
      }
    }

    final sections = <_BookmarkSection>[
      _BookmarkSection(title: context.t.tr('Today', 'ថ្ងៃនេះ'), items: today),
      _BookmarkSection(
        title: context.t.tr('This Week', 'សប្តាហ៍នេះ'),
        items: thisWeek,
      ),
      _BookmarkSection(
        title: context.t.tr('This Month', 'ខែនេះ'),
        items: thisMonth,
      ),
      _BookmarkSection(title: context.t.tr('Earlier', 'មុននេះ'), items: earlier),
    ];

    return sections.where((section) => section.items.isNotEmpty).toList();
  }

  int _daysOld(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final date = DateTime(dateTime.year, dateTime.month, dateTime.day);
    final days = today.difference(date).inDays;
    return days < 0 ? 0 : days;
  }

  Widget _buildFilterChips(List<BookmarkItem> allBookmarks) {
    final assistantCount = allBookmarks
        .where((b) => b.role == 'assistant')
        .length;
    final userCount = allBookmarks.length - assistantCount;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          ChoiceChip(
            label: Text('${context.t.all} (${allBookmarks.length})'),
            selected: _roleFilter == _BookmarkRoleFilter.all,
            showCheckmark: false,
            onSelected: (_) {
              setState(() => _roleFilter = _BookmarkRoleFilter.all);
            },
          ),
          const SizedBox(width: 8),
          ChoiceChip(
            label: Text('${context.t.tr('AI', 'AI')} ($assistantCount)'),
            selected: _roleFilter == _BookmarkRoleFilter.assistant,
            showCheckmark: false,
            onSelected: (_) {
              setState(() => _roleFilter = _BookmarkRoleFilter.assistant);
            },
          ),
          const SizedBox(width: 8),
          ChoiceChip(
            label: Text('${context.t.tr('You', 'អ្នក')} ($userCount)'),
            selected: _roleFilter == _BookmarkRoleFilter.user,
            showCheckmark: false,
            onSelected: (_) {
              setState(() => _roleFilter = _BookmarkRoleFilter.user);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme, ColorScheme colorScheme) {
    final isFiltered = _hasActiveFilters;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer.withValues(alpha: 0.3),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.bookmark_outline_rounded,
              size: 64,
              color: colorScheme.primary,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            isFiltered
                ? context.t.tr('No matching bookmarks', 'មិនមានចំណាំត្រូវគ្នា')
                : context.t.tr('No bookmarks yet', 'មិនទាន់មានចំណាំ'),
            style: theme.textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            isFiltered
                ? context.t.tr(
                    'Try changing your search or filter',
                    'សូមសាកផ្លាស់ប្ដូរការស្វែងរក ឬតម្រង',
                  )
                : context.t.tr(
                    'Long-press messages in chat to bookmark them',
                    'ចុចសង្កត់លើសារនៅក្នុងជជែក ដើម្បីរក្សាទុកជា​ចំណាំ',
                  ),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  void _removeBookmarkWithUndo(BookmarkItem bookmark) {
    final bookmarksCubit = context.read<BookmarksCubit>();
    bookmarksCubit.removeBookmark(bookmark.id);

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(context.t.tr('Bookmark removed', 'បានដកចំណាំចេញ')),
          action: SnackBarAction(
            label: context.t.tr('Undo', 'មិនធ្វើ'),
            onPressed: () {
              bookmarksCubit.toggleBookmark(
                messageId: bookmark.id,
                content: bookmark.content,
                role: bookmark.role,
                conversationId: bookmark.conversationId,
                conversationTitle: bookmark.conversationTitle,
              );
            },
          ),
        ),
      );
  }
}

class _BookmarkSection {
  final String title;
  final List<BookmarkItem> items;

  const _BookmarkSection({required this.title, required this.items});
}

class _BookmarkCard extends StatelessWidget {
  final BookmarkItem bookmark;
  final VoidCallback onRemove;
  final VoidCallback onTap;

  const _BookmarkCard({
    required this.bookmark,
    required this.onRemove,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isAI = bookmark.role == 'assistant';
    final dateFormat = DateFormat('MMM d, yyyy - HH:mm');

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: colorScheme.surface.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.48),
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color:
                          (isAI ? colorScheme.primary : colorScheme.secondary)
                              .withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      isAI ? Icons.smart_toy_rounded : Icons.person_rounded,
                      color: isAI ? colorScheme.primary : colorScheme.secondary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isAI
                              ? context.t.tr('AI Response', 'ចម្លើយពី AI')
                              : context.t.tr('You', 'អ្នក'),
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (bookmark.conversationTitle != null)
                          Text(
                            bookmark.conversationTitle!,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.bookmark_remove_rounded,
                      color: colorScheme.error,
                    ),
                    onPressed: onRemove,
                    tooltip: context.t.tr('Remove bookmark', 'ដកចំណាំចេញ'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 150),
                child: SingleChildScrollView(
                  child: MarkdownBody(
                    data: bookmark.content,
                    selectable: true,
                    styleSheet: MarkdownStyleSheet(
                      p: theme.textTheme.bodyMedium,
                      code: theme.textTheme.bodySmall?.copyWith(
                        fontFamily: 'monospace',
                        backgroundColor: colorScheme.surfaceContainerHighest,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.access_time_rounded,
                    size: 14,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    dateFormat.format(bookmark.bookmarkedAt),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BookmarkSearchDelegate extends SearchDelegate<String> {
  final Function(String) onSearch;

  _BookmarkSearchDelegate({required this.onSearch});

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          query = '';
          onSearch('');
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        close(context, '');
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    onSearch(query);
    close(context, query);
    return const SizedBox.shrink();
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return Center(
      child: Text(
        context.t.tr('Type to search bookmarks', 'វាយអក្សរដើម្បីស្វែងរកចំណាំ'),
      ),
    );
  }
}
