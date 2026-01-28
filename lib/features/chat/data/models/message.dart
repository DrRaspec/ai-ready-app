/// Model for a chat message.
class Message {
  final String id;
  final String role; // 'user' or 'assistant'
  final String content;
  final String? imageUrl;
  final String? localImagePath;
  final DateTime? createdAt;
  final String? detectedIntent;
  final List<String>? suggestedReplies;

  const Message({
    required this.id,
    required this.role,
    required this.content,
    this.imageUrl,
    this.localImagePath,
    this.createdAt,
    this.detectedIntent,
    this.suggestedReplies,
  });

  bool get isUser => role == 'user';
  bool get isAssistant => role == 'assistant';

  factory Message.fromJson(Map<String, dynamic> json) => Message(
    id: json['id'] as String,
    role: json['role'] as String,
    content: json['content'] as String? ?? '',
    imageUrl: json['imageUrl'] as String?,
    detectedIntent: json['detectedIntent'] as String?,
    suggestedReplies: (json['suggestedReplies'] as List<dynamic>?)
        ?.map((e) => e as String)
        .toList(),
    createdAt: json['createdAt'] != null
        ? DateTime.tryParse(json['createdAt'] as String)
        : null,
  );

  /// Create a local user message (before API response).
  factory Message.userLocal(String content, {String? imagePath}) => Message(
    id: DateTime.now().millisecondsSinceEpoch.toString(),
    role: 'user',
    content: content,
    localImagePath: imagePath,
    createdAt: DateTime.now(),
  );

  /// Create a local assistant message (for optimistic UI).
  factory Message.assistantLocal(
    String content, {
    String? imageUrl,
    String? detectedIntent,
    List<String>? suggestedReplies,
  }) => Message(
    id: DateTime.now().millisecondsSinceEpoch.toString(),
    role: 'assistant',
    content: content,
    imageUrl: imageUrl,
    detectedIntent: detectedIntent,
    suggestedReplies: suggestedReplies,
    createdAt: DateTime.now(),
  );

  Message copyWith({
    String? id,
    String? role,
    String? content,
    String? imageUrl,
    String? localImagePath,
    DateTime? createdAt,
    String? detectedIntent,
    List<String>? suggestedReplies,
  }) {
    return Message(
      id: id ?? this.id,
      role: role ?? this.role,
      content: content ?? this.content,
      imageUrl: imageUrl ?? this.imageUrl,
      localImagePath: localImagePath ?? this.localImagePath,
      createdAt: createdAt ?? this.createdAt,
      detectedIntent: detectedIntent ?? this.detectedIntent,
      suggestedReplies: suggestedReplies ?? this.suggestedReplies,
    );
  }
}
