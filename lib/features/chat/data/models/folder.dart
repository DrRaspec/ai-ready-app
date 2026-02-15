class Folder {
  final String id;
  final String name;
  final String? userId;
  final String color;
  final String? parentId;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Folder({
    required this.id,
    required this.name,
    this.userId,
    required this.color,
    this.parentId,
    this.createdAt,
    this.updatedAt,
  });

  factory Folder.fromJson(Map<String, dynamic> json) {
    return Folder(
      id: (json['id'] as String?) ?? '',
      name: (json['name'] as String?) ?? '',
      userId: (json['user']?['id'] ?? json['ownerId'] ?? json['userId'])
          ?.toString(),
      color: (json['color'] as String?) ?? 'blue',
      parentId: json['parentId'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'].toString())
          : null,
    );
  }
}
