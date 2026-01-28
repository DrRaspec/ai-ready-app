/// Request model for sending a chat message.
class ChatRequest {
  final String message;
  final String? systemPrompt;
  final String? imageBase64;
  final String? imageUrl;
  final String? imageMimeType;
  final String? model;
  final double? temperature;
  final String? modeHint;
  final String? conversationId;
  final bool? forceTextChat;

  const ChatRequest({
    required this.message,
    this.systemPrompt,
    this.imageBase64,
    this.imageUrl,
    this.imageMimeType,
    this.model,
    this.temperature,
    this.modeHint,
    this.conversationId,
    this.forceTextChat,
  });

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{'message': message};
    if (systemPrompt != null) map['systemPrompt'] = systemPrompt;
    if (imageBase64 != null) map['imageBase64'] = imageBase64;
    if (imageUrl != null) map['imageUrl'] = imageUrl;
    if (imageMimeType != null) map['imageMimeType'] = imageMimeType;
    if (model != null) map['model'] = model;
    if (temperature != null) map['temperature'] = temperature;
    if (modeHint != null) map['modeHint'] = modeHint;
    // Note: conversationId is passed in URL path, not body
    if (forceTextChat != null) map['forceTextChat'] = forceTextChat;
    return map;
  }
}
