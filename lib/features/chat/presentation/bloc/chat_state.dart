import 'package:equatable/equatable.dart';
import 'package:ai_chat_bot/features/chat/data/models/conversation.dart';
import 'package:ai_chat_bot/features/chat/data/models/message.dart';
import 'package:ai_chat_bot/features/chat/data/models/usage_summary.dart';

enum ChatStatus { initial, loading, success, failure }

class ChatState extends Equatable {
  final ChatStatus status;
  final List<Conversation> conversations;
  final String? currentConversationId;
  final List<Message> messages;
  final bool isSending;
  final UsageSummary? usage;
  final String? errorMessage;

  // Media & Modes
  final String? attachedImagePath;
  final dynamic chatMode; // ChatMode enum

  const ChatState({
    this.status = ChatStatus.initial,
    this.conversations = const [],
    this.currentConversationId,
    this.messages = const [],
    this.isSending = false,
    this.usage,
    this.errorMessage,
    this.attachedImagePath,
    this.chatMode,
  });

  bool get isLoading => status == ChatStatus.loading;
  bool get hasConversation => currentConversationId != null;

  Conversation? get currentConversation {
    if (currentConversationId == null) return null;
    try {
      return conversations.firstWhere((c) => c.id == currentConversationId);
    } catch (_) {
      return null;
    }
  }

  ChatState copyWith({
    ChatStatus? status,
    List<Conversation>? conversations,
    String? currentConversationId,
    bool clearCurrentConversation = false,
    List<Message>? messages,
    bool? isSending,
    UsageSummary? usage,
    String? errorMessage,
    bool clearError = false,
    String? attachedImagePath,
    bool clearAttachedImage = false,
    dynamic chatMode,
  }) {
    return ChatState(
      status: status ?? this.status,
      conversations: conversations ?? this.conversations,
      currentConversationId: clearCurrentConversation
          ? null
          : (currentConversationId ?? this.currentConversationId),
      messages: messages ?? this.messages,
      isSending: isSending ?? this.isSending,
      usage: usage ?? this.usage,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      attachedImagePath: clearAttachedImage
          ? null
          : (attachedImagePath ?? this.attachedImagePath),
      chatMode: chatMode ?? this.chatMode,
    );
  }

  @override
  List<Object?> get props => [
    status,
    conversations,
    currentConversationId,
    messages,
    isSending,
    usage,
    errorMessage,
    attachedImagePath,
    chatMode,
  ];
}
