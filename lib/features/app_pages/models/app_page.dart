class AppPage {
  final int id;
  final String slug;
  final String title;
  final String content;
  final String language;
  final String updatedAt;

  AppPage({
    required this.id,
    required this.slug,
    required this.title,
    required this.content,
    required this.language,
    required this.updatedAt,
  });

  factory AppPage.fromJson(Map<String, dynamic> json) {
    return AppPage(
      id: json['id'] ?? 0,
      slug: json['slug'] ?? '',
      title: json['title'] ?? '',
      content: json['content'] ?? '',
      language: json['language'] ?? 'en',
      updatedAt: json['updated_at']?.toString() ?? '',
    );
  }
}
