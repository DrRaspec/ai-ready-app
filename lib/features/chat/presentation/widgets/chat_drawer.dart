import 'package:ai_chat_bot/features/chat/data/models/conversation.dart';
import 'package:ai_chat_bot/features/chat/data/models/chat_mode.dart';
import 'package:ai_chat_bot/features/chat/presentation/controllers/chat_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:ai_chat_bot/features/chat/presentation/controllers/folder_controller.dart';
import 'package:ai_chat_bot/features/chat/presentation/controllers/folder_state.dart';
import 'package:skeletonizer/skeletonizer.dart';

class ChatDrawer extends StatefulWidget {
  const ChatDrawer({super.key});

  @override
  State<ChatDrawer> createState() => _ChatDrawerState();
}

class _ChatDrawerState extends State<ChatDrawer> {
  late final ChatController _chatController;
  late final FolderController _folderController;

  @override
  void initState() {
    super.initState();
    _chatController = Get.find<ChatController>();
    _folderController = Get.find<FolderController>();

    // Lazy load conversations when the drawer is opened
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final state = _chatController.state;
      if (state.conversations.isEmpty && !state.isLoading) {
        _chatController.loadConversations();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Drawer(
      backgroundColor: theme.scaffoldBackgroundColor,
      child: SafeArea(
        child: Column(
          children: [
            // Header with Search and New Chat
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Search Bar
                  TextField(
                    decoration: InputDecoration(
                      hintText: 'Search',
                      prefixIcon: Icon(
                        Icons.search,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.edit_square),
                        onPressed: () {
                          // New Chat
                          _chatController.newConversation();
                          context.pop();
                        },
                        tooltip: 'New Chat',
                      ),
                      filled: true,
                      fillColor: colorScheme.surfaceContainerHighest.withValues(
                        alpha: 0.3,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      isDense: true,
                    ),
                    onChanged: (value) {
                      _chatController.searchConversations(value);
                    },
                  ),
                  const SizedBox(height: 16),

                  // Images Menu Item (like ChatGPT mobile app)
                  Obx(() {
                    final state = _chatController.state;
                    final isImageMode =
                        state.chatMode == ChatMode.imageGeneration;
                    return InkWell(
                      onTap: () {
                        _chatController.setChatMode(ChatMode.imageGeneration);
                        _chatController.newConversation();
                        context.pop();
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: isImageMode
                              ? colorScheme.primaryContainer.withValues(
                                  alpha: 0.4,
                                )
                              : colorScheme.surfaceContainerHighest.withValues(
                                  alpha: 0.3,
                                ),
                          borderRadius: BorderRadius.circular(12),
                          border: isImageMode
                              ? Border.all(color: colorScheme.primary)
                              : null,
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: colorScheme.primary.withValues(
                                  alpha: 0.15,
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.auto_awesome,
                                size: 20,
                                color: colorScheme.primary,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Images',
                              style: theme.textTheme.bodyLarge?.copyWith(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: 12),

                  // Prompt Library Item
                  InkWell(
                    onTap: () {
                      context.pop();
                      context.push('/prompts');
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest.withValues(
                          alpha: 0.3,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.amber.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.lightbulb_outline,
                              size: 20,
                              color: Colors.amber,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Prompt Library',
                            style: theme.textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  const SizedBox(height: 12),

                  // New Conversation Button
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () {
                        _chatController.newConversation();
                        context.pop();
                      },
                      icon: const Icon(Icons.add),
                      label: const Text('New Conversation'),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Folders List
            Obx(() {
              final folderState = _folderController.state;
              final chatState = _chatController.state;
              if (folderState is FolderLoaded) {
                return Container(
                  height: 40,
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: [
                      _buildFolderChip(
                        context,
                        null,
                        'All',
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
                          size: 18,
                        ),
                        onPressed: () => _showCreateFolderDialog(context),
                        constraints: const BoxConstraints.tightFor(
                          width: 40,
                          height: 40,
                        ),
                        style: IconButton.styleFrom(padding: EdgeInsets.zero),
                      ),
                    ],
                  ),
                );
              }
              return const SizedBox.shrink();
            }),

            const Divider(height: 1),

            // Recent Conversations List
            Expanded(
              child: Obx(() {
                final state = _chatController.state;
                final conversations = state.visibleConversations;

                if (state.isConversationsLoading &&
                    state.conversations.isEmpty) {
                  return Skeletonizer(
                    enabled: true,
                    child: ListView.builder(
                      itemCount: 5,
                      itemBuilder: (context, index) =>
                          const ListTile(title: Text('Loading...')),
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
                              ? 'No matching conversations'
                              : 'No conversations yet',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return Container(
                  decoration: BoxDecoration(
                    color: theme.scaffoldBackgroundColor,
                  ),
                  child: NotificationListener<ScrollNotification>(
                    onNotification: (scrollInfo) {
                      if (!state.isConversationsLoading &&
                          state.hasMoreConversations &&
                          !state
                              .isSearching && // Disable pagination when searching
                          scrollInfo.metrics.pixels >=
                              scrollInfo.metrics.maxScrollExtent * 0.8) {
                        _chatController.loadConversations(
                          page: state.conversationPage + 1,
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
                          dense: true,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 24,
                          ),
                          title: Text(
                            conversation.title ?? 'New Chat',
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
                          onTap: () {
                            // Reset search on select
                            _chatController.searchConversations('');
                            if (conversation.id !=
                                state.currentConversationId) {
                              _chatController.selectConversation(conversation.id);
                            }
                            context.pop();
                          },
                        );
                      },
                    ),
                  ),
                );
              }),
            ),

            const Divider(height: 1),

            // Footer (Profile)
            ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 8,
              ),
              leading: CircleAvatar(
                backgroundColor: colorScheme.primary,
                child: Text(
                  'AI',
                  style: TextStyle(color: colorScheme.onPrimary),
                ),
              ),
              title: const Text('My Profile'),
              subtitle: Text(
                'Basic Account',
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

  void _showOptionsSheet(BuildContext context, Conversation conversation) {
    showModalBottomSheet(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: const Text('Rename'),
              onTap: () {
                Navigator.pop(sheetContext);
                _showRenameDialog(context, conversation);
              },
            ),
            ListTile(
              leading: const Icon(Icons.drive_file_move_outlined),
              title: const Text('Move to Folder'),
              onTap: () {
                Navigator.pop(sheetContext);
                _showMoveToFolderDialog(context, conversation);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.red),
              title: const Text('Delete', style: TextStyle(color: Colors.red)),
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
        title: const Text('Delete Conversation'),
        content: Text(
          'Are you sure you want to delete "${conversation.title ?? "this conversation"}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final chatController = _chatController;
              chatController.deleteConversation(conversation.id);
              Navigator.pop(ctx);
            },
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            child: const Text('Delete'),
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
        title: const Text('Rename Conversation'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Conversation Title',
            hintText: 'Enter a new title',
          ),
          autofocus: true,
          textCapitalization: TextCapitalization.sentences,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                final chatController = _chatController;
                chatController.renameConversation(conversation.id, controller.text);
              }
              Navigator.pop(ctx);
            },
            child: const Text('Rename'),
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
            _chatController.selectFolder(id);
          },
          borderRadius: BorderRadius.circular(20),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected
                  ? colorScheme.primary
                  : colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(20),
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
              title: const Text('Rename Folder'),
              onTap: () {
                Navigator.pop(sheetContext);
                _showRenameFolderDialog(context, folderId, folderName);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.red),
              title: const Text(
                'Delete Folder',
                style: TextStyle(color: Colors.red),
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
        title: const Text('Rename Folder'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Folder Name',
            hintText: 'Enter new name',
          ),
          autofocus: true,
          textCapitalization: TextCapitalization.words,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                final folderController = _folderController;
                folderController.renameFolder(folderId, controller.text);
              }
              Navigator.pop(ctx);
            },
            child: const Text('Rename'),
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
        title: const Text('Delete Folder'),
        content: Text(
          'Are you sure you want to delete folder "$folderName"?\nConversations inside will be moved to "All".',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final folderController = _folderController;
              folderController.deleteFolder(folderId);
              // Also reset folder selection if needed.
              // _chatController.selectFolder(null); // Optional
              Navigator.pop(ctx);
            },
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            child: const Text('Delete'),
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
        title: const Text('New Folder'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Folder Name',
            hintText: 'e.g., Work, Personal',
          ),
          autofocus: true,
          textCapitalization: TextCapitalization.words,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                final folderController = _folderController;
                folderController.createFolder(
                  controller.text,
                  'blue',
                ); // Default color
              }
              Navigator.pop(ctx);
            },
            child: const Text('Create'),
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
        title: const Text('Move to Folder'),
        content: SizedBox(
          width: double.maxFinite,
          child: Obx(() {
            final state = _folderController.state;
            if (state is FolderLoaded) {
              return ListView(
                shrinkWrap: true,
                children: [
                  ListTile(
                    leading: const Icon(Icons.folder_off_outlined),
                    title: const Text('No Folder (Uncategorized)'),
                    onTap: () {
                      final chatController = _chatController;
                      chatController.moveToFolder(conversation.id, null);
                      Navigator.pop(ctx);
                    },
                  ),
                  const Divider(),
                  ...state.folders.map(
                    (folder) => ListTile(
                      leading: const Icon(Icons.folder_outlined),
                      title: Text(folder.name),
                      onTap: () {
                        final chatController = _chatController;
                        chatController.moveToFolder(conversation.id, folder.id);
                        Navigator.pop(ctx);
                      },
                    ),
                  ),
                ],
              );
            }
            return const Center(child: CircularProgressIndicator());
          }),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }
}
