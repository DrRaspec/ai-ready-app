import 'package:bloc/bloc.dart';
import 'package:ai_chat_bot/core/errors/api_exception.dart';
import 'package:ai_chat_bot/features/chat/data/chat_repository.dart';
import 'package:ai_chat_bot/features/chat/data/models/chat_request.dart';
import 'package:ai_chat_bot/features/chat/data/models/message.dart';
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
  }

  Future<void> _onLoadConversations(
    LoadConversations event,
    Emitter<ChatState> emit,
  ) async {
    emit(state.copyWith(status: ChatStatus.loading, clearError: true));

    try {
      final response = await _repository.getConversations(
        page: event.page,
        size: event.size,
      );

      if (response.success && response.data != null) {
        emit(
          state.copyWith(
            status: ChatStatus.success,
            conversations: response.data!,
          ),
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
    final userMessage = Message.userLocal(event.message);
    final updatedMessages = [...state.messages, userMessage];

    emit(
      state.copyWith(
        messages: updatedMessages,
        isSending: true,
        clearError: true,
      ),
    );

    try {
      final request = ChatRequest(
        message: event.message,
        systemPrompt: event.systemPrompt,
        model: event.model,
        temperature: event.temperature,
      );

      final response = event.conversationId != null
          ? await _repository.sendMessageToConversation(
              event.conversationId!,
              request,
            )
          : await _repository.sendMessage(request);

      if (response.success && response.data != null) {
        final chatResponse = response.data!;
        final assistantMessage = Message.assistantLocal(chatResponse.response);

        // Update conversation ID if this was a new conversation
        final newConversationId =
            chatResponse.conversationId ?? state.currentConversationId;

        emit(
          state.copyWith(
            messages: [...updatedMessages, assistantMessage],
            currentConversationId: newConversationId,
            isSending: false,
          ),
        );

        // Reload conversations to get updated list
        add(const LoadConversations());
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
