/// Model representing a conversation.
class Conversation {
  final String id;
  final String? title;
  final int messageCount;
  final bool isPinned;
  final String? summary;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Conversation({
    required this.id,
    this.title,
    this.messageCount = 0,
    this.summary,
    this.createdAt,
    this.updatedAt,
    this.isPinned = false,
  });

  factory Conversation.fromJson(Map<String, dynamic> json) => Conversation(
    id: json['id'] as String,
    title: json['title'] as String?,
    messageCount: json['messageCount'] as int? ?? 0,
    summary: json['summary'] as String?,
    createdAt: json['createdAt'] != null
        ? DateTime.tryParse(json['createdAt'] as String)
        : null,
    updatedAt: json['updatedAt'] != null
        ? DateTime.tryParse(json['updatedAt'] as String)
        : null,
    isPinned: json['isPinned'] as bool? ?? false,
  );

  Conversation copyWith({
    String? id,
    String? title,
    int? messageCount,
    String? summary,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isPinned,
  }) {
    return Conversation(
      id: id ?? this.id,
      title: title ?? this.title,
      messageCount: messageCount ?? this.messageCount,
      summary: summary ?? this.summary,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isPinned: isPinned ?? this.isPinned,
    );
  }
}
