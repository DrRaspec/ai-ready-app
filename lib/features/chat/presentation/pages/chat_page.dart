import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/services.dart';
import 'package:gal/gal.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:ai_chat_bot/features/chat/presentation/bloc/chat_bloc.dart';
import 'package:ai_chat_bot/features/chat/presentation/bloc/chat_event.dart';
import 'package:ai_chat_bot/features/chat/presentation/bloc/chat_state.dart';
import 'package:ai_chat_bot/features/chat/data/models/message.dart';
import 'package:ai_chat_bot/core/theme/theme_cubit.dart';
import 'package:ai_chat_bot/core/theme/theme_state.dart';
import 'dart:async';
import 'dart:io';
import 'dart:ui';
import 'dart:math' as math; // Added for TypingIndicator
import 'package:pasteboard/pasteboard.dart';
import 'package:path_provider/path_provider.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_highlighter/themes/github.dart';
import 'package:flutter_highlighter/themes/dracula.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:go_router/go_router.dart';
import 'package:ai_chat_bot/features/chat/presentation/widgets/media_sheet.dart';
import 'package:ai_chat_bot/core/routers/route_names.dart';
import 'package:ai_chat_bot/features/chat/presentation/widgets/chat_drawer.dart';
import 'package:ai_chat_bot/core/theme/app_colors.dart';
import 'package:ai_chat_bot/features/chat/data/models/conversation.dart';
import 'package:ai_chat_bot/features/bookmarks/presentation/bloc/bookmarks_cubit.dart';
import 'package:ai_chat_bot/features/bookmarks/presentation/bloc/bookmarks_state.dart';
import 'package:flutter_highlighter/flutter_highlighter.dart';

class ChatPage extends StatefulWidget {
  final String? conversationId;
  final String? scrollToMessageId;
  const ChatPage({super.key, this.conversationId, this.scrollToMessageId});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  String? _selectedModel;

  // Voice Recording
  bool _isListening = false;
  final SpeechToText _speechToText = SpeechToText();
  bool _speechEnabled = false;

  // TTS
  final FlutterTts _flutterTts = FlutterTts();
  String? _currentlySpeakingMessageId;
  bool _hasScrolledToBookmark = false;

  @override
  void initState() {
    super.initState();

    print("ChatPage initialized with ID: ${widget.conversationId}");
    if (widget.conversationId != null) {
      context.read<ChatBloc>().add(SelectConversation(widget.conversationId!));
    }
    _initSpeech();
    _initTts();
  }

  Future<void> _initTts() async {
    await _flutterTts.setLanguage("en-US");
    await _flutterTts.setSpeechRate(0.5);
    await _flutterTts.setVolume(1.0);
    await _flutterTts.setPitch(1.0);

    _flutterTts.setCompletionHandler(() {
      if (mounted) {
        setState(() {
          _currentlySpeakingMessageId = null;
        });
      }
    });

    _flutterTts.setErrorHandler((msg) {
      if (mounted) {
        setState(() {
          _currentlySpeakingMessageId = null;
        });
      }
    });
  }

  Future<void> _speak(Message message) async {
    if (_currentlySpeakingMessageId == message.id) {
      await _flutterTts.stop();
      setState(() {
        _currentlySpeakingMessageId = null;
      });
    } else {
      if (_currentlySpeakingMessageId != null) {
        await _flutterTts.stop();
      }
      setState(() {
        _currentlySpeakingMessageId = message.id;
      });
      await _flutterTts.speak(message.content);
    }
  }

  Future<bool> _requestMicrophonePermission() async {
    final status = await Permission.microphone.status;
    if (status.isGranted) return true;

    final result = await Permission.microphone.request();
    if (result.isGranted) return true;

    if (mounted) {
      if (result.isPermanentlyDenied) {
        _showPermissionDialog();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Microphone permission required for voice'),
          ),
        );
      }
    }
    return false;
  }

  void _showPermissionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Permission Required'),
        content: const Text(
          'Microphone access is needed for voice features. Please enable it in settings.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              openAppSettings();
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  Future<void> _initSpeech() async {
    try {
      final hasPermission = await _requestMicrophonePermission();
      if (!hasPermission) return;

      // Small delay to ensure OS propagation
      await Future.delayed(const Duration(milliseconds: 500));

      _speechEnabled = await _speechToText.initialize(
        debugLogging: true,
        onError: (e) {
          debugPrint('STT Error: $e');
          if (mounted) {
            setState(() {
              _isListening = false;
              if (e.permanent) _speechEnabled = false;
            });

            // Reduce spam during init
            if (_isListening) {
              String errorMessage = 'Error: ${e.errorMsg}';
              if (e.errorMsg == 'error_listen_failed') {
                errorMessage =
                    'Microphone unavailable. Are you on a simulator?';
              } else if (e.errorMsg == 'error_no_match') {
                errorMessage = 'No speech detected. Please try again.';
              }

              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text(errorMessage)));
            }
          }
        },
        onStatus: (status) {
          debugPrint('STT Status: $status');
          if (status == 'notListening' && mounted) {
            if (_isListening) {
              debugPrint('STT: Ended without result');
            }
            setState(() => _isListening = false);
          }
        },
      );

      if (_speechEnabled) {
        var locales = await _speechToText.locales();
        debugPrint('STT Locales: ${locales.map((e) => e.localeId).join(', ')}');
      }

      if (mounted) setState(() {});
    } catch (e) {
      debugPrint('STT Init Exception: $e');
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();

    _speechToText.cancel();
    _flutterTts.stop();
    super.dispose();
  }

  void _sendMessage() {
    final message = _messageController.text.trim();
    if (message.isEmpty &&
        context.read<ChatBloc>().state.attachedImagePath == null) {
      return;
    }

    final state = context.read<ChatBloc>().state;

    context.read<ChatBloc>().add(
      SendMessage(
        message: message.isEmpty ? 'Image Analysis' : message,
        conversationId: state.currentConversationId,
        model: _selectedModel,
      ),
    );
    HapticFeedback.lightImpact();

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

  IconData _getIconData(String? name) {
    switch (name) {
      case 'auto_awesome':
        return Icons.auto_awesome;
      case 'code':
        return Icons.code;
      case 'edit_note':
        return Icons.edit_note;
      case 'short_text':
        return Icons.short_text;
      case 'image':
        return Icons.image;
      default:
        return Icons.chat_bubble_outline;
    }
  }

  void _showMediaSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.45,
        minChildSize: 0.3,
        maxChildSize: 0.8,
        snap: true,
        expand: false,
        builder: (context, scrollController) =>
            MediaSheet(scrollController: scrollController),
      ),
    );
  }

  Future<void> _handleVoiceRecord() async {
    if (_isListening) {
      await _speechToText.stop();
      setState(() => _isListening = false);
    } else {
      if (!_speechEnabled) {
        await _initSpeech(); // Await initialization
        if (!mounted) return;
        if (!_speechEnabled) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Speech recognition not available. Check permissions.',
              ),
            ),
          );
          return;
        }
      }

      setState(() {
        _isListening = true;
      });

      // Capture current text so we append to it
      final originalText = _messageController.text;
      // If there is existing text, add a space if not present
      final prefix = originalText.isNotEmpty && !originalText.endsWith(' ')
          ? '$originalText '
          : originalText;

      try {
        await _speechToText.listen(
          onResult: (result) {
            debugPrint('STT Result: ${result.recognizedWords}');
            setState(() {
              _messageController.text = '$prefix${result.recognizedWords}';
              _messageController.selection = TextSelection.fromPosition(
                TextPosition(offset: _messageController.text.length),
              );
            });
          },
          listenOptions: SpeechListenOptions(
            listenMode: ListenMode.dictation,
            partialResults: true,
            cancelOnError: false, // Critical for iOS stability
          ),
          listenFor: const Duration(seconds: 30),
          pauseFor: const Duration(seconds: 5),
          localeId: 'en_US',
        );
      } catch (e) {
        debugPrint('STT Listen Exception: $e');
        setState(() => _isListening = false);
      }
    }
  }

  Future<void> _handlePaste() async {
    final bytes = await Pasteboard.image;
    if (bytes != null) {
      final tempDir = await getTemporaryDirectory();
      final file = File(
        '${tempDir.path}/pasted_image_${DateTime.now().millisecondsSinceEpoch}.png',
      );
      await file.writeAsBytes(bytes);

      if (mounted) {
        context.read<ChatBloc>().add(AttachImage(file.path));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Image pasted from clipboard')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.keyV, meta: true):
            _handlePaste,
        const SingleActivator(LogicalKeyboardKey.keyV, control: true):
            _handlePaste,
      },
      child: GestureDetector(
        onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
        child: Scaffold(
          drawer: const ChatDrawer(),
          extendBodyBehindAppBar: true,
          appBar: AppBar(
            leading: Builder(
              builder: (context) => IconButton(
                icon: const Icon(Icons.menu_rounded),
                onPressed: () => Scaffold.of(context).openDrawer(),
              ),
            ),
            title: BlocBuilder<ChatBloc, ChatState>(
              builder: (context, state) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'AI Chat',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (state.currentConversationId != null)
                      Text(
                        _selectedModel ?? 'Select Model',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                  ],
                );
              },
            ),
            centerTitle: true,
            backgroundColor: Colors.transparent,
            flexibleSpace: ClipRRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  color: theme.scaffoldBackgroundColor.withValues(alpha: 0.8),
                ),
              ),
            ),
            actions: [
              IconButton(
                icon: BlocBuilder<ThemeCubit, ThemeState>(
                  builder: (context, state) {
                    return Icon(
                      state.mode == ThemeMode.light
                          ? Icons.dark_mode_rounded
                          : Icons.light_mode_rounded,
                    );
                  },
                ),
                onPressed: () => context.read<ThemeCubit>().toggleTheme(),
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
                    // Handle scrolling to specific message (Bookmark)
                    if (widget.scrollToMessageId != null &&
                        !_hasScrolledToBookmark &&
                        !state.isLoading &&
                        state.messages.isNotEmpty) {
                      final index = state.messages.indexWhere(
                        (m) => m.id == widget.scrollToMessageId,
                      );

                      if (index != -1) {
                        _hasScrolledToBookmark = true;
                        // Calculate list index (reversed list)
                        // state.messages[length - 1 - listIndex] = message
                        // listIndex = length - 1 - messageIndex
                        final listIndex = state.messages.length - 1 - index;

                        // Heuristic scroll: average item height ~150px
                        // Small delay to allow build
                        Future.delayed(const Duration(milliseconds: 300), () {
                          if (_scrollController.hasClients) {
                            _scrollController.animateTo(
                              listIndex * 150.0,
                              duration: const Duration(milliseconds: 600),
                              curve: Curves.easeOut,
                            );
                          }
                        });
                      }
                    }

                    // Scroll on new message or when generating completes
                    if (!state.isSending || state.messages.isNotEmpty) {
                      if (widget.scrollToMessageId == null) {
                        // Only auto-scroll to bottom if NOT trying to view a bookmark
                        // Small delay to let the list build
                        Future.delayed(
                          const Duration(milliseconds: 100),
                          _scrollToBottom,
                        );
                      }
                    }
                  },
                  builder: (context, state) {
                    if (state.messages.isEmpty && state.isLoading) {
                      // Fake data for skeleton loading
                      final fakeMessages = List.generate(
                        4,
                        (index) =>
                            Message.assistantLocal(
                              'This is a long fake message for loading skeleton effect. ' *
                                  (index + 1),
                            ).copyWith(
                              role: index.isEven ? 'user' : 'assistant',
                              id: 'fake_$index',
                            ),
                      );

                      return Skeletonizer(
                        enabled: true,
                        child: ListView.builder(
                          reverse: true,
                          padding: EdgeInsets.fromLTRB(
                            16,
                            MediaQuery.of(context).padding.top +
                                kToolbarHeight +
                                20,
                            16,
                            20,
                          ),
                          itemCount: fakeMessages.length,
                          itemBuilder: (context, index) {
                            final message = fakeMessages[index];
                            return _MessageBubble(
                              message: message,
                              isSpeaking: false,
                              onSpeak: () {},
                            );
                          },
                        ),
                      );
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
                                _getIconData(state.chatMode?.iconName),
                                size: 48,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              state.chatMode?.label ??
                                  'How can I help you today?',
                              style: theme.textTheme.titleLarge,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              state.chatMode?.systemPrompt ??
                                  'Ask me anything...',
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
                        MediaQuery.of(context).padding.top +
                            kToolbarHeight +
                            20,
                        16,
                        20,
                      ), // Dynamic top padding for AppBar + Status Bar
                      itemCount:
                          state.messages.length + (state.isSending ? 1 : 0),
                      itemBuilder: (context, index) {
                        // Handle Typing Indicator
                        if (state.isSending && index == 0) {
                          return const Padding(
                            padding: EdgeInsets.only(bottom: 12),
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: _TypingIndicator(),
                            ),
                          );
                        }

                        // Adjust index if typing indicator is present
                        final adjustedIndex = state.isSending
                            ? index - 1
                            : index;
                        final message =
                            state.messages[state.messages.length -
                                1 -
                                adjustedIndex];

                        // Check if this is the last message in the full list
                        final isLastMessage = adjustedIndex == 0;
                        return _MessageBubble(
                          key: ValueKey(message.id),
                          message: message,
                          isSpeaking: _currentlySpeakingMessageId == message.id,
                          onSpeak: () => _speak(message),
                          shouldAnimate:
                              message.id == state.lastAnimatedMessageId,
                          isLastMessage: isLastMessage,
                        );
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
                        style: TextStyle(
                          color: theme.colorScheme.onErrorContainer,
                        ),
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
                  if (state.attachedImagePath == null) {
                    return const SizedBox.shrink();
                  }

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
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface.withValues(alpha: 0.8),
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
                            onPressed: () {
                              HapticFeedback.lightImpact();
                              _showMediaSheet();
                            },
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
                                  final hasAttachment =
                                      state.attachedImagePath != null;
                                  final canSend = !isTextEmpty || hasAttachment;

                                  return IconButton.filled(
                                    onPressed: state.isSending
                                        ? null
                                        : (canSend
                                              ? _sendMessage
                                              : _handleVoiceRecord),
                                    style: IconButton.styleFrom(
                                      backgroundColor: _isListening
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
                                            _isListening
                                                ? Icons.stop_rounded
                                                : (canSend
                                                      ? Icons
                                                            .arrow_upward_rounded
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
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CodeElementBuilder extends MarkdownElementBuilder {
  final bool isDark;

  CodeElementBuilder({required this.isDark});

  @override
  Widget? visitElementAfter(md.Element element, TextStyle? preferredStyle) {
    var language = '';
    if (element.attributes['class'] != null) {
      String lg = element.attributes['class'] as String;
      language = lg.substring(9);
    }

    // Simple text content extraction
    final text = element.textContent;

    // Format language for display
    final displayLanguage = language.isEmpty ? 'code' : language.toLowerCase();

    // Provide syntax highlighting with copy header
    return _CodeBlockWithCopy(
      code: text,
      language: language,
      displayLanguage: displayLanguage,
      isDark: isDark,
    );
  }
}

class _CodeBlockWithCopy extends StatefulWidget {
  final String code;
  final String language;
  final String displayLanguage;
  final bool isDark;

  const _CodeBlockWithCopy({
    required this.code,
    required this.language,
    required this.displayLanguage,
    required this.isDark,
  });

  @override
  State<_CodeBlockWithCopy> createState() => _CodeBlockWithCopyState();
}

class _CodeBlockWithCopyState extends State<_CodeBlockWithCopy> {
  bool _copied = false;

  void _copyCode() {
    Clipboard.setData(ClipboardData(text: widget.code));
    HapticFeedback.lightImpact();
    setState(() => _copied = true);

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() => _copied = false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = widget.isDark
        ? const Color(0xff1e1e1e)
        : const Color(0xfff5f5f5);
    final headerColor = widget.isDark
        ? const Color(0xff2d2d2d)
        : const Color(0xffe8e8e8);
    final textColor = widget.isDark ? Colors.grey[400] : Colors.grey[600];

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: bgColor,
        border: Border.all(
          color: widget.isDark ? Colors.grey[700]! : Colors.grey[300]!,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header with language and copy button
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: headerColor,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(11),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Language label
                Row(
                  children: [
                    Icon(Icons.code_rounded, size: 14, color: textColor),
                    const SizedBox(width: 6),
                    Text(
                      widget.displayLanguage,
                      style: TextStyle(
                        color: textColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                // Copy button
                InkWell(
                  onTap: _copyCode,
                  borderRadius: BorderRadius.circular(6),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _copied
                          ? Colors.green.withValues(alpha: 0.2)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _copied ? Icons.check_rounded : Icons.copy_rounded,
                          size: 14,
                          color: _copied ? Colors.green : textColor,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _copied ? 'Copied!' : 'Copy',
                          style: TextStyle(
                            color: _copied ? Colors.green : textColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Code content
          HighlightView(
            widget.code,
            language: widget.language,
            theme: widget.isDark ? draculaTheme : githubTheme,
            padding: const EdgeInsets.all(12),
            textStyle: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 13,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final Message message;
  final bool isSpeaking;
  final VoidCallback onSpeak;
  final bool shouldAnimate;
  final bool isLastMessage;

  const _MessageBubble({
    super.key,
    required this.message,
    required this.isSpeaking,
    required this.onSpeak,
    this.shouldAnimate = false,
    this.isLastMessage = false,
  });

  Widget _buildNetworkOrDataImage(String imageUrl) {
    if (imageUrl.startsWith('data:image')) {
      try {
        final base64String = imageUrl.split(',').last;
        final bytes = base64Decode(base64String);
        return Image.memory(
          bytes,
          width: 200,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return _buildErrorPlaceholder();
          },
        );
      } catch (e) {
        return _buildErrorPlaceholder();
      }
    }

    return Image.network(
      imageUrl,
      width: 200,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        return _buildErrorPlaceholder();
      },
    );
  }

  Widget _buildErrorPlaceholder() {
    return Container(
      width: 200,
      height: 150,
      color: Colors.grey[200],
      child: const Center(child: Icon(Icons.broken_image)),
    );
  }

  void _showImagePreview(
    BuildContext context,
    String? imageUrl,
    String? localPath,
  ) {
    if (imageUrl == null && localPath == null) return;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Image
            InteractiveViewer(
              minScale: 0.5,
              maxScale: 4.0,
              child: localPath != null
                  ? Image.file(File(localPath))
                  : _buildNetworkOrDataImage(imageUrl!), // Use helper
            ),
            // Close Button
            Positioned(
              top: 40,
              right: 20,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 30),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            // Download Button
            Positioned(
              bottom: 40,
              child: FilledButton.icon(
                onPressed: () async {
                  try {
                    final hasAccess = await Gal.hasAccess();
                    if (!hasAccess) await Gal.requestAccess();

                    if (localPath != null) {
                      await Gal.putImage(localPath);
                    } else if (imageUrl != null) {
                      if (imageUrl.startsWith('data:image')) {
                        final base64String = imageUrl.split(',').last;
                        final bytes = base64Decode(base64String);
                        await Gal.putImageBytes(bytes);
                      } else {
                        // Placeholder for network download
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Downloading remote images not fully implemented yet',
                            ),
                          ),
                        );
                        return;
                      }
                    }
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Image saved to Gallery!'),
                        ),
                      );
                    }
                  } catch (e) {
                    debugPrint('Save Error: $e');
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Failed to save: $e')),
                      );
                    }
                  }
                },
                icon: const Icon(Icons.download_rounded),
                label: const Text('Save to Gallery'),
              ),
            ),
          ],
        ),
      ),
    );
  }

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
                  onLongPress: () {
                    HapticFeedback.heavyImpact();
                    _showMessageOptions(context, message);
                  },
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
                        if (message.localImagePath != null ||
                            message.imageUrl != null)
                          GestureDetector(
                            onTap: () => _showImagePreview(
                              context,
                              message.imageUrl,
                              message.localImagePath,
                            ),
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: message.localImagePath != null
                                    ? Image.file(
                                        File(message.localImagePath!),
                                        width: 200,
                                        fit: BoxFit.cover,
                                      )
                                    : _buildNetworkOrDataImage(
                                        message.imageUrl!,
                                      ),
                              ),
                            ),
                          ),
                        shouldAnimate
                            ? TypewriterMarkdown(
                                data: message.content,
                                theme: theme,
                                isDark: isDark,
                                textColor: textColor,
                              )
                            : MarkdownBody(
                                selectable: true,
                                data: message.content,
                                builders: {
                                  'code': CodeElementBuilder(isDark: isDark),
                                },
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

          // Suggested Replies (Assistant Only, Last Message Only)
          if (!isUser &&
              isLastMessage &&
              message.suggestedReplies != null &&
              message.suggestedReplies!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 40, top: 8),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: message.suggestedReplies!.map((reply) {
                  return ActionChip(
                    label: Text(
                      reply,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    backgroundColor: theme.colorScheme.primaryContainer
                        .withValues(alpha: 0.3),
                    side: BorderSide.none,
                    padding: EdgeInsets.zero,
                    labelPadding: const EdgeInsets.symmetric(horizontal: 8),
                    onPressed: () {
                      context.read<ChatBloc>().add(SendMessage(message: reply));
                    },
                  );
                }).toList(),
              ),
            ),

          // Action Row (Copy, Read, Feedback)
          Padding(
            padding: EdgeInsets.only(
              top: 4,
              left: isUser ? 0 : 40,
              right: isUser ? 0 : 0,
            ),
            child: Row(
              mainAxisAlignment: isUser
                  ? MainAxisAlignment.end
                  : MainAxisAlignment.start,
              children: [
                // Copy Button
                InkWell(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    Clipboard.setData(ClipboardData(text: message.content));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Message copied'),
                        duration: Duration(seconds: 1),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.all(6),
                    child: Icon(
                      Icons.copy_rounded,
                      size: 16,
                      color: theme.colorScheme.outline,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                // Read (TTS) Button
                InkWell(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    onSpeak();
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.all(6),
                    child: Icon(
                      isSpeaking
                          ? Icons.volume_up_rounded
                          : Icons.volume_off_rounded,
                      size: 16,
                      color: isSpeaking
                          ? theme.colorScheme.primary
                          : theme.colorScheme.outline,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                // Bookmark Button
                BlocBuilder<BookmarksCubit, BookmarksState>(
                  builder: (context, bookmarkState) {
                    final isBookmarked = context
                        .read<BookmarksCubit>()
                        .isBookmarked(message.id);
                    return InkWell(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        context.read<BookmarksCubit>().toggleBookmark(
                          messageId: message.id,
                          content: message.content,
                          role: message.role,
                        );
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              isBookmarked
                                  ? 'Bookmark removed'
                                  : 'Message bookmarked',
                            ),
                            duration: const Duration(seconds: 1),
                          ),
                        );
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.all(6),
                        child: Icon(
                          isBookmarked
                              ? Icons.bookmark_rounded
                              : Icons.bookmark_outline_rounded,
                          size: 16,
                          color: isBookmarked
                              ? Colors.amber
                              : theme.colorScheme.outline,
                        ),
                      ),
                    );
                  },
                ),
                // Feedback Buttons (Assistant Only)
                if (!isUser) ...[
                  const SizedBox(width: 4),
                  InkWell(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      context.read<ChatBloc>().add(
                        RateMessage(message.id, isPositive: true),
                      );
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Thanks for the feedback!'),
                          duration: Duration(seconds: 1),
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.all(6),
                      child: Icon(
                        Icons.thumb_up_alt_outlined,
                        size: 16,
                        color: theme.colorScheme.outline,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  InkWell(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      context.read<ChatBloc>().add(
                        RateMessage(message.id, isPositive: false),
                      );
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Thanks for the feedback!'),
                          duration: Duration(seconds: 1),
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.all(6),
                      child: Icon(
                        Icons.thumb_down_alt_outlined,
                        size: 16,
                        color: theme.colorScheme.outline,
                      ),
                    ),
                  ),
                ],
                // Time (Moved here for better alignment with actions)
                if (message.createdAt != null) ...[
                  const SizedBox(width: 8),
                  Text(
                    _formatTime(message.createdAt!),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.outline.withValues(alpha: 0.7),
                      fontSize: 10,
                    ),
                  ),
                ],
              ],
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
}

void _showMessageOptions(BuildContext context, Message message) {
  showModalBottomSheet(
    context: context,
    builder: (context) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (message.isUser)
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Edit Message'),
              onTap: () {
                Navigator.pop(context); // Close sheet
                _showEditDialog(context, message);
              },
            ),
          if (!message.isUser)
            ListTile(
              leading: const Icon(Icons.refresh),
              title: const Text('Regenerate Response'),
              onTap: () {
                Navigator.pop(context); // Close sheet
                // Need conversationId. Assuming it's in context/state.
                // We can fetch it via context.read<ChatBloc>().state.currentConversationId
                final conversationId = context
                    .read<ChatBloc>()
                    .state
                    .currentConversationId;
                if (conversationId != null) {
                  context.read<ChatBloc>().add(
                    RegenerateMessage(conversationId),
                  );
                }
              },
            ),
          ListTile(
            leading: const Icon(Icons.copy),
            title: const Text('Copy Message'),
            onTap: () {
              Navigator.pop(context); // Close sheet
              Clipboard.setData(ClipboardData(text: message.content));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Message copied to clipboard')),
              );
            },
          ),
          Builder(
            builder: (context) {
              final isBookmarked = context.read<BookmarksCubit>().isBookmarked(
                message.id,
              );
              return ListTile(
                leading: Icon(
                  isBookmarked
                      ? Icons.bookmark_remove_rounded
                      : Icons.bookmark_add_outlined,
                  color: isBookmarked
                      ? Theme.of(context).colorScheme.primary
                      : null,
                ),
                title: Text(
                  isBookmarked ? 'Remove Bookmark' : 'Bookmark Message',
                ),
                onTap: () {
                  Navigator.pop(context); // Close sheet
                  final state = context.read<ChatBloc>().state;
                  // Find conversation title if possible, or use default
                  final conversation = state.conversations
                      .cast<Conversation?>()
                      .firstWhere(
                        (c) => c?.id == state.currentConversationId,
                        orElse: () => null,
                      );

                  context.read<BookmarksCubit>().toggleBookmark(
                    messageId: message.id,
                    content: message.content,
                    role: message.role,
                    conversationId: state.currentConversationId,
                    conversationTitle: conversation?.title,
                  );

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        isBookmarked
                            ? 'Bookmark removed'
                            : 'Message bookmarked',
                      ),
                    ),
                  );
                },
              );
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

class TypewriterMarkdown extends StatefulWidget {
  final String data;
  final ThemeData theme;
  final bool isDark;
  final Color? textColor;

  const TypewriterMarkdown({
    super.key,
    required this.data,
    required this.theme,
    required this.isDark,
    required this.textColor,
  });

  @override
  State<TypewriterMarkdown> createState() => _TypewriterMarkdownState();
}

class _TypewriterMarkdownState extends State<TypewriterMarkdown>
    with SingleTickerProviderStateMixin {
  String _displayedText = "";
  Timer? _timer;
  int _currentWordIndex = 0;
  List<String> _words = [];
  bool _isComplete = false;

  @override
  void initState() {
    super.initState();
    _parseWords();
    _startTyping();
  }

  void _parseWords() {
    // Split by whitespace but preserve the whitespace
    _words = [];
    final regex = RegExp(r'(\S+|\s+)');
    final matches = regex.allMatches(widget.data);
    for (final match in matches) {
      _words.add(match.group(0)!);
    }
  }

  @override
  void didUpdateWidget(covariant TypewriterMarkdown oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.data != widget.data) {
      _parseWords();
      if (widget.data.startsWith(_displayedText)) {
        // Continue from current position
        _startTyping();
      } else {
        // Full reset
        _currentWordIndex = 0;
        _displayedText = "";
        _isComplete = false;
        _startTyping();
      }
    }
  }

  void _startTyping() {
    _timer?.cancel();

    // Adaptive speed: faster for longer content
    // Base: 20ms per word, min: 5ms, max: 30ms
    final wordCount = _words.length;
    int intervalMs;
    if (wordCount > 200) {
      intervalMs = 5; // Very fast for long content
    } else if (wordCount > 100) {
      intervalMs = 10;
    } else if (wordCount > 50) {
      intervalMs = 15;
    } else {
      intervalMs = 20; // Normal speed for short content
    }

    _timer = Timer.periodic(Duration(milliseconds: intervalMs), (timer) {
      if (_currentWordIndex < _words.length) {
        if (mounted) {
          setState(() {
            _displayedText += _words[_currentWordIndex];
            _currentWordIndex++;
          });
        }
      } else {
        _timer?.cancel();
        if (mounted && !_isComplete) {
          setState(() => _isComplete = true);
        }
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MarkdownBody(
      selectable: true,
      data: _displayedText,
      builders: {'code': CodeElementBuilder(isDark: widget.isDark)},
      styleSheet: MarkdownStyleSheet(
        p: widget.theme.textTheme.bodyLarge?.copyWith(
          color: widget.textColor,
          height: 1.5,
        ),
        strong: widget.theme.textTheme.bodyLarge?.copyWith(
          color: widget.textColor,
          fontWeight: FontWeight.bold,
          height: 1.5,
        ),
        h1: widget.theme.textTheme.headlineSmall?.copyWith(
          color: widget.textColor,
        ),
        h2: widget.theme.textTheme.titleLarge?.copyWith(
          color: widget.textColor,
        ),
        h3: widget.theme.textTheme.titleMedium?.copyWith(
          color: widget.textColor,
        ),
        listBullet: TextStyle(color: widget.textColor),
        code: widget.theme.textTheme.bodyMedium?.copyWith(
          color: widget.isDark ? Colors.grey[200] : Colors.grey[800],
          backgroundColor: widget.isDark ? Colors.grey[800] : Colors.grey[200],
          fontFamily: 'monospace',
        ),
      ),
    );
  }
}

class _TypingIndicator extends StatefulWidget {
  const _TypingIndicator();

  @override
  State<_TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<_TypingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dotColor = theme.colorScheme.primary.withValues(alpha: 0.6);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(3, (index) {
          return AnimatedBuilder(
            animation: _animation,
            builder: (context, child) {
              // Staggered sine wave
              final offset = index * 0.2;
              final value = math.sin(
                (_controller.value * 2 * math.pi) + offset,
              );
              final opacity = (value + 1) / 2; // Normalize to 0..1

              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 2),
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: dotColor.withOpacity(0.3 + (0.7 * opacity)),
                  shape: BoxShape.circle,
                ),
              );
            },
          );
        }),
      ),
    );
  }
}
