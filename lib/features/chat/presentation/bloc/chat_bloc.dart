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
import 'package:ai_chat_bot/features/chat/data/models/chat_mode.dart';
import 'package:ai_chat_bot/features/chat/data/models/image_generation_request.dart';
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

      final request = ChatRequest(
        message: event.message,
        systemPrompt: event.systemPrompt ?? (state.chatMode?.systemPrompt),
        model: event.model,
        temperature: event.temperature,
        imageBase64: base64Image,
        imageMimeType: mimeType,
      );

      final hasImage = state.attachedImagePath != null;

      // Clear attachment after sending
      if (hasImage) {
        add(const DetachImage());
      }

      if (state.chatMode == ChatMode.imageGeneration) {
        // Handle Image Generation
        final imageRequest = ImageGenerationRequest(
          prompt: event.message,
          aspectRatio: "16:9", // Default for now
        );

        // Use repo to generate image
        // determining if conversation context matters for image gen? Usually not for this specific endpoint.
        // But the endpoint is independent.
        final response = await _repository.generateImage(imageRequest);

        if (response.success && response.data != null) {
          final chatResponse = response.data!;
          // Assistant message will likely contain the image URL in `response` field
          final assistantMessage = Message.assistantLocal(
            chatResponse.response,
          );

          emit(
            state.copyWith(
              messages: [...updatedMessages, assistantMessage],
              // currentConversationId: ... // Image gen might not return conversation ID or might not be chat based.
              // Assuming standalone interaction for now unless backend returns ID.
              isSending: false,
              lastAnimatedMessageId: assistantMessage.id,
            ),
          );
        } else {
          emit(
            state.copyWith(isSending: false, errorMessage: response.message),
          );
        }
      } else {
        // Standard Chat / Vision Chat Logic
        final response = hasImage
            ? (event.conversationId != null
                  ? await _repository.sendVisionMessageToConversation(
                      event.conversationId!,
                      request,
                    )
                  : await _repository.sendVisionMessage(request))
            : (event.conversationId != null
                  ? await _repository.sendMessageToConversation(
                      event.conversationId!,
                      request,
                    )
                  : await _repository.sendMessage(request));

        if (response.success && response.data != null) {
          final chatResponse = response.data!;
          final assistantMessage = Message.assistantLocal(
            chatResponse.response,
          );

          // Update conversation ID if this was a new conversation
          final newConversationId =
              chatResponse.conversationId ?? state.currentConversationId;

          emit(
            state.copyWith(
              messages: [...updatedMessages, assistantMessage],
              currentConversationId: newConversationId,
              isSending: false,
              lastAnimatedMessageId: assistantMessage.id,
            ),
          );

          // Reload conversations to get updated list
          add(const LoadConversations());
        } else {
          emit(
            state.copyWith(isSending: false, errorMessage: response.message),
          );
        }
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
}
