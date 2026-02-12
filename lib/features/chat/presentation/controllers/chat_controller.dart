import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:mime/mime.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:ai_chat_bot/core/errors/api_exception.dart';
import 'package:ai_chat_bot/core/logging/app_logger.dart';
import 'package:get/get.dart';
import 'package:ai_chat_bot/features/chat/data/chat_repository.dart';
import 'package:ai_chat_bot/features/chat/data/models/chat_request.dart';
import 'package:ai_chat_bot/features/chat/data/models/conversation.dart';
import 'package:ai_chat_bot/features/chat/data/models/message.dart';
import 'package:ai_chat_bot/core/network/models/api_response.dart';
import 'package:ai_chat_bot/features/chat/data/models/chat_response.dart';
import 'package:ai_chat_bot/features/chat/data/models/chat_mode.dart';
import 'chat_state.dart';

class ChatController extends GetxController {
  final ChatRepository _repository;
  Future<void> _eventQueue = Future<void>.value();
  final Rx<ChatState> rxState;

  ChatState get state => rxState.value;

  void _setState(ChatState newState) {
    rxState.value = newState;
  }

  ChatController(ChatRepository repository)
    : _repository = repository,
      rxState = const ChatState().obs;

  Future<void> _enqueue(Future<void> Function() task) async {
    _eventQueue = _eventQueue.then((_) => task());
    return _eventQueue;
  }

  Future<void> loadConversations({int page = 0, int size = 20}) async {
    return _enqueue(() => _onLoadConversations(page: page, size: size));
  }

  Future<void> selectConversation(String conversationId) async {
    return _enqueue(
      () => _onSelectConversation(conversationId: conversationId),
    );
  }

  Future<void> refreshMessages(String conversationId) async {
    return _enqueue(() => _onRefreshMessages(conversationId: conversationId));
  }

  Future<void> sendMessage({
    required String message,
    String? conversationId,
    String? systemPrompt,
    String? model,
    double? temperature,
    bool useStream = true,
  }) async {
    return _enqueue(
      () => _onSendMessage(
        message: message,
        conversationId: conversationId,
        systemPrompt: systemPrompt,
        model: model,
        temperature: temperature,
        useStream: useStream,
      ),
    );
  }

  Future<void> newConversation() async {
    return _enqueue(_onNewConversation);
  }

  Future<void> renameConversation(
    String conversationId,
    String newTitle,
  ) async {
    return _enqueue(
      () => _onRenameConversation(
        conversationId: conversationId,
        newTitle: newTitle,
      ),
    );
  }

  Future<void> deleteConversation(String conversationId) async {
    return _enqueue(
      () => _onDeleteConversation(conversationId: conversationId),
    );
  }

  Future<void> loadUsage() async {
    return _enqueue(_onLoadUsage);
  }

  Future<void> attachImage(String path) async {
    return _enqueue(() async => _onAttachImage(path: path));
  }

  Future<void> detachImage() async {
    return _enqueue(() async => _onDetachImage());
  }

  Future<void> setChatMode(dynamic mode) async {
    return _enqueue(() async => _onSetChatMode(mode: mode));
  }

  Future<void> editMessage(String messageId, String newContent) async {
    return _enqueue(
      () => _onEditMessage(messageId: messageId, newContent: newContent),
    );
  }

  Future<void> regenerateMessage(String conversationId) async {
    return _enqueue(() => _onRegenerateMessage(conversationId: conversationId));
  }

  Future<void> rateMessage(String messageId, {required bool isPositive}) async {
    return _enqueue(
      () => _onRateMessage(messageId: messageId, isPositive: isPositive),
    );
  }

  Future<void> getSummary(String conversationId) async {
    return _enqueue(() => _onGetSummary(conversationId: conversationId));
  }

  Future<void> selectFolder(String? folderId) async {
    return _enqueue(() async => _onSelectFolder(folderId: folderId));
  }

  Future<void> moveToFolder(String conversationId, String? folderId) async {
    return _enqueue(
      () => _onMoveToFolder(conversationId: conversationId, folderId: folderId),
    );
  }

  Future<void> performWebSearch(String query) async {
    return _enqueue(() => _onPerformWebSearch(query: query));
  }

  Future<void> searchConversations(String query) async {
    return _enqueue(() async => _onSearchConversations(query: query));
  }

  void _onSearchConversations({required String query}) {
    _setState(state.copyWith(searchQuery: query));
  }

  Future<void> _onEditMessage({
    required String messageId,
    required String newContent,
  }) async {
    if (state.currentConversationId == null) return;

    // Optimistic update
    final updatedMessages = state.messages.map((m) {
      if (m.id == messageId) {
        return m.copyWith(content: newContent);
      }
      return m;
    }).toList();

    _setState(state.copyWith(messages: updatedMessages));

    try {
      final response = await _repository.editMessage(
        state.currentConversationId!,
        messageId,
        newContent,
      );

      if (!response.success) {
        // Revert on failure (reload messages)
        unawaited(selectConversation(state.currentConversationId!));
        _setState(
          state.copyWith(
            errorMessage: response.message ?? 'Failed to edit message',
          ),
        );
      }
    } on ApiException catch (e) {
      // Revert on failure
      unawaited(selectConversation(state.currentConversationId!));
      _setState(state.copyWith(errorMessage: e.message));
    }
  }

  void _onAttachImage({required String path}) {
    _setState(state.copyWith(attachedImagePath: path));
  }

  void _onDetachImage() {
    _setState(state.copyWith(clearAttachedImage: true));
  }

  void _onSetChatMode({required dynamic mode}) {
    _setState(state.copyWith(chatMode: mode));
  }

  void _onSelectFolder({required String? folderId}) {
    _setState(
      state.copyWith(
        currentFolderId: folderId,
        clearCurrentFolderId: folderId == null,
        conversations: [],
        hasMoreConversations: true,
        conversationPage: 0,
        isConversationsLoading: false, // Ensure we are ready to load
      ),
    );
    unawaited(loadConversations(page: 0));
  }

  Future<void> _onLoadConversations({
    required int page,
    required int size,
  }) async {
    // If we're already loading or strict refresh isn't requested and we don't have more, return.
    final isRefresh = page == 0;
    if (!isRefresh && !state.hasMoreConversations) return;
    if (state.isConversationsLoading) return;

    _setState(state.copyWith(isConversationsLoading: true, clearError: true));

    try {
      final response = await _repository.getConversations(
        page: page,
        size: size,
        folderId: state.currentFolderId, // Use state's current folder
      );

      if (response.success && response.data != null) {
        final newConversations = response.data!;
        final hasMore = newConversations.length >= size;

        // Merge conversations
        final List<Conversation> updatedList = isRefresh
            ? newConversations
            : [...state.conversations, ...newConversations];

        _setState(
          state.copyWith(
            conversations: updatedList,
            isConversationsLoading: false,
            hasMoreConversations: hasMore,
            conversationPage: page,
          ),
        );
      } else {
        _setState(
          state.copyWith(
            isConversationsLoading: false,
            errorMessage: response.message,
          ),
        );
      }
    } on ApiException catch (e) {
      _setState(
        state.copyWith(isConversationsLoading: false, errorMessage: e.message),
      );
    }
  }

  Future<void> _onSelectConversation({required String conversationId}) async {
    _setState(
      state.copyWith(
        currentConversationId: conversationId,
        messages: [],
        status: ChatStatus.loading,
      ),
    );

    try {
      final response = await _repository.getConversationMessages(
        conversationId,
      );

      if (response.success && response.data != null) {
        _setState(
          state.copyWith(status: ChatStatus.success, messages: response.data!),
        );
      } else {
        _setState(
          state.copyWith(
            status: ChatStatus.failure,
            errorMessage: response.message,
          ),
        );
      }
    } on ApiException catch (e) {
      _setState(
        state.copyWith(status: ChatStatus.failure, errorMessage: e.message),
      );
    }
  }

  Future<void> _onRefreshMessages({required String conversationId}) async {
    try {
      final response = await _repository.getConversationMessages(
        conversationId,
      );

      if (response.success && response.data != null) {
        _setState(state.copyWith(messages: response.data!));
      }
    } on ApiException catch (e) {
      AppLogger.e('Silent refresh failed: ${e.message}');
    }
  }

  Future<void> _onSendMessage({
    required String message,
    String? conversationId,
    String? systemPrompt,
    String? model,
    double? temperature,
    bool useStream = true,
  }) async {
    // Optimistically add user message
    final userMessage = Message.userLocal(
      message,
      imagePath: state.attachedImagePath,
    );
    final updatedMessages = [...state.messages, userMessage];

    _setState(
      state.copyWith(
        messages: updatedMessages,
        isSending: true,
        clearError: true,
      ),
    );

    try {
      String? base64Image;
      String? mimeType;

      if (state.attachedImagePath != null) {
        final file = File(state.attachedImagePath!);
        final bytes = await _compressImage(file);
        base64Image = base64Encode(bytes);
        mimeType = lookupMimeType(state.attachedImagePath!) ?? 'image/jpeg';
      }

      final hasImage = state.attachedImagePath != null;
      if (hasImage) {
        // Clear attachment immediately to reflect UI state
        _onDetachImage();
      }

      // Check Mode and Model
      String modeHint = 'CHAT';
      if (state.chatMode == ChatMode.imageGeneration) {
        modeHint = 'IMAGE_GEN';
      } else if (state.chatMode == ChatMode.imageEditing) {
        modeHint = 'IMAGE_EDIT';
      }

      final request = ChatRequest(
        message: message,
        systemPrompt: systemPrompt ?? (state.chatMode?.systemPrompt),
        model:
            model ??
            (state.chatMode == ChatMode.coding
                ? 'llama-3.1-8b-instant'
                : null), // Example fallback
        temperature: temperature,
        imageBase64: base64Image,
        imageMimeType: mimeType,
        modeHint: modeHint,
        conversationId: state.currentConversationId,
        folderId: state.currentFolderId,
        forceTextChat: modeHint == 'CHAT',
      );

      // --- STREAMING LOGIC ---
      if (useStream && modeHint != 'IMAGE_GEN') {
        // Don't stream images
        // 1. Create a placeholder assistant message
        final tempAssistantId =
            'stream_${DateTime.now().millisecondsSinceEpoch}';
        var assistantMessage = Message.assistantLocal(
          '', // start empty
          id: tempAssistantId,
        );

        var currentMessages = [...updatedMessages, assistantMessage];
        _setState(state.copyWith(messages: currentMessages));

        final stream = _repository.streamSmartMessage(request);

        try {
          await for (final chunk in stream) {
            // Update the last message (assistant) with new chunk
            final currentContent = assistantMessage.content + chunk;
            assistantMessage = assistantMessage.copyWith(
              content: currentContent,
            );

            final index = currentMessages.indexWhere(
              (m) => m.id == tempAssistantId,
            );
            if (index != -1) {
              currentMessages = List.from(currentMessages);
              currentMessages[index] = assistantMessage;
              _setState(state.copyWith(messages: currentMessages));
            }
          }
        } catch (e) {
          AppLogger.e('Streaming error: $e');
          _setState(
            state.copyWith(errorMessage: 'Streaming failed: ${e.toString()}'),
          );
        }

        // Finalize
        _setState(state.copyWith(isSending: false));
        // Note: You might want to reload conversation to get the real ID from server if needed
        // But for now, local ID works for display.
        // Ideally, we fetch the conversation again to sync IDs.
        if (state.currentConversationId != null) {
          // Passive refresh to get real message IDs
          unawaited(refreshMessages(state.currentConversationId!));
        }
      } else {
        // --- STANDARD FUTURE LOGIC ---
        final ApiResponse<ChatResponse> response;
        if (modeHint == 'IMAGE_EDIT' && state.attachedImagePath != null) {
          // Use the dedicated edit image endpoint
          response = await _repository.editImage(
            prompt: message,
            imagePath: state.attachedImagePath!,
          );
        } else {
          response = await _repository.sendSmartMessage(request);
        }

        if (response.success && response.data != null) {
          final chatResponse = response.data!;
          AppLogger.d('AI Model Used: ${chatResponse.model ?? "Unknown"}');

          // Logic to determine if we show the image
          String? finalImageUrl = chatResponse.imageUrl;
          final intent = chatResponse.detectedIntent;

          if (intent == 'TEXT_CHAT' || intent == 'VISION_CHAT') {
            finalImageUrl = null;
          }

          final assistantMessage = Message.assistantLocal(
            chatResponse.response,
            imageUrl: finalImageUrl,
            detectedIntent: intent,
            suggestedReplies: chatResponse.suggestedReplies,
          );

          final newConversationId =
              chatResponse.conversationId ?? state.currentConversationId;

          final wasNewConversation =
              state.currentConversationId == null && newConversationId != null;

          // Automatic Title Renaming logic
          List<Conversation> updatedConversations = state.conversations;
          if (newConversationId != null && chatResponse.title != null) {
            updatedConversations = state.conversations.map((c) {
              if (c.id == newConversationId) {
                return c.copyWith(title: chatResponse.title);
              }
              return c;
            }).toList();
          }

          _setState(
            state.copyWith(
              messages: [...updatedMessages, assistantMessage],
              currentConversationId: newConversationId,
              conversations: chatResponse.title != null
                  ? updatedConversations
                  : null,
              isSending: false,
              lastAnimatedMessageId: assistantMessage.id,
            ),
          );

          if (wasNewConversation) {
            unawaited(loadConversations());
          }
        } else {
          _setState(
            state.copyWith(isSending: false, errorMessage: response.message),
          );
        }
      }
    } on ApiException catch (e) {
      _setState(state.copyWith(isSending: false, errorMessage: e.message));
    }
  }

  Future<void> _onNewConversation() async {
    _setState(
      state.copyWith(
        clearCurrentConversation: true,
        messages: [],
        clearError: true,
      ),
    );
  }

  Future<void> _onRenameConversation({
    required String conversationId,
    required String newTitle,
  }) async {
    try {
      final response = await _repository.renameConversation(
        conversationId,
        newTitle,
      );

      if (response.success) {
        // Update local conversation
        final updatedConversations = state.conversations.map((c) {
          if (c.id == conversationId) {
            return c.copyWith(title: newTitle);
          }
          return c;
        }).toList();

        _setState(state.copyWith(conversations: updatedConversations));
      }
    } on ApiException catch (e) {
      _setState(state.copyWith(errorMessage: e.message));
    }
  }

  Future<void> _onMoveToFolder({
    required String conversationId,
    required String? folderId,
  }) async {
    try {
      final response = await _repository.moveConversationToFolder(
        conversationId,
        folderId,
      );

      if (response.success) {
        // Update local conversation
        final updatedConversations = state.conversations.map((c) {
          if (c.id == conversationId) {
            return c.copyWith(folderId: folderId);
          }
          return c;
        }).toList();

        // If we are currently filtering by a folder and the conversation moved out of it (or into another)
        // we might want to refresh. But for now, simple local update is enough if we filter on backend.
        // Actually, if we filter on backend, moving a conversation OUT of the current folder means it should disappear from the list.

        List<Conversation> finalConversations = updatedConversations;
        if (state.currentFolderId != null &&
            state.currentFolderId != folderId) {
          finalConversations = updatedConversations
              .where((c) => c.folderId == state.currentFolderId)
              .toList();
        }

        _setState(state.copyWith(conversations: finalConversations));
      }
    } on ApiException catch (e) {
      _setState(state.copyWith(errorMessage: e.message));
    }
  }

  Future<void> _onDeleteConversation({required String conversationId}) async {
    try {
      final response = await _repository.deleteConversation(conversationId);

      if (response.success) {
        final updatedConversations = state.conversations
            .where((c) => c.id != conversationId)
            .toList();

        final clearCurrent = state.currentConversationId == conversationId;

        _setState(
          state.copyWith(
            conversations: updatedConversations,
            clearCurrentConversation: clearCurrent,
            messages: clearCurrent ? [] : null,
          ),
        );
      }
    } on ApiException catch (e) {
      _setState(state.copyWith(errorMessage: e.message));
    }
  }

  Future<List<int>> _compressImage(File file) async {
    final originalSize = await file.length();
    AppLogger.d(
      'Image: Original Size = ${(originalSize / 1024).toStringAsFixed(2)} KB',
    );

    try {
      final result = await FlutterImageCompress.compressWithFile(
        file.absolute.path,
        minWidth: 800,
        minHeight: 800,
        quality: 70,
      );

      if (result == null) {
        AppLogger.d('Image: Compression returned null. Using original.');
        // Fallback to original if compression fails
        return await file.readAsBytes();
      }

      AppLogger.d(
        'Image: Compressed Size = ${(result.length / 1024).toStringAsFixed(2)} KB',
      );
      return result;
    } catch (e) {
      AppLogger.e('Image: Compression failed ($e).');

      // If original is > 4MB, do not send it as it will likely fail
      if (originalSize > 4 * 1024 * 1024) {
        throw ApiException(
          message: 'Image too large (rebuild app required)',
          status: 413,
        );
      }

      AppLogger.w('Image: Fallback to original.');
      return await file.readAsBytes();
    }
  }

  Future<void> _onLoadUsage() async {
    try {
      final response = await _repository.getUsage();

      if (response.success && response.data != null) {
        _setState(state.copyWith(usage: response.data!));
      }
    } on ApiException catch (e) {
      _setState(state.copyWith(errorMessage: e.message));
    }
  }

  Future<void> _onRegenerateMessage({required String conversationId}) async {
    _setState(state.copyWith(isSending: true));
    try {
      final response = await _repository.regenerate(conversationId);
      if (response.success && response.data != null) {
        final chatResponse = response.data!;

        // Remove last assistant message if exists, or just append?
        // Usually regenerate replaces the last message.
        // For simplicity, we'll append a new message or update the last one.
        // Let's replace the last assistant message if it exists.

        List<Message> updatedMessages = List.from(state.messages);
        if (updatedMessages.isNotEmpty && updatedMessages.last.isAssistant) {
          updatedMessages.removeLast();
        }

        final assistantMessage = Message.assistantLocal(
          chatResponse.response,
          imageUrl: chatResponse.imageUrl,
          detectedIntent: chatResponse.detectedIntent,
          suggestedReplies: chatResponse.suggestedReplies,
        );

        updatedMessages.add(assistantMessage);

        _setState(
          state.copyWith(
            messages: updatedMessages,
            isSending: false,
            lastAnimatedMessageId: assistantMessage.id,
          ),
        );
      } else {
        _setState(
          state.copyWith(isSending: false, errorMessage: response.message),
        );
      }
    } on ApiException catch (e) {
      _setState(state.copyWith(isSending: false, errorMessage: e.message));
    }
  }

  Future<void> _onRateMessage({
    required String messageId,
    required bool isPositive,
  }) async {
    try {
      await _repository.rateFeedback(messageId, isPositive);
      // Optionally show a snackbar or update message state locally to show feedback given
    } on ApiException catch (e) {
      // access context in UI to show error? or emit state error
      AppLogger.e('Rate Message Failed: ${e.message}');
    }
  }

  Future<void> _onGetSummary({required String conversationId}) async {
    try {
      final response = await _repository.getSummary(conversationId);
      if (response.success) {
        // Show summary in a dialog or snippet in UI?
        // Using AppLogger for now or we could stick it in a state field `lastSummary`
        AppLogger.d('Summary: ${response.data}');
      }
    } on ApiException catch (e) {
      _setState(state.copyWith(errorMessage: e.message));
    }
  }

  Future<void> _onPerformWebSearch({required String query}) async {
    // This might be called contextually or by user command
    try {
      final response = await _repository.webSearch(query);
      if (response.success && response.data != null) {
        // Handle search results, maybe append a system message or separate UI state
        // For now, logging
        AppLogger.d('Search Results: ${response.data?.length}');
      }
    } on ApiException catch (e) {
      _setState(state.copyWith(errorMessage: e.message));
    }
  }
}
