import 'package:equatable/equatable.dart';

class VoiceChatResponse extends Equatable {
  final String userText;
  final String aiText;
  final String audioBase64;
  final String? conversationId;

  const VoiceChatResponse({
    required this.userText,
    required this.aiText,
    required this.audioBase64,
    this.conversationId,
  });

  factory VoiceChatResponse.fromJson(Map<String, dynamic> json) {
    return VoiceChatResponse(
      userText: json['userText'] as String,
      aiText: json['aiText'] as String,
      audioBase64: json['audioBase64'] as String,
      conversationId: json['conversationId'] as String?,
    );
  }

  @override
  List<Object?> get props => [userText, aiText, audioBase64, conversationId];
}
