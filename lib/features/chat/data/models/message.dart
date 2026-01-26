/// Model for a chat message.
class Message {
  final String id;
  final String role; // 'user' or 'assistant'
  final String content;
  final String? imageUrl;
  final DateTime? createdAt;

  const Message({
    required this.id,
    required this.role,
    required this.content,
    this.imageUrl,
    this.createdAt,
  });

  bool get isUser => role == 'user';
  bool get isAssistant => role == 'assistant';

  factory Message.fromJson(Map<String, dynamic> json) => Message(
    id: json['id'] as String,
    role: json['role'] as String,
    content: json['content'] as String? ?? '',
    imageUrl: json['imageUrl'] as String?,
    createdAt: json['createdAt'] != null
        ? DateTime.tryParse(json['createdAt'] as String)
        : null,
  );

  /// Create a local user message (before API response).
  factory Message.userLocal(String content) => Message(
    id: DateTime.now().millisecondsSinceEpoch.toString(),
    role: 'user',
    content: content,
    createdAt: DateTime.now(),
  );

  /// Create a local assistant message (for optimistic UI).
  factory Message.assistantLocal(String content) => Message(
    id: DateTime.now().millisecondsSinceEpoch.toString(),
    role: 'assistant',
    content: content,
    createdAt: DateTime.now(),
  );

  Message copyWith({
    String? id,
    String? role,
    String? content,
    String? imageUrl,
    DateTime? createdAt,
  }) {
    return Message(
      id: id ?? this.id,
      role: role ?? this.role,
      content: content ?? this.content,
      imageUrl: imageUrl ?? this.imageUrl,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
