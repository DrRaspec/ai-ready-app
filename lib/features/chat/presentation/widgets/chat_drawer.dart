import 'package:ai_chat_bot/features/chat/data/models/conversation.dart';
import 'package:ai_chat_bot/features/chat/data/models/chat_mode.dart';
import 'package:ai_chat_bot/features/chat/presentation/bloc/chat_bloc.dart';
import 'package:ai_chat_bot/features/chat/presentation/bloc/chat_event.dart';
import 'package:ai_chat_bot/features/chat/presentation/bloc/chat_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
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
                          context.read<ChatBloc>().add(const NewConversation());
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
                    onTap: () {
                      // TODO: Implement search functionality
                    },
                  ),
                  const SizedBox(height: 16),

                  // Images Menu Item (like ChatGPT mobile app)
                  BlocBuilder<ChatBloc, ChatState>(
                    builder: (context, state) {
                      final isImageMode =
                          state.chatMode == ChatMode.imageGeneration;
                      return InkWell(
                        onTap: () {
                          context.read<ChatBloc>().add(
                            const SetChatMode(ChatMode.imageGeneration),
                          );
                          context.read<ChatBloc>().add(const NewConversation());
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
                                : colorScheme.surfaceContainerHighest
                                      .withValues(alpha: 0.3),
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
                    },
                  ),
                  const SizedBox(height: 12),

                  // New Conversation Button
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () {
                        context.read<ChatBloc>().add(const NewConversation());
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

            const Divider(height: 1),

            // Recent Conversations List
            Expanded(
              child: BlocBuilder<ChatBloc, ChatState>(
                builder: (context, state) {
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

                  if (state.conversations.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.chat_bubble_outline,
                            size: 48,
                            color: colorScheme.outline.withValues(alpha: 0.5),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No conversations yet',
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
                            state.conversations.length +
                            (state.hasMoreConversations ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index >= state.conversations.length) {
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

                          final conversation = state.conversations[index];
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
                              if (conversation.id !=
                                  state.currentConversationId) {
                                context.read<ChatBloc>().add(
                                  SelectConversation(conversation.id),
                                );
                              }
                              context.pop();
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
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: const Text('Rename'),
              onTap: () {
                Navigator.pop(context);
                _showRenameDialog(context, conversation);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.red),
              title: const Text('Delete', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
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
              context.read<ChatBloc>().add(DeleteConversation(conversation.id));
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
                context.read<ChatBloc>().add(
                  RenameConversation(conversation.id, controller.text),
                );
              }
              Navigator.pop(ctx);
            },
            child: const Text('Rename'),
          ),
        ],
      ),
    );
  }
}
