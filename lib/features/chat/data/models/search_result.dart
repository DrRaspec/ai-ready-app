class SearchResult {
  final String title;
  final String url;
  final String snippet;

  const SearchResult({
    required this.title,
    required this.url,
    required this.snippet,
  });

  String get link => url; // Backward-compatible alias

  factory SearchResult.fromJson(Map<String, dynamic> json) => SearchResult(
    title: json['title'] as String? ?? '',
    url: (json['url'] ?? json['link']) as String? ?? '',
    snippet: json['snippet'] as String? ?? '',
  );
}
