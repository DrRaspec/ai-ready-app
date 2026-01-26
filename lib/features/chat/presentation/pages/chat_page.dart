import 'package:ai_chat_bot/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:ai_chat_bot/features/chat/presentation/bloc/chat_bloc.dart';
import 'package:ai_chat_bot/features/chat/presentation/bloc/chat_event.dart';
import 'package:ai_chat_bot/features/chat/presentation/bloc/chat_state.dart';
import 'package:ai_chat_bot/features/chat/data/models/message.dart';
import 'package:go_router/go_router.dart';
import 'dart:io';
import 'package:ai_chat_bot/features/chat/presentation/widgets/media_sheet.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:ai_chat_bot/core/routers/route_names.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  String? _selectedModel;

  // Voice Recording
  bool _isRecording = false;
  final Record _audioRecorder = Record();

  final List<String> _availableModels = [
    'llama-3.3-70b-versatile',
    'llama-3.1-8b-instant',
    'mixtral-8x7b-32768',
    'gemma2-9b-it',
  ];

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _audioRecorder.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final message = _messageController.text.trim();
    if (message.isEmpty &&
        context.read<ChatBloc>().state.attachedImagePath == null)
      return;

    final state = context.read<ChatBloc>().state;

    context.read<ChatBloc>().add(
      SendMessage(
        message: message.isEmpty ? 'Image Analysis' : message,
        conversationId: state.currentConversationId,
        model: _selectedModel,
      ),
    );

    _messageController.clear();
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0.0, // Scroll to bottom (start of reversed list)
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _showMediaSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.45,
        minChildSize: 0.3,
        maxChildSize: 0.8,
        builder: (context, scrollController) =>
            MediaSheet(scrollController: scrollController),
      ),
    );
  }

  // Voice Recording Logic would go here (requires StatefulWidget mixin or controller)
  // For simplicity, we just mock the UI toggle for now, or implement fully if package is ready.
  // Since 'record' package logic is a bit involved for a single replace, we'll keep it simple:
  // Tap mic -> Start, Tap again -> Stop & Send.
  Future<void> _handleVoiceRecord() async {
    try {
      if (_isRecording) {
        // Stop recording
        final path = await _audioRecorder.stop();
        setState(() => _isRecording = false);

        if (path != null) {
          if (mounted) {
            context.read<ChatBloc>().add(VoiceMessageSent(path));
          }
        }
      } else {
        // Start recording
        if (await _audioRecorder.hasPermission()) {
          final tempDir = await getTemporaryDirectory();
          final path =
              '${tempDir.path}/audio_${DateTime.now().millisecondsSinceEpoch}.m4a';

          await _audioRecorder.start(path: path);
          setState(() => _isRecording = true);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error recording: $e')));
        setState(() => _isRecording = false);
      }
    }
  }

  void _showModelSelector() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final theme = Theme.of(context);
        return Container(
          decoration: BoxDecoration(
            color: theme.scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: Colors.grey.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.psychology, color: theme.colorScheme.primary),
                      const SizedBox(width: 12),
                      Text(
                        'Select AI Model',
                        style: theme.textTheme.titleLarge,
                      ),
                    ],
                  ),
                ),
                const Divider(),
                ..._availableModels.map((model) {
                  final isSelected =
                      _selectedModel == model ||
                      (_selectedModel == null &&
                          model ==
                              'llama-3.3-70b-versatile'); // default fallback logic check
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 8,
                    ),
                    onTap: () {
                      setState(() => _selectedModel = model);
                      Navigator.pop(context);
                    },
                    leading: CircleAvatar(
                      backgroundColor: isSelected
                          ? theme.colorScheme.primaryContainer
                          : theme.colorScheme.surfaceContainerHighest,
                      child: Icon(
                        Icons.smart_toy_rounded,
                        color: isSelected
                            ? theme.colorScheme.primary
                            : theme.colorScheme.onSurfaceVariant,
                        size: 20,
                      ),
                    ),
                    title: Text(
                      model,
                      style: TextStyle(
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.normal,
                        color: isSelected
                            ? theme.colorScheme.primary
                            : theme.colorScheme.onSurface,
                      ),
                    ),
                    subtitle: Text(
                      _getModelDescription(model),
                      style: theme.textTheme.bodySmall,
                    ),
                    trailing: isSelected
                        ? Icon(
                            Icons.check_circle_rounded,
                            color: theme.colorScheme.primary,
                          )
                        : null,
                  );
                }),
                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }

  String _getModelDescription(String model) {
    if (model.contains('llama')) return 'Fast & Versatile (Recommended)';
    if (model.contains('mixtral')) return 'High intelligence for complex tasks';
    if (model.contains('gemma')) return 'Lightweight & Efficient';
    return 'Standard AI Model';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: BlocBuilder<ChatBloc, ChatState>(
          builder: (context, state) {
            return Column(
              children: [
                Text(
                  state.currentConversation?.title ?? 'New Chat',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  state.chatMode?.label ??
                      (_selectedModel ?? 'General Assistant'),
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontSize: 10,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            );
          },
        ),
        centerTitle: true,
        backgroundColor: theme.scaffoldBackgroundColor.withValues(alpha: 0.9),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune_rounded),
            tooltip: 'Select Model',
            onPressed: _showModelSelector,
          ),
          IconButton(
            icon: const Icon(Icons.person_outline_rounded),
            onPressed: () => context.pushNamed(RouteNames.profile),
          ),
        ],
      ),
      body: Column(
        children: [
          // Messages list
          Expanded(
            child: BlocConsumer<ChatBloc, ChatState>(
              listener: (context, state) {
                // Scroll on new message or when generating completes
                if (!state.isSending || state.messages.isNotEmpty) {
                  // Small delay to let the list build
                  Future.delayed(
                    const Duration(milliseconds: 100),
                    _scrollToBottom,
                  );
                }
              },
              builder: (context, state) {
                if (state.isLoading && state.messages.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (state.messages.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Mode Icon
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primaryContainer
                                .withValues(alpha: 0.3),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            // _getIconData(state.chatMode?.iconName) // Would need helper
                            Icons.auto_awesome,
                            size: 48,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          state.chatMode?.label ?? 'How can I help you today?',
                          style: theme.textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          state.chatMode?.systemPrompt ?? 'Ask me anything...',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  controller: _scrollController,
                  reverse: true,
                  padding: EdgeInsets.fromLTRB(
                    16,
                    MediaQuery.of(context).padding.top + kToolbarHeight + 20,
                    16,
                    20,
                  ), // Dynamic top padding for AppBar + Status Bar
                  itemCount: state.messages.length,
                  itemBuilder: (context, index) {
                    // Reversed index to show newest at bottom
                    final message =
                        state.messages[state.messages.length - 1 - index];
                    return _MessageBubble(message: message);
                  },
                );
              },
            ),
          ),

          // Error message
          BlocBuilder<ChatBloc, ChatState>(
            builder: (context, state) {
              if (state.errorMessage != null) {
                return Container(
                  width: double.infinity,
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.errorContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    state.errorMessage!,
                    style: TextStyle(color: theme.colorScheme.onErrorContainer),
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),

          // Attached Image Preview
          BlocBuilder<ChatBloc, ChatState>(
            buildWhen: (p, c) => p.attachedImagePath != c.attachedImagePath,
            builder: (context, state) {
              if (state.attachedImagePath == null)
                return const SizedBox.shrink();

              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(
                        File(state.attachedImagePath!),
                        width: 60,
                        height: 60,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () =>
                          context.read<ChatBloc>().add(const DetachImage()),
                    ),
                  ],
                ),
              );
            },
          ),

          // Input area
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Attachment Button
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline_rounded),
                    iconSize: 28,
                    color: theme.colorScheme.onSurfaceVariant,
                    onPressed: _showMediaSheet,
                  ),
                  const SizedBox(width: 8),

                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest
                            .withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: TextField(
                        controller: _messageController,
                        decoration: const InputDecoration(
                          hintText: 'Message...',
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                          isDense: true,
                        ),
                        minLines: 1,
                        maxLines: 5,
                        textInputAction: TextInputAction.newline,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Mic or Send Button
                  BlocBuilder<ChatBloc, ChatState>(
                    builder: (context, state) {
                      return ListenableBuilder(
                        listenable: _messageController,
                        builder: (context, _) {
                          final isTextEmpty = _messageController.text
                              .trim()
                              .isEmpty;
                          final hasAttachment = state.attachedImagePath != null;
                          final canSend = !isTextEmpty || hasAttachment;

                          return IconButton.filled(
                            onPressed: state.isSending
                                ? null
                                : (canSend ? _sendMessage : _handleVoiceRecord),
                            style: IconButton.styleFrom(
                              backgroundColor: _isRecording
                                  ? Colors.red
                                  : theme.colorScheme.primary,
                              foregroundColor: Colors.white,
                              fixedSize: const Size(48, 48),
                            ),
                            icon: state.isSending
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : Icon(
                                    _isRecording
                                        ? Icons.stop_rounded
                                        : (canSend
                                              ? Icons.arrow_upward_rounded
                                              : Icons.mic_rounded),
                                  ),
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final Message message;

  const _MessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final bubbleColor = isUser
        ? (isDark ? AppColors.darkBubbleUser : AppColors.lightBubbleUser)
        : (isDark ? AppColors.darkBubbleAI : AppColors.lightBubbleAI);

    final textColor = isUser
        ? (isDark
              ? AppColors.darkBubbleUserText
              : AppColors.lightBubbleUserText)
        : (isDark ? AppColors.darkBubbleAIText : AppColors.lightBubbleAIText);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: isUser
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: isUser
                ? MainAxisAlignment.end
                : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (!isUser) ...[
                CircleAvatar(
                  radius: 16,
                  backgroundColor: theme.colorScheme.primaryContainer,
                  child: Icon(
                    Icons.auto_awesome,
                    size: 16,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 8),
              ],

              Flexible(
                child: GestureDetector(
                  onLongPress: isUser
                      ? () => _showMessageOptions(context, message)
                      : null,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: bubbleColor,
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(20),
                        topRight: const Radius.circular(20),
                        bottomLeft: Radius.circular(isUser ? 20 : 4),
                        bottomRight: Radius.circular(isUser ? 4 : 20),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        MarkdownBody(
                          data: message.content,
                          styleSheet: MarkdownStyleSheet(
                            p: theme.textTheme.bodyLarge?.copyWith(
                              color: textColor,
                              height: 1.5,
                            ),
                            strong: theme.textTheme.bodyLarge?.copyWith(
                              color: textColor,
                              fontWeight: FontWeight.bold,
                              height: 1.5,
                            ),
                            // Ensure other elements respect the bubble text color
                            h1: theme.textTheme.headlineSmall?.copyWith(
                              color: textColor,
                            ),
                            h2: theme.textTheme.titleLarge?.copyWith(
                              color: textColor,
                            ),
                            h3: theme.textTheme.titleMedium?.copyWith(
                              color: textColor,
                            ),
                            listBullet: TextStyle(color: textColor),
                            code: theme.textTheme.bodyMedium?.copyWith(
                              color: isDark
                                  ? Colors.grey[200]
                                  : Colors.grey[800],
                              backgroundColor: isDark
                                  ? Colors.grey[800]
                                  : Colors.grey[200],
                              fontFamily: 'monospace',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (message.createdAt != null)
            Padding(
              padding: EdgeInsets.only(
                top: 6,
                left: isUser ? 0 : 40,
                right: isUser ? 0 : 0,
              ),
              child: Text(
                _formatTime(message.createdAt!),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.outline,
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  void _showMessageOptions(BuildContext context, Message message) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Edit Message'),
              onTap: () {
                Navigator.pop(context); // Close sheet
                _showEditDialog(context, message);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showEditDialog(BuildContext context, Message message) {
    final controller = TextEditingController(text: message.content);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Message'),
        content: TextField(
          controller: controller,
          maxLines: 5,
          minLines: 1,
          decoration: const InputDecoration(border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                context.read<ChatBloc>().add(
                  EditMessage(message.id, controller.text.trim()),
                );
                Navigator.pop(context);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
