class AdminContentPageModel {
  final int id;
  final String slug;
  final String title;
  final String content;
  final String language;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const AdminContentPageModel({
    required this.id,
    required this.slug,
    required this.title,
    required this.content,
    required this.language,
    required this.isActive,
    this.createdAt,
    this.updatedAt,
  });

  factory AdminContentPageModel.fromJson(Map<String, dynamic> json) {
    return AdminContentPageModel(
      id: _parseInt(json['id']),
      slug: json['slug']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      content: json['content']?.toString() ?? '',
      language: json['language']?.toString() ?? 'en',
      isActive: _parseBool(json['is_active']),
      createdAt: _parseDateTime(json['created_at']),
      updatedAt: _parseDateTime(json['updated_at']),
    );
  }

  AdminContentPageModel copyWith({
    int? id,
    String? slug,
    String? title,
    String? content,
    String? language,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AdminContentPageModel(
      id: id ?? this.id,
      slug: slug ?? this.slug,
      title: title ?? this.title,
      content: content ?? this.content,
      language: language ?? this.language,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toCreateJson() {
    return {
      'slug': slug.trim(),
      'title': title.trim(),
      'content': content.trim(),
      'language': language.trim().toLowerCase(),
      'is_active': isActive,
    };
  }

  Map<String, dynamic> toUpdateJson() {
    return {
      'slug': slug.trim(),
      'title': title.trim(),
      'content': content.trim(),
      'language': language.trim().toLowerCase(),
      'is_active': isActive,
    };
  }

  static int _parseInt(dynamic value) {
    if (value is int) {
      return value;
    }

    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static bool _parseBool(dynamic value) {
    if (value is bool) {
      return value;
    }

    final normalized = value?.toString().toLowerCase();

    return normalized == 'true' || normalized == '1' || normalized == 't';
  }

  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) {
      return null;
    }

    return DateTime.tryParse(value.toString());
  }
}
