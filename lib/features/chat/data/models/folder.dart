class Folder {
  final String id;
  final String name;
  final String color;

  const Folder({required this.id, required this.name, required this.color});

  factory Folder.fromJson(Map<String, dynamic> json) {
    return Folder(
      id: json['id'] as String,
      name: json['name'] as String,
      color: json['color'] as String,
    );
  }
}
