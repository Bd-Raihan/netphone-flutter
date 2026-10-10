class FaxNotificationModel {
  final int id;
  final int? faxId;
  final String title;
  final String message;
  final String? notificationType;
  final bool isRead;
  final DateTime? createdAt;

  const FaxNotificationModel({
    required this.id,
    required this.title,
    required this.message,
    required this.isRead,
    this.faxId,
    this.notificationType,
    this.createdAt,
  });

  factory FaxNotificationModel.fromJson(Map<String, dynamic> json) {
    return FaxNotificationModel(
      id: _toInt(json['id']) ?? 0,
      faxId: _toInt(json['fax_id']),
      title: json['title']?.toString() ?? '',
      message: json['message']?.toString() ?? '',
      notificationType: json['notification_type']?.toString(),
      isRead: _toBool(json['is_read']),
      createdAt: json['created_at'] == null
          ? null
          : DateTime.tryParse(json['created_at'].toString()),
    );
  }

  static int? _toInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    return int.tryParse(value.toString());
  }

  static bool _toBool(dynamic value) {
    if (value is bool) return value;
    if (value is int) return value == 1;

    final text = value?.toString().toLowerCase();
    return text == 'true' || text == '1';
  }
}
