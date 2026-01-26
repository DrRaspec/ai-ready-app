import 'package:equatable/equatable.dart';

abstract class ChatEvent extends Equatable {
  const ChatEvent();

  @override
  List<Object?> get props => [];
}

/// Load list of conversations.
class LoadConversations extends ChatEvent {
  final int page;
  final int size;

  const LoadConversations({this.page = 0, this.size = 20});

  @override
  List<Object?> get props => [page, size];
}

/// Select a conversation to view messages.
class SelectConversation extends ChatEvent {
  final String conversationId;

  const SelectConversation(this.conversationId);

  @override
  List<Object?> get props => [conversationId];
}

/// Send a new message.
class SendMessage extends ChatEvent {
  final String message;
  final String? conversationId;
  final String? systemPrompt;
  final String? model;
  final double? temperature;

  const SendMessage({
    required this.message,
    this.conversationId,
    this.systemPrompt,
    this.model,
    this.temperature,
  });

  @override
  List<Object?> get props => [
    message,
    conversationId,
    systemPrompt,
    model,
    temperature,
  ];
}

/// Create a new conversation (clear current).
class NewConversation extends ChatEvent {
  const NewConversation();
}

/// Rename a conversation.
class RenameConversation extends ChatEvent {
  final String conversationId;
  final String newTitle;

  const RenameConversation(this.conversationId, this.newTitle);

  @override
  List<Object?> get props => [conversationId, newTitle];
}

/// Delete a conversation.
class DeleteConversation extends ChatEvent {
  final String conversationId;

  const DeleteConversation(this.conversationId);

  @override
  List<Object?> get props => [conversationId];
}

/// Load usage statistics.
class LoadUsage extends ChatEvent {
  const LoadUsage();
}

/// Attach an image (from photo_manager AssetEntity).
class AttachImage extends ChatEvent {
  final String path;

  const AttachImage(this.path);

  @override
  List<Object?> get props => [path];
}

class DetachImage extends ChatEvent {
  const DetachImage();
}

class SetChatMode extends ChatEvent {
  final dynamic mode; // Will be ChatMode
  const SetChatMode(this.mode);
  @override
  List<Object?> get props => [mode];
}

class VoiceMessageSent extends ChatEvent {
  final String path;
  final String? language;

  const VoiceMessageSent(this.path, {this.language});

  @override
  List<Object?> get props => [path, language];
}

class EditMessage extends ChatEvent {
  final String messageId;
  final String newContent;

  const EditMessage(this.messageId, this.newContent);

  @override
  List<Object?> get props => [messageId, newContent];
}
