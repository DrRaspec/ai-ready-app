import 'dart:convert';
import 'dart:io';

import 'package:mime/mime.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:bloc/bloc.dart';
import 'package:ai_chat_bot/core/errors/api_exception.dart';
import 'package:ai_chat_bot/core/logging/app_logger.dart';
import 'package:ai_chat_bot/features/chat/data/chat_repository.dart';
import 'package:ai_chat_bot/features/chat/data/models/chat_request.dart';
import 'package:ai_chat_bot/features/chat/data/models/conversation.dart';
import 'package:ai_chat_bot/features/chat/data/models/message.dart';
import 'package:ai_chat_bot/features/chat/data/models/chat_mode.dart'; // Re-added
import 'chat_event.dart';
import 'chat_state.dart';

class ChatBloc extends Bloc<ChatEvent, ChatState> {
  final ChatRepository _repository;

  ChatBloc(ChatRepository repository)
    : _repository = repository,
      super(const ChatState()) {
    on<LoadConversations>(_onLoadConversations);
    on<SelectConversation>(_onSelectConversation);
    on<SendMessage>(_onSendMessage);
    on<NewConversation>(_onNewConversation);
    on<RenameConversation>(_onRenameConversation);
    on<DeleteConversation>(_onDeleteConversation);
    on<LoadUsage>(_onLoadUsage);
    on<AttachImage>(_onAttachImage);
    on<DetachImage>(_onDetachImage);
    on<SetChatMode>(_onSetChatMode);

    on<EditMessage>(_onEditMessage);
    on<RegenerateMessage>(_onRegenerateMessage);
    on<RateMessage>(_onRateMessage);
    on<GetSummary>(_onGetSummary);
    on<PerformWebSearch>(_onPerformWebSearch);
  }

  Future<void> _onEditMessage(
    EditMessage event,
    Emitter<ChatState> emit,
  ) async {
    if (state.currentConversationId == null) return;

    // Optimistic update
    final updatedMessages = state.messages.map((m) {
      if (m.id == event.messageId) {
        return m.copyWith(content: event.newContent);
      }
      return m;
    }).toList();

    emit(state.copyWith(messages: updatedMessages));

    try {
      final response = await _repository.editMessage(
        state.currentConversationId!,
        event.messageId,
        event.newContent,
      );

      if (!response.success) {
        // Revert on failure (reload messages)
        add(SelectConversation(state.currentConversationId!));
        emit(
          state.copyWith(
            errorMessage: response.message ?? 'Failed to edit message',
          ),
        );
      }
    } on ApiException catch (e) {
      // Revert on failure
      add(SelectConversation(state.currentConversationId!));
      emit(state.copyWith(errorMessage: e.message));
    }
  }

  void _onAttachImage(AttachImage event, Emitter<ChatState> emit) {
    emit(state.copyWith(attachedImagePath: event.path));
  }

  void _onDetachImage(DetachImage event, Emitter<ChatState> emit) {
    emit(state.copyWith(clearAttachedImage: true));
  }

  void _onSetChatMode(SetChatMode event, Emitter<ChatState> emit) {
    emit(state.copyWith(chatMode: event.mode));
  }

  Future<void> _onLoadConversations(
    LoadConversations event,
    Emitter<ChatState> emit,
  ) async {
    // If we're already loading or strict refresh isn't requested and we don't have more, return.
    // For now, assuming LoadConversations checks event.page normally.
    // If event.page == 0, it's a refresh.

    final isRefresh = event.page == 0;
    if (!isRefresh && !state.hasMoreConversations) return;
    if (state.isConversationsLoading) return;

    emit(state.copyWith(isConversationsLoading: true, clearError: true));

    try {
      final response = await _repository.getConversations(
        page: event.page,
        size: event.size,
      );

      if (response.success && response.data != null) {
        final newConversations = response.data!;
        final hasMore = newConversations.length >= event.size;

        // Merge conversations
        final List<Conversation> updatedList = isRefresh
            ? newConversations
            : [...state.conversations, ...newConversations];

        emit(
          state.copyWith(
            conversations: updatedList,
            isConversationsLoading: false,
            hasMoreConversations: hasMore,
            conversationPage: event.page,
          ),
        );
      } else {
        emit(
          state.copyWith(
            isConversationsLoading: false,
            errorMessage: response.message,
          ),
        );
      }
    } on ApiException catch (e) {
      emit(
        state.copyWith(isConversationsLoading: false, errorMessage: e.message),
      );
    }
  }

  Future<void> _onSelectConversation(
    SelectConversation event,
    Emitter<ChatState> emit,
  ) async {
    emit(
      state.copyWith(
        currentConversationId: event.conversationId,
        messages: [],
        status: ChatStatus.loading,
      ),
    );

    try {
      final response = await _repository.getConversationMessages(
        event.conversationId,
      );

      if (response.success && response.data != null) {
        emit(
          state.copyWith(status: ChatStatus.success, messages: response.data!),
        );
      } else {
        emit(
          state.copyWith(
            status: ChatStatus.failure,
            errorMessage: response.message,
          ),
        );
      }
    } on ApiException catch (e) {
      emit(state.copyWith(status: ChatStatus.failure, errorMessage: e.message));
    }
  }

  Future<void> _onSendMessage(
    SendMessage event,
    Emitter<ChatState> emit,
  ) async {
    // Optimistically add user message
    final userMessage = Message.userLocal(
      event.message,
      imagePath: state.attachedImagePath,
    );
    final updatedMessages = [...state.messages, userMessage];

    emit(
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
      // Clear attachment after sending, before potential error,
      // but usually better to clear after success?
      // Existing logic cleared it early. We'll stick to that or move it.
      // Let's clear it after request creation to simulate "sent".
      if (hasImage) {
        add(const DetachImage());
      }

      String modeHint = 'CHAT'; // Default
      if (state.chatMode == ChatMode.imageGeneration) {
        modeHint = 'IMAGE_GEN';
      }
      // You can add more mappings if needed, e.g. CODING -> CHAT or CODING

      final request = ChatRequest(
        message: event.message,
        systemPrompt: event.systemPrompt ?? (state.chatMode?.systemPrompt),
        model: event.model,
        temperature: event.temperature,
        imageBase64: base64Image,
        imageMimeType: mimeType,
        modeHint: modeHint,
        conversationId: state.currentConversationId,
        forceTextChat: modeHint == 'CHAT',
      );

      final response = await _repository.sendSmartMessage(request);

      if (response.success && response.data != null) {
        final chatResponse = response.data!;

        // Logic to determine if we show the image
        String? finalImageUrl = chatResponse.imageUrl;
        final intent = chatResponse.detectedIntent;

        if (intent == 'TEXT_CHAT' || intent == 'VISION_CHAT') {
          // Force no image for text intents, even if backend sends one (safety)
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

        // Check if this is a new conversation BEFORE emitting new state
        final wasNewConversation =
            state.currentConversationId == null && newConversationId != null;

        emit(
          state.copyWith(
            messages: [...updatedMessages, assistantMessage],
            currentConversationId: newConversationId,
            isSending: false,
            lastAnimatedMessageId: assistantMessage.id,
          ),
        );

        // Reload conversations if this was a new conversation
        if (wasNewConversation) {
          add(const LoadConversations());
        }
      } else {
        emit(state.copyWith(isSending: false, errorMessage: response.message));
      }
    } on ApiException catch (e) {
      emit(state.copyWith(isSending: false, errorMessage: e.message));
    }
  }

  void _onNewConversation(NewConversation event, Emitter<ChatState> emit) {
    emit(
      state.copyWith(
        clearCurrentConversation: true,
        messages: [],
        clearError: true,
      ),
    );
  }

  Future<void> _onRenameConversation(
    RenameConversation event,
    Emitter<ChatState> emit,
  ) async {
    try {
      final response = await _repository.renameConversation(
        event.conversationId,
        event.newTitle,
      );

      if (response.success) {
        // Update local conversation
        final updatedConversations = state.conversations.map((c) {
          if (c.id == event.conversationId) {
            return c.copyWith(title: event.newTitle);
          }
          return c;
        }).toList();

        emit(state.copyWith(conversations: updatedConversations));
      }
    } on ApiException catch (e) {
      emit(state.copyWith(errorMessage: e.message));
    }
  }

  Future<void> _onDeleteConversation(
    DeleteConversation event,
    Emitter<ChatState> emit,
  ) async {
    try {
      final response = await _repository.deleteConversation(
        event.conversationId,
      );

      if (response.success) {
        final updatedConversations = state.conversations
            .where((c) => c.id != event.conversationId)
            .toList();

        final clearCurrent =
            state.currentConversationId == event.conversationId;

        emit(
          state.copyWith(
            conversations: updatedConversations,
            clearCurrentConversation: clearCurrent,
            messages: clearCurrent ? [] : null,
          ),
        );
      }
    } on ApiException catch (e) {
      emit(state.copyWith(errorMessage: e.message));
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

  Future<void> _onLoadUsage(LoadUsage event, Emitter<ChatState> emit) async {
    try {
      final response = await _repository.getUsage();

      if (response.success && response.data != null) {
        emit(state.copyWith(usage: response.data!));
      }
    } on ApiException catch (e) {
      emit(state.copyWith(errorMessage: e.message));
    }
  }

  Future<void> _onRegenerateMessage(
    RegenerateMessage event,
    Emitter<ChatState> emit,
  ) async {
    emit(state.copyWith(isSending: true));
    try {
      final response = await _repository.regenerate(event.conversationId);
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

        emit(
          state.copyWith(
            messages: updatedMessages,
            isSending: false,
            lastAnimatedMessageId: assistantMessage.id,
          ),
        );
      } else {
        emit(state.copyWith(isSending: false, errorMessage: response.message));
      }
    } on ApiException catch (e) {
      emit(state.copyWith(isSending: false, errorMessage: e.message));
    }
  }

  Future<void> _onRateMessage(
    RateMessage event,
    Emitter<ChatState> emit,
  ) async {
    try {
      await _repository.rateFeedback(event.messageId, event.isPositive);
      // Optionally show a snackbar or update message state locally to show feedback given
    } on ApiException catch (e) {
      // access context in UI to show error? or emit state error
      AppLogger.e('Rate Message Failed: ${e.message}');
    }
  }

  Future<void> _onGetSummary(GetSummary event, Emitter<ChatState> emit) async {
    try {
      final response = await _repository.getSummary(event.conversationId);
      if (response.success) {
        // Show summary in a dialog or snippet in UI?
        // Using AppLogger for now or we could stick it in a state field `lastSummary`
        AppLogger.d('Summary: ${response.data}');
      }
    } on ApiException catch (e) {
      emit(state.copyWith(errorMessage: e.message));
    }
  }

  Future<void> _onPerformWebSearch(
    PerformWebSearch event,
    Emitter<ChatState> emit,
  ) async {
    // This might be called contextually or by user command
    try {
      final response = await _repository.webSearch(event.query);
      if (response.success && response.data != null) {
        // Handle search results, maybe append a system message or separate UI state
        // For now, logging
        AppLogger.d('Search Results: ${response.data?.length}');
      }
    } on ApiException catch (e) {
      emit(state.copyWith(errorMessage: e.message));
    }
  }
}
