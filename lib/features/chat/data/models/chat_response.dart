/// Response model from chat API.
class ChatResponse {
  final String? conversationId;
  final String response;
  final String? model;
  final int? promptTokens;
  final int? completionTokens;
  final int? totalTokens;

  const ChatResponse({
    this.conversationId,
    required this.response,
    this.model,
    this.promptTokens,
    this.completionTokens,
    this.totalTokens,
  });

  factory ChatResponse.fromJson(Map<String, dynamic> json) => ChatResponse(
    conversationId: json['conversationId'] as String?,
    response: json['response'] as String? ?? '',
    model: json['model'] as String?,
    promptTokens: json['promptTokens'] as int?,
    completionTokens: json['completionTokens'] as int?,
    totalTokens: json['totalTokens'] as int?,
  );
}
