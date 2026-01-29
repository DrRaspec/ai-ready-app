/// Response model from chat API.
class ChatResponse {
  final String? conversationId;
  final String response;
  final String? imageUrl;
  final String? model;
  final int? promptTokens;
  final int? completionTokens;
  final int? totalTokens;
  final String? detectedIntent;
  final List<String>? suggestedReplies;

  const ChatResponse({
    this.conversationId,
    required this.response,
    this.imageUrl,
    this.model,
    this.promptTokens,
    this.completionTokens,
    this.totalTokens,
    this.detectedIntent,
    this.suggestedReplies,
  });

  factory ChatResponse.fromJson(Map<String, dynamic> json) => ChatResponse(
    conversationId: json['conversationId'] as String?,
    response: json['response'] as String? ?? '',
    imageUrl: json['imageUrl'] as String?,
    model: json['model'] as String?,
    promptTokens: json['promptTokens'] as int?,
    completionTokens: json['completionTokens'] as int?,
    totalTokens: json['totalTokens'] as int?,
    detectedIntent: json['detectedIntent'] as String?,
    suggestedReplies: (json['suggestedReplies'] as List<dynamic>?)
        ?.map((e) => e as String)
        .toList(),
  );
}
