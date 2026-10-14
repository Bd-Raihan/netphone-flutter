class FaxModel {
  final Map<String, dynamic>? billing;
  final int id;
  final String direction;
  final String? fromNumber;
  final String? toNumber;
  final String status;
  final String? senderName;
  final String? fileName;
  final int? pages;
  final String? failureReason;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const FaxModel({
    required this.id,
    this.billing,
    required this.direction,
    required this.status,
    this.fromNumber,
    this.toNumber,
    this.senderName,
    this.fileName,
    this.pages,
    this.failureReason,
    this.createdAt,
    this.updatedAt,
  });

  factory FaxModel.fromJson(Map<String, dynamic> json) {
    return FaxModel(
      id: _toInt(json['id']) ?? 0,
      billing: json['billing'] is Map ? Map<String, dynamic>.from(json['billing'] as Map) : null,
      direction: json['direction']?.toString() ?? '',
      fromNumber: json['from_number']?.toString(),
      toNumber: json['to_number']?.toString(),
      status: json['status']?.toString() ?? 'unknown',
      senderName: json['sender_name']?.toString(),
      fileName: json['file_name']?.toString(),
      pages: _toInt(json['pages']),
      failureReason: json['failure_reason']?.toString(),
      createdAt: _toDateTime(json['created_at']),
      updatedAt: _toDateTime(json['updated_at']),
    );
  }

  static int? _toInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    return int.tryParse(value.toString());
  }

  static DateTime? _toDateTime(dynamic value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString());
  }
}
