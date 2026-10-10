// ============================================================
// 🇧🇩 ADMIN CALL ACTIVITY / CDR MODELS
//
// কাজ:
// - Backend Call Activity API response parse করা
// - Calling Engine / Wallet / Billing-এর সাথে কোনো সম্পর্ক নেই
// ============================================================

class AdminCallActivitySummary {
  final int totalCalls;
  final int answeredCalls;
  final int unansweredCalls;
  final int failedCalls;
  final int totalDurationSeconds;
  final int totalBilledMinutes;
  final int uniqueUsers;
  final int uniqueDestinationNumbers;

  const AdminCallActivitySummary({
    required this.totalCalls,
    required this.answeredCalls,
    required this.unansweredCalls,
    required this.failedCalls,
    required this.totalDurationSeconds,
    required this.totalBilledMinutes,
    required this.uniqueUsers,
    required this.uniqueDestinationNumbers,
  });

  factory AdminCallActivitySummary.fromJson(Map<String, dynamic> json) {
    int asInt(dynamic value) {
      return int.tryParse(value?.toString() ?? '0') ?? 0;
    }

    return AdminCallActivitySummary(
      totalCalls: asInt(json['total_calls']),
      answeredCalls: asInt(json['answered_calls']),
      unansweredCalls: asInt(json['unanswered_calls']),
      failedCalls: asInt(json['failed_calls']),
      totalDurationSeconds: asInt(json['total_duration_seconds']),
      totalBilledMinutes: asInt(json['total_billed_minutes']),
      uniqueUsers: asInt(json['unique_users']),
      uniqueDestinationNumbers: asInt(json['unique_destination_numbers']),
    );
  }

  static const empty = AdminCallActivitySummary(
    totalCalls: 0,
    answeredCalls: 0,
    unansweredCalls: 0,
    failedCalls: 0,
    totalDurationSeconds: 0,
    totalBilledMinutes: 0,
    uniqueUsers: 0,
    uniqueDestinationNumbers: 0,
  );
}

class AdminCallActivityItem {
  final int callId;
  final int userId;

  final String registeredNumber;
  final String originCountry;
  final String? originCountryCode;

  final String destinationNumber;
  final String destinationCountry;
  final String? destinationCountryCode;

  final DateTime? startedAt;
  final DateTime? answeredAt;
  final DateTime? endedAt;

  final int durationSeconds;
  final double durationMinutes;
  final int billedMinutes;

  final String status;
  final String providerStatus;
  final String provider;

  final String? providerPhoneNumber;

  final String? providerCallId;

  const AdminCallActivityItem({
    required this.callId,
    required this.userId,
    required this.registeredNumber,
    required this.originCountry,
    required this.originCountryCode,
    required this.destinationNumber,
    required this.destinationCountry,
    required this.destinationCountryCode,
    required this.startedAt,
    required this.answeredAt,
    required this.endedAt,
    required this.durationSeconds,
    required this.durationMinutes,
    required this.billedMinutes,
    required this.status,
    required this.providerStatus,
    required this.provider,
    required this.providerPhoneNumber,
    required this.providerCallId,
  });

  factory AdminCallActivityItem.fromJson(Map<String, dynamic> json) {
    int asInt(dynamic value) {
      return int.tryParse(value?.toString() ?? '0') ?? 0;
    }

    double asDouble(dynamic value) {
      return double.tryParse(value?.toString() ?? '0') ?? 0.0;
    }

    String asString(dynamic value) {
      final text = value?.toString().trim() ?? '';

      return text;
    }

    DateTime? asDate(dynamic value) {
      final text = value?.toString().trim() ?? '';

      if (text.isEmpty) {
        return null;
      }

      return DateTime.tryParse(text);
    }

    return AdminCallActivityItem(
      callId: asInt(json['call_id']),
      userId: asInt(json['user_id']),
      registeredNumber: asString(json['registered_number']),
      originCountry: asString(json['origin_country']),
      originCountryCode: asString(json['origin_country_code']).isEmpty
          ? null
          : asString(json['origin_country_code']),
      destinationNumber: asString(json['destination_number']),
      destinationCountry: asString(json['destination_country']),
      destinationCountryCode: asString(json['destination_country_code']).isEmpty
          ? null
          : asString(json['destination_country_code']),
      startedAt: asDate(json['started_at']),
      answeredAt: asDate(json['answered_at']),
      endedAt: asDate(json['ended_at']),
      durationSeconds: asInt(json['duration_seconds']),
      durationMinutes: asDouble(json['duration_minutes']),
      billedMinutes: asInt(json['billed_minutes']),
      status: asString(json['status']),
      providerStatus: asString(json['provider_status']),
      provider: asString(json['provider']),
      providerPhoneNumber: asString(json['provider_phone_number']).isEmpty
          ? null
          : asString(json['provider_phone_number']),
      providerCallId: asString(json['provider_call_id']).isEmpty
          ? null
          : asString(json['provider_call_id']),
    );
  }
}

class AdminCallActivityResponse {
  final AdminCallActivitySummary summary;
  final int total;
  final int limit;
  final int offset;
  final List<AdminCallActivityItem> calls;

  const AdminCallActivityResponse({
    required this.summary,
    required this.total,
    required this.limit,
    required this.offset,
    required this.calls,
  });

  factory AdminCallActivityResponse.fromJson(Map<String, dynamic> json) {
    final summaryRaw = json['summary'];

    final paginationRaw = json['pagination'];

    final callsRaw = json['calls'];

    final summary = summaryRaw is Map
        ? AdminCallActivitySummary.fromJson(
            Map<String, dynamic>.from(summaryRaw),
          )
        : AdminCallActivitySummary.empty;

    final pagination = paginationRaw is Map
        ? Map<String, dynamic>.from(paginationRaw)
        : <String, dynamic>{};

    final calls = <AdminCallActivityItem>[];

    if (callsRaw is List) {
      for (final item in callsRaw) {
        if (item is Map) {
          calls.add(
            AdminCallActivityItem.fromJson(Map<String, dynamic>.from(item)),
          );
        }
      }
    }

    return AdminCallActivityResponse(
      summary: summary,
      total: int.tryParse(pagination['total']?.toString() ?? '0') ?? 0,
      limit: int.tryParse(pagination['limit']?.toString() ?? '50') ?? 50,
      offset: int.tryParse(pagination['offset']?.toString() ?? '0') ?? 0,
      calls: calls,
    );
  }
}
