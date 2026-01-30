class Folder {
  final String id;
  final String name;
  final String color;
  final String? parentId;

  const Folder({
    required this.id,
    required this.name,
    required this.color,
    this.parentId,
  });

  factory Folder.fromJson(Map<String, dynamic> json) {
    return Folder(
      id: (json['id'] as String?) ?? '',
      name: (json['name'] as String?) ?? '',
      color: (json['color'] as String?) ?? '',
      parentId: json['parentId'] as String?,
    );
  }
}
