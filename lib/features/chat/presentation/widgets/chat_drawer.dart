import 'package:ai_chat_bot/features/chat/data/models/conversation.dart';
import 'package:ai_chat_bot/features/chat/data/models/chat_mode.dart';
import 'package:ai_chat_bot/core/localization/app_text.dart';
import 'package:ai_chat_bot/features/chat/presentation/bloc/chat_bloc.dart';
import 'package:ai_chat_bot/features/chat/presentation/bloc/chat_event.dart';
import 'package:ai_chat_bot/features/chat/presentation/bloc/chat_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:ai_chat_bot/features/chat/presentation/bloc/folder_cubit.dart';
import 'package:ai_chat_bot/features/chat/presentation/bloc/folder_state.dart';
import 'package:skeletonizer/skeletonizer.dart';

class ChatDrawer extends StatefulWidget {
  const ChatDrawer({super.key});

  @override
  State<ChatDrawer> createState() => _ChatDrawerState();
}

class _ChatDrawerState extends State<ChatDrawer> {
  @override
  void initState() {
    super.initState();
    // Lazy load conversations when the drawer is opened
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final state = context.read<ChatBloc>().state;
      if (state.conversations.isEmpty && !state.isLoading) {
        context.read<ChatBloc>().add(const LoadConversations());
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final media = MediaQuery.of(context);
    final isCompactHeight = media.size.height < 500;
    final headerPadding = isCompactHeight ? 12.0 : 16.0;
    final sectionGap = isCompactHeight ? 8.0 : 12.0;

    return Drawer(
      backgroundColor: colorScheme.surface,
      child: SafeArea(
        child: Column(
          children: [
            // Header with Search and New Chat
            Container(
              padding: EdgeInsets.all(headerPadding),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                border: Border(
                  bottom: BorderSide(
                    color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                  ),
                ),
              ),
              child: Column(
                children: [
                  // Search Bar
                  TextField(
                    decoration: InputDecoration(
                      hintText: context.t.search,
                      prefixIcon: Icon(
                        Icons.search,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.edit_square),
                        onPressed: () async {
                          // New Chat
                          context.read<ChatBloc>().add(const NewConversation());
                          await _closeDrawerIfOpen();
                        },
                        tooltip: context.t.newChat,
                      ),
                      filled: true,
                      fillColor: colorScheme.surfaceContainerHighest.withValues(
                        alpha: 0.65,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(
                          color: colorScheme.outlineVariant.withValues(
                            alpha: 0.45,
                          ),
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      isDense: true,
                    ),
                    onChanged: (value) {
                      context.read<ChatBloc>().add(SearchConversations(value));
                    },
                  ),
                  SizedBox(height: isCompactHeight ? 10 : 16),

                  if (isCompactHeight)
                    Row(
                      children: [
                        Expanded(
                          child: BlocBuilder<ChatBloc, ChatState>(
                            builder: (context, state) {
                              final isImageMode =
                                  state.chatMode == ChatMode.imageGeneration;
                              return _buildQuickActionTile(
                                context,
                                icon: Icons.auto_awesome,
                                label: context.t.images,
                                compact: true,
                                isSelected: isImageMode,
                                accentColor: colorScheme.primary,
                                onTap: () async {
                                  context.read<ChatBloc>().add(
                                    const SetChatMode(ChatMode.imageGeneration),
                                  );
                                  context.read<ChatBloc>().add(
                                    const NewConversation(),
                                  );
                                  await _closeDrawerIfOpen();
                                },
                              );
                            },
                          ),
                        ),
                        SizedBox(width: sectionGap),
                        Expanded(
                          child: _buildQuickActionTile(
                            context,
                            icon: Icons.lightbulb_outline,
                            label: context.t.prompts,
                            compact: true,
                            accentColor: Colors.amber,
                            onTap: _openPromptLibrary,
                          ),
                        ),
                      ],
                    )
                  else ...[
                    BlocBuilder<ChatBloc, ChatState>(
                      builder: (context, state) {
                        final isImageMode =
                            state.chatMode == ChatMode.imageGeneration;
                        return _buildQuickActionTile(
                          context,
                          icon: Icons.auto_awesome,
                          label: context.t.images,
                          isSelected: isImageMode,
                          accentColor: colorScheme.primary,
                          onTap: () async {
                            context.read<ChatBloc>().add(
                              const SetChatMode(ChatMode.imageGeneration),
                            );
                            context.read<ChatBloc>().add(
                              const NewConversation(),
                            );
                            await _closeDrawerIfOpen();
                          },
                        );
                      },
                    ),
                    SizedBox(height: sectionGap),
                    _buildQuickActionTile(
                      context,
                      icon: Icons.lightbulb_outline,
                      label: context.t.promptLibrary,
                      accentColor: Colors.amber,
                      onTap: _openPromptLibrary,
                    ),
                  ],

                  SizedBox(height: sectionGap),

                  // New Conversation Button
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () async {
                        context.read<ChatBloc>().add(const NewConversation());
                        await _closeDrawerIfOpen();
                      },
                      icon: const Icon(Icons.add),
                      label: Text(context.t.newConversation),
                      style: FilledButton.styleFrom(
                        padding: EdgeInsets.symmetric(
                          vertical: isCompactHeight ? 12 : 16,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Folders List
            BlocBuilder<FolderCubit, FolderState>(
              builder: (context, folderState) {
                if (folderState is FolderLoaded) {
                  return BlocBuilder<ChatBloc, ChatState>(
                    buildWhen: (p, c) => p.currentFolderId != c.currentFolderId,
                    builder: (context, chatState) {
                      return Container(
                        height: isCompactHeight ? 36 : 40,
                        margin: EdgeInsets.only(
                          bottom: isCompactHeight ? 6 : 8,
                        ),
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          padding: EdgeInsets.symmetric(
                            horizontal: isCompactHeight ? 12 : 16,
                          ),
                          children: [
                            _buildFolderChip(
                              context,
                              null,
                              context.t.all,
                              chatState.currentFolderId == null,
                            ),
                            const SizedBox(width: 8),
                            ...folderState.folders.map((f) {
                              return Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: _buildFolderChip(
                                  context,
                                  f.id,
                                  f.name,
                                  chatState.currentFolderId == f.id,
                                  color: f.color,
                                  isFolder: true,
                                ),
                              );
                            }),
                            IconButton.filledTonal(
                              icon: const Icon(
                                Icons.create_new_folder_outlined,
                                size: 16,
                              ),
                              onPressed: () => _showCreateFolderDialog(context),
                              constraints: BoxConstraints.tightFor(
                                width: isCompactHeight ? 36 : 40,
                                height: isCompactHeight ? 36 : 40,
                              ),
                              style: IconButton.styleFrom(
                                padding: EdgeInsets.zero,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                }
                return const SizedBox.shrink();
              },
            ),

            const Divider(height: 1),

            // Recent Conversations List
            Expanded(
              child: BlocBuilder<ChatBloc, ChatState>(
                builder: (context, state) {
                  final conversations = state.visibleConversations;

                  if (state.isConversationsLoading &&
                      state.conversations.isEmpty) {
                    return Skeletonizer(
                      enabled: true,
                      child: ListView.builder(
                        itemCount: 5,
                        itemBuilder: (context, index) =>
                            ListTile(title: Text(context.t.loading)),
                      ),
                    );
                  }

                  if (conversations.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            state.isSearching
                                ? Icons.search_off
                                : Icons.chat_bubble_outline,
                            size: 48,
                            color: colorScheme.outline.withValues(alpha: 0.5),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            state.isSearching
                                ? context.t.noMatchingConversations
                                : context.t.noConversationsYet,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return Container(
                    decoration: BoxDecoration(color: colorScheme.surface),
                    child: NotificationListener<ScrollNotification>(
                      onNotification: (scrollInfo) {
                        if (!state.isConversationsLoading &&
                            state.hasMoreConversations &&
                            !state
                                .isSearching && // Disable pagination when searching
                            scrollInfo.metrics.pixels >=
                                scrollInfo.metrics.maxScrollExtent * 0.8) {
                          context.read<ChatBloc>().add(
                            LoadConversations(page: state.conversationPage + 1),
                          );
                        }
                        return false;
                      },
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount:
                            conversations.length +
                            (state.hasMoreConversations && !state.isSearching
                                ? 1
                                : 0),
                        itemBuilder: (context, index) {
                          if (index >= conversations.length) {
                            return Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Center(
                                child: SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: colorScheme.primary,
                                  ),
                                ),
                              ),
                            );
                          }

                          final conversation = conversations[index];
                          final isSelected =
                              conversation.id == state.currentConversationId;

                          return ListTile(
                            selected: isSelected,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            tileColor: isSelected
                                ? colorScheme.primaryContainer.withValues(
                                    alpha: 0.3,
                                  )
                                : Colors.transparent,
                            dense: true,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                            ),
                            title: Text(
                              conversation.title ?? context.t.newChat,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: isSelected
                                    ? colorScheme.primary
                                    : colorScheme.onSurface,
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                              ),
                            ),
                            trailing: IconButton(
                              icon: Icon(
                                Icons.more_horiz,
                                size: 20,
                                color: colorScheme.onSurfaceVariant,
                              ),
                              onPressed: () =>
                                  _showOptionsSheet(context, conversation),
                              visualDensity: VisualDensity.compact,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                            onLongPress: () =>
                                _showOptionsSheet(context, conversation),
                            onTap: () async {
                              // Reset search on select
                              context.read<ChatBloc>().add(
                                const SearchConversations(''),
                              );
                              if (conversation.id !=
                                  state.currentConversationId) {
                                context.read<ChatBloc>().add(
                                  SelectConversation(conversation.id),
                                );
                              }
                              await _closeDrawerIfOpen();
                            },
                          );
                        },
                      ),
                    ),
                  );
                },
              ),
            ),

            const Divider(height: 1),

            // Footer (Profile)
            ListTile(
              dense: isCompactHeight,
              contentPadding: EdgeInsets.symmetric(
                horizontal: isCompactHeight ? 12 : 16,
                vertical: isCompactHeight ? 2 : 8,
              ),
              leading: CircleAvatar(
                backgroundColor: colorScheme.primary,
                child: Text(
                  'AI',
                  style: TextStyle(color: colorScheme.onPrimary),
                ),
              ),
              title: Text(context.t.myProfile),
              subtitle: isCompactHeight
                  ? null
                  : Text(
                      context.t.basicAccount,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
              trailing: const Icon(Icons.settings_outlined),
              onTap: () {
                context.push('/profile');
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _closeDrawerIfOpen() async {
    final scaffold = Scaffold.maybeOf(context);
    final isDrawerOpen = scaffold?.isDrawerOpen ?? false;
    final isEndDrawerOpen = scaffold?.isEndDrawerOpen ?? false;
    if (!isDrawerOpen && !isEndDrawerOpen) return;

    final navigator = Navigator.maybeOf(context);
    if (navigator == null) return;
    await navigator.maybePop();
  }

  Future<void> _openPromptLibrary() async {
    final router = GoRouter.of(context);
    await _closeDrawerIfOpen();
    router.push('/prompts');
  }

  Widget _buildQuickActionTile(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool compact = false,
    bool isSelected = false,
    Color? accentColor,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final accent = accentColor ?? colorScheme.primary;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 10 : 16,
          vertical: compact ? 10 : 12,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? colorScheme.primaryContainer.withValues(alpha: 0.32)
              : colorScheme.surfaceContainerHighest.withValues(alpha: 0.58),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected
                ? colorScheme.primary.withValues(alpha: 0.5)
                : colorScheme.outlineVariant.withValues(alpha: 0.45),
          ),
        ),
        child: Row(
          mainAxisAlignment: compact
              ? MainAxisAlignment.center
              : MainAxisAlignment.start,
          children: [
            Container(
              padding: EdgeInsets.all(compact ? 6 : 8),
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: compact ? 16 : 20, color: accent),
            ),
            SizedBox(width: compact ? 8 : 12),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style:
                    (compact
                            ? theme.textTheme.bodyMedium
                            : theme.textTheme.bodyLarge)
                        ?.copyWith(fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showOptionsSheet(BuildContext context, Conversation conversation) {
    showModalBottomSheet(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: Text(context.t.rename),
              onTap: () {
                Navigator.pop(sheetContext);
                _showRenameDialog(context, conversation);
              },
            ),
            ListTile(
              leading: const Icon(Icons.drive_file_move_outlined),
              title: Text(context.t.moveToFolder),
              onTap: () {
                Navigator.pop(sheetContext);
                _showMoveToFolderDialog(context, conversation);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.red),
              title: Text(
                context.t.delete,
                style: const TextStyle(color: Colors.red),
              ),
              onTap: () {
                Navigator.pop(sheetContext);
                _showDeleteDialog(context, conversation);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, Conversation conversation) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.t.deleteConversation),
        content: Text(
          context.t.deleteConversationConfirm(
            conversation.title ?? context.t.thisConversation,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(context.t.cancel),
          ),
          FilledButton(
            onPressed: () {
              final chatBloc = context.read<ChatBloc>();
              chatBloc.add(DeleteConversation(conversation.id));
              Navigator.pop(ctx);
            },
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            child: Text(context.t.delete),
          ),
        ],
      ),
    );
  }

  void _showRenameDialog(BuildContext context, Conversation conversation) {
    final controller = TextEditingController(text: conversation.title);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.t.renameConversation),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            labelText: context.t.conversationTitle,
            hintText: context.t.enterNewTitle,
          ),
          autofocus: true,
          textCapitalization: TextCapitalization.sentences,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(context.t.cancel),
          ),
          FilledButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                final chatBloc = context.read<ChatBloc>();
                chatBloc.add(
                  RenameConversation(conversation.id, controller.text),
                );
              }
              Navigator.pop(ctx);
            },
            child: Text(context.t.rename),
          ),
        ],
      ),
    );
  }

  Widget _buildFolderChip(
    BuildContext context,
    String? id,
    String label,
    bool isSelected, {
    String? color,
    bool isFolder = false,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onLongPress: (id != null && isFolder)
              ? () => _showFolderOptions(context, id, label)
              : null,
          onTap: () {
            context.read<ChatBloc>().add(SelectFolder(id));
          },
          borderRadius: BorderRadius.circular(20),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected
                  ? colorScheme.primary
                  : colorScheme.surfaceContainerHighest.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected
                    ? colorScheme.primary
                    : colorScheme.outlineVariant.withValues(alpha: 0.5),
              ),
            ),
            child: Text(
              label,
              style: theme.textTheme.labelLarge?.copyWith(
                color: isSelected
                    ? colorScheme.onPrimary
                    : colorScheme.onSurface,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showFolderOptions(
    BuildContext context,
    String folderId,
    String folderName,
  ) {
    showModalBottomSheet(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                folderName,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: Text(context.t.renameFolder),
              onTap: () {
                Navigator.pop(sheetContext);
                _showRenameFolderDialog(context, folderId, folderName);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.red),
              title: Text(
                context.t.deleteFolder,
                style: const TextStyle(color: Colors.red),
              ),
              onTap: () {
                Navigator.pop(sheetContext);
                _showDeleteFolderDialog(context, folderId, folderName);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showRenameFolderDialog(
    BuildContext context,
    String folderId,
    String currentName,
  ) {
    final controller = TextEditingController(text: currentName);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.t.renameFolder),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            labelText: context.t.folderName,
            hintText: context.t.enterNewName,
          ),
          autofocus: true,
          textCapitalization: TextCapitalization.words,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(context.t.cancel),
          ),
          FilledButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                final folderCubit = context.read<FolderCubit>();
                folderCubit.renameFolder(folderId, controller.text);
              }
              Navigator.pop(ctx);
            },
            child: Text(context.t.rename),
          ),
        ],
      ),
    );
  }

  void _showDeleteFolderDialog(
    BuildContext context,
    String folderId,
    String folderName,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.t.deleteFolder),
        content: Text(
          context.t.deleteFolderConfirm(folderName),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(context.t.cancel),
          ),
          FilledButton(
            onPressed: () {
              final folderCubit = context.read<FolderCubit>();
              folderCubit.deleteFolder(folderId);
              // Also update chat bloc to reset folder selection if needed
              // context.read<ChatBloc>().add(const SelectFolder(null)); // Optional: reset selection
              Navigator.pop(ctx);
            },
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            child: Text(context.t.delete),
          ),
        ],
      ),
    );
  }

  void _showCreateFolderDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.t.newFolder),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            labelText: context.t.folderName,
            hintText: context.t.folderNameExamples,
          ),
          autofocus: true,
          textCapitalization: TextCapitalization.words,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(context.t.cancel),
          ),
          FilledButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                final folderCubit = context.read<FolderCubit>();
                folderCubit.createFolder(controller.text);
              }
              Navigator.pop(ctx);
            },
            child: Text(context.t.create),
          ),
        ],
      ),
    );
  }

  void _showMoveToFolderDialog(
    BuildContext context,
    Conversation conversation,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.t.moveToFolder),
        content: SizedBox(
          width: double.maxFinite,
          child: BlocBuilder<FolderCubit, FolderState>(
            builder: (context, state) {
              if (state is FolderLoaded) {
                return ListView(
                  shrinkWrap: true,
                  children: [
                    ListTile(
                      leading: const Icon(Icons.folder_off_outlined),
                      title: Text(context.t.noFolderUncategorized),
                      onTap: () {
                        final chatBloc = context.read<ChatBloc>();
                        chatBloc.add(MoveToFolder(conversation.id, null));
                        Navigator.pop(ctx);
                      },
                    ),
                    const Divider(),
                    ...state.folders.map(
                      (folder) => ListTile(
                        leading: const Icon(Icons.folder_outlined),
                        title: Text(folder.name),
                        onTap: () {
                          final chatBloc = context.read<ChatBloc>();
                          chatBloc.add(
                            MoveToFolder(conversation.id, folder.id),
                          );
                          Navigator.pop(ctx);
                        },
                      ),
                    ),
                  ],
                );
              }
              return const Center(child: CircularProgressIndicator());
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(context.t.cancel),
          ),
        ],
      ),
    );
  }
}
