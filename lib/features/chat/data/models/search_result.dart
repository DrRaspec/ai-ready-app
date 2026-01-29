class SearchResult {
  final String title;
  final String link;
  final String snippet;

  const SearchResult({
    required this.title,
    required this.link,
    required this.snippet,
  });

  factory SearchResult.fromJson(Map<String, dynamic> json) => SearchResult(
    title: json['title'] as String? ?? '',
    link: json['link'] as String? ?? '',
    snippet: json['snippet'] as String? ?? '',
  );
}
