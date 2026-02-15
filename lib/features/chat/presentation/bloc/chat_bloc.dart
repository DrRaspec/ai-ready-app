import 'dart:convert';
import 'dart:io';

import 'package:mime/mime.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:bloc/bloc.dart';
import 'package:ai_chat_bot/core/errors/api_exception.dart';
import 'package:shadow_log/shadow_log.dart';
import 'package:ai_chat_bot/features/chat/data/chat_repository.dart';
import 'package:ai_chat_bot/features/chat/data/models/chat_request.dart';
import 'package:ai_chat_bot/features/chat/data/models/conversation.dart';
import 'package:ai_chat_bot/features/chat/data/models/image_generation_request.dart';
import 'package:ai_chat_bot/features/chat/data/models/message.dart';
import 'package:ai_chat_bot/core/network/models/api_response.dart';
import 'package:ai_chat_bot/features/chat/data/models/chat_response.dart';
import 'package:ai_chat_bot/features/chat/data/models/chat_mode.dart';
import 'chat_event.dart';
import 'chat_state.dart';

class ChatBloc extends Bloc<ChatEvent, ChatState> {
  final ChatRepository _repository;

  ChatBloc(ChatRepository repository)
    : _repository = repository,
      super(const ChatState()) {
    on<LoadConversations>(_onLoadConversations);
    on<SelectConversation>(_onSelectConversation);
    on<RefreshMessages>(_onRefreshMessages);
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
    on<SelectFolder>(_onSelectFolder);
    on<MoveToFolder>(_onMoveToFolder);
    on<PerformWebSearch>(_onPerformWebSearch);
    on<SearchConversations>(_onSearchConversations);
  }

  Future<void> _onSearchConversations(
    SearchConversations event,
    Emitter<ChatState> emit,
  ) async {
    final query = event.query.trim();
    emit(state.copyWith(searchQuery: event.query, clearError: true));

    if (query.isEmpty) {
      add(const LoadConversations(page: 0));
      return;
    }

    try {
      final response = await _repository.searchConversations(query, page: 0);
      if (response.success && response.data != null) {
        emit(
          state.copyWith(
            conversations: response.data!,
            hasMoreConversations: response.data!.length >= 20,
            conversationPage: 0,
          ),
        );
      } else {
        emit(state.copyWith(errorMessage: response.message));
      }
    } on ApiException catch (e) {
      emit(state.copyWith(errorMessage: e.message));
    }
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

  void _onSelectFolder(SelectFolder event, Emitter<ChatState> emit) {
    emit(
      state.copyWith(
        currentFolderId: event.folderId,
        clearCurrentFolderId: event.folderId == null,
        conversations: [],
        hasMoreConversations: true,
        conversationPage: 0,
        isConversationsLoading: false, // Ensure we are ready to load
      ),
    );
    add(const LoadConversations(page: 0));
  }

  Future<void> _onLoadConversations(
    LoadConversations event,
    Emitter<ChatState> emit,
  ) async {
    // If we're already loading or strict refresh isn't requested and we don't have more, return.
    final isRefresh = event.page == 0;
    if (!isRefresh && !state.hasMoreConversations) return;
    if (state.isConversationsLoading) return;

    emit(state.copyWith(isConversationsLoading: true, clearError: true));

    try {
      final response = await _repository.getConversations(
        page: event.page,
        size: event.size,
        folderId: state.currentFolderId, // Use state's current folder
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

  Future<void> _onRefreshMessages(
    RefreshMessages event,
    Emitter<ChatState> emit,
  ) async {
    try {
      final response = await _repository.getConversationMessages(
        event.conversationId,
      );

      if (response.success && response.data != null) {
        emit(state.copyWith(messages: response.data!));
      }
    } on ApiException catch (e) {
      ShadowLog.e('Silent refresh failed: ${e.message}');
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
      if (hasImage) {
        // Clear attachment immediately to reflect UI state
        add(const DetachImage());
      }

      // Check Mode and Model
      String modeHint = 'CHAT';
      if (state.chatMode == ChatMode.imageGeneration) {
        modeHint = 'IMAGE_GEN';
      } else if (state.chatMode == ChatMode.imageEditing) {
        modeHint = 'IMAGE_EDIT';
      }

      final request = ChatRequest(
        message: event.message,
        systemPrompt: event.systemPrompt ?? (state.chatMode?.systemPrompt),
        model:
            event.model ??
            (state.chatMode == ChatMode.coding
                ? 'llama-3.1-8b-instant'
                : null), // Example fallback
        temperature: event.temperature,
        imageBase64: base64Image,
        imageMimeType: mimeType,
        modeHint: modeHint,
        conversationId: state.currentConversationId,
        folderId: state.currentFolderId,
        forceTextChat: modeHint == 'CHAT',
      );

      // --- STREAMING LOGIC ---
      if (event.useStream && modeHint == 'CHAT') {
        // Don't stream images
        // 1. Create a placeholder assistant message
        final tempAssistantId =
            'stream_${DateTime.now().millisecondsSinceEpoch}';
        var assistantMessage = Message.assistantLocal(
          '', // start empty
          id: tempAssistantId,
        );

        var currentMessages = [...updatedMessages, assistantMessage];
        emit(state.copyWith(messages: currentMessages));

        final stream = _repository.streamSmartMessage(request);

        await emit.forEach(
          stream,
          onData: (String chunk) {
            // Update the last message (assistant) with new chunk
            final currentContent = assistantMessage.content + chunk;

            assistantMessage = assistantMessage.copyWith(
              content: currentContent,
            );

            // Re-construct list with updated message
            // Need to find by ID in case user sent another message (rare in sync, but good practice)
            // or just replace the last one since we are in a bloc handler (sequential?)
            // actually emit.forEach keeps the handler active.
            // We can safely assume it's the last one for this flow

            // Note for efficient updates: finding index
            final index = currentMessages.indexWhere(
              (m) => m.id == tempAssistantId,
            );
            if (index != -1) {
              currentMessages = List.from(currentMessages);
              currentMessages[index] = assistantMessage;
              return state.copyWith(messages: currentMessages);
            }
            return state;
          },
          onError: (e, stackTrace) {
            ShadowLog.e('Streaming error: $e');
            return state.copyWith(
              errorMessage: 'Streaming failed: ${e.toString()}',
            );
          },
        );

        // Finalize
        emit(state.copyWith(isSending: false));
        // Note: You might want to reload conversation to get the real ID from server if needed
        // But for now, local ID works for display.
        // Ideally, we fetch the conversation again to sync IDs.
        if (state.currentConversationId != null) {
          // Passive refresh to get real message IDs
          add(RefreshMessages(state.currentConversationId!));
        }
      } else {
        // --- STANDARD FUTURE LOGIC ---
        final ApiResponse<ChatResponse> response;
        if (modeHint == 'IMAGE_EDIT' && state.attachedImagePath != null) {
          // Use the dedicated edit image endpoint
          response = await _repository.editImage(
            prompt: event.message,
            imagePath: state.attachedImagePath!,
          );
        } else if (modeHint == 'IMAGE_GEN') {
          response = await _repository.generateImage(
            ImageGenerationRequest(prompt: event.message),
          );
        } else {
          response = await _repository.sendSmartMessage(request);
        }

        if (response.success && response.data != null) {
          final chatResponse = response.data!;
          ShadowLog.d('AI Model Used: ${chatResponse.model ?? "Unknown"}');

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

          emit(
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
            add(const LoadConversations());
          }
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

  Future<void> _onMoveToFolder(
    MoveToFolder event,
    Emitter<ChatState> emit,
  ) async {
    try {
      final response = await _repository.moveConversationToFolder(
        event.conversationId,
        event.folderId,
      );

      if (response.success) {
        // Update local conversation
        final updatedConversations = state.conversations.map((c) {
          if (c.id == event.conversationId) {
            return c.copyWith(folderId: event.folderId);
          }
          return c;
        }).toList();

        // If we are currently filtering by a folder and the conversation moved out of it (or into another)
        // we might want to refresh. But for now, simple local update is enough if we filter on backend.
        // Actually, if we filter on backend, moving a conversation OUT of the current folder means it should disappear from the list.

        List<Conversation> finalConversations = updatedConversations;
        if (state.currentFolderId != null &&
            state.currentFolderId != event.folderId) {
          finalConversations = updatedConversations
              .where((c) => c.folderId == state.currentFolderId)
              .toList();
        }

        emit(state.copyWith(conversations: finalConversations));
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
    ShadowLog.d(
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
        ShadowLog.d('Image: Compression returned null. Using original.');
        // Fallback to original if compression fails
        return await file.readAsBytes();
      }

      ShadowLog.d(
        'Image: Compressed Size = ${(result.length / 1024).toStringAsFixed(2)} KB',
      );
      return result;
    } catch (e) {
      ShadowLog.e('Image: Compression failed ($e).');

      // If original is > 4MB, do not send it as it will likely fail
      if (originalSize > 4 * 1024 * 1024) {
        throw ApiException(
          message: 'Image too large (rebuild app required)',
          status: 413,
        );
      }

      ShadowLog.w('Image: Fallback to original.');
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
      await _repository.rateFeedback(
        event.messageId,
        event.isPositive,
        feedbackText: event.feedbackText,
      );
      // Optionally show a snackbar or update message state locally to show feedback given
    } on ApiException catch (e) {
      // access context in UI to show error? or emit state error
      ShadowLog.e('Rate Message Failed: ${e.message}');
    }
  }

  Future<void> _onGetSummary(GetSummary event, Emitter<ChatState> emit) async {
    try {
      final response = await _repository.getSummary(event.conversationId);
      if (response.success) {
        // Show summary in a dialog or snippet in UI?
        ShadowLog.d('Summary: ${response.data}');
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
        ShadowLog.d('Search Results: ${response.data?.length}');
      }
    } on ApiException catch (e) {
      emit(state.copyWith(errorMessage: e.message));
    }
  }
}
