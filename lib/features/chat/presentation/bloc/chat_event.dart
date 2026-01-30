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
  final String? folderId;

  const LoadConversations({this.page = 0, this.size = 20, this.folderId});

  @override
  List<Object?> get props => [page, size, folderId];
}

class SelectFolder extends ChatEvent {
  final String? folderId;

  const SelectFolder(this.folderId);

  @override
  List<Object?> get props => [folderId];
}

/// Select a conversation to view messages.
class SelectConversation extends ChatEvent {
  final String conversationId;

  const SelectConversation(this.conversationId);

  @override
  List<Object?> get props => [conversationId];
}

/// Refresh messages for current conversation without clearing UI.
class RefreshMessages extends ChatEvent {
  final String conversationId;

  const RefreshMessages(this.conversationId);

  @override
  List<Object?> get props => [conversationId];
}

class SearchConversations extends ChatEvent {
  final String query;
  const SearchConversations(this.query);
  @override
  List<Object?> get props => [query];
}

/// Send a new message.
class SendMessage extends ChatEvent {
  final String message;
  final String? conversationId;
  final String? systemPrompt;
  final String? model;
  final double? temperature;

  final bool useStream;

  const SendMessage({
    required this.message,
    this.conversationId,
    this.systemPrompt,
    this.model,
    this.temperature,
    this.useStream = true,
  });

  @override
  List<Object?> get props => [
    message,
    conversationId,
    systemPrompt,
    model,
    temperature,
    useStream,
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

class MoveToFolder extends ChatEvent {
  final String conversationId;
  final String? folderId;

  const MoveToFolder(this.conversationId, this.folderId);

  @override
  List<Object?> get props => [conversationId, folderId];
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

class StartStreaming extends ChatEvent {
  final String message;
  final String? conversationId;
  const StartStreaming(this.message, {this.conversationId});
  @override
  List<Object?> get props => [message, conversationId];
}

class RegenerateMessage extends ChatEvent {
  final String conversationId;
  const RegenerateMessage(this.conversationId);
  @override
  List<Object?> get props => [conversationId];
}

class RateMessage extends ChatEvent {
  final String messageId;
  final bool isPositive;
  const RateMessage(this.messageId, {required this.isPositive});
  @override
  List<Object?> get props => [messageId, isPositive];
}

class GetSummary extends ChatEvent {
  final String conversationId;
  const GetSummary(this.conversationId);
  @override
  List<Object?> get props => [conversationId];
}

class PerformWebSearch extends ChatEvent {
  final String query;
  const PerformWebSearch(this.query);
  @override
  List<Object?> get props => [query];
}

class EditMessage extends ChatEvent {
  final String messageId;
  final String newContent;

  const EditMessage(this.messageId, this.newContent);

  @override
  List<Object?> get props => [messageId, newContent];
}
