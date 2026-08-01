/// ==========================================================
/// admin_country_pricing_model.dart
///
/// কাজ:
/// - Backend Country Pricing response parse করা
/// - Auto Markup / Manual Rate mode রাখা
/// - Provider cost, final rate ও profit information রাখা
/// ==========================================================

enum CountryPricingMode { autoMarkup, manualRate }

extension CountryPricingModeValue on CountryPricingMode {
  String get apiValue {
    switch (this) {
      case CountryPricingMode.autoMarkup:
        return 'auto_markup';

      case CountryPricingMode.manualRate:
        return 'manual_rate';
    }
  }

  String get displayName {
    switch (this) {
      case CountryPricingMode.autoMarkup:
        return 'Auto Markup';

      case CountryPricingMode.manualRate:
        return 'Manual Rate';
    }
  }

  static CountryPricingMode fromApiValue(dynamic value) {
    final normalized = value?.toString().trim().toLowerCase();

    if (normalized == 'manual_rate') {
      return CountryPricingMode.manualRate;
    }

    return CountryPricingMode.autoMarkup;
  }
}

class AdminCountryPricingItem {
  final int? routeId;
  final String routeCode;
  final String routeName;

  final String countryCode;
  final String countryName;
  final String prefix;

  final String providerCode;
  final String providerName;
  final String providerPlanCode;

  final int? providerId;
  final int? providerPlanId;
  final int? providerRateId;
  final int? routeProviderId;

  final double rawProviderRateUsdPerMin;
  final double discountedProviderRateUsdPerMin;
  final double platformFeeUsdPerMin;
  final double providerCostUsdPerMin;

  final int billingIncrementSeconds;
  final int minimumDurationSeconds;
  final double connectionFeeUsd;
  final int destinationRateCount;

  final CountryPricingMode pricingMode;
  final bool manualOverride;

  final double markupPercent;
  final double? manualSellRateUsdPerMin;
  final double finalSellRateUsdPerMin;

  final double minProfitUsdPerMin;
  final double profitUsdPerMin;
  final double effectiveMarkupPercent;
  final double profitMarginPercent;

  final bool isActive;
  final bool publishRate;

  final String? note;
  final DateTime? updatedAt;
  final int? updatedBy;
  final String? updatedByPhone;

  const AdminCountryPricingItem({
    required this.routeId,
    required this.routeCode,
    required this.routeName,
    required this.countryCode,
    required this.countryName,
    required this.prefix,
    required this.providerCode,
    required this.providerName,
    required this.providerPlanCode,
    required this.providerId,
    required this.providerPlanId,
    required this.providerRateId,
    required this.routeProviderId,
    required this.rawProviderRateUsdPerMin,
    required this.discountedProviderRateUsdPerMin,
    required this.platformFeeUsdPerMin,
    required this.providerCostUsdPerMin,
    required this.billingIncrementSeconds,
    required this.minimumDurationSeconds,
    required this.connectionFeeUsd,
    required this.destinationRateCount,
    required this.pricingMode,
    required this.manualOverride,
    required this.markupPercent,
    required this.manualSellRateUsdPerMin,
    required this.finalSellRateUsdPerMin,
    required this.minProfitUsdPerMin,
    required this.profitUsdPerMin,
    required this.effectiveMarkupPercent,
    required this.profitMarginPercent,
    required this.isActive,
    required this.publishRate,
    required this.note,
    required this.updatedAt,
    required this.updatedBy,
    required this.updatedByPhone,
  });

  factory AdminCountryPricingItem.fromJson(Map<String, dynamic> json) {
    return AdminCountryPricingItem(
      routeId: _toNullableInt(json['route_id']),

      routeCode: json['route_code']?.toString() ?? '',

      routeName: json['route_name']?.toString() ?? '',

      countryCode: json['country_code']?.toString() ?? 'UNKNOWN',

      countryName: json['country_name']?.toString() ?? 'Unknown',

      prefix: json['prefix']?.toString() ?? '',

      providerCode: json['provider_code']?.toString() ?? '',

      providerName: json['provider_name']?.toString() ?? '',

      providerPlanCode: json['provider_plan_code']?.toString() ?? '',

      providerId: _toNullableInt(json['provider_id']),

      providerPlanId: _toNullableInt(json['provider_plan_id']),

      providerRateId: _toNullableInt(json['provider_rate_id']),

      routeProviderId: _toNullableInt(json['route_provider_id']),

      rawProviderRateUsdPerMin: _toDouble(
        json['raw_provider_rate_usd_per_min'],
      ),

      discountedProviderRateUsdPerMin: _toDouble(
        json['discounted_provider_rate_usd_per_min'],
      ),

      platformFeeUsdPerMin: _toDouble(json['platform_fee_usd_per_min']),

      providerCostUsdPerMin: _toDouble(
        json['provider_cost_usd_per_min'] ??
            json['total_provider_cost_usd_per_min'],
      ),

      billingIncrementSeconds: _toInt(
        json['billing_increment_seconds'],
        fallback: 60,
      ),

      minimumDurationSeconds: _toInt(
        json['minimum_duration_seconds'],
        fallback: 60,
      ),

      connectionFeeUsd: _toDouble(json['connection_fee_usd']),

      destinationRateCount: _toInt(json['destination_rate_count']),

      pricingMode: CountryPricingModeValue.fromApiValue(json['pricing_mode']),

      manualOverride: _toBool(json['manual_override']),

      markupPercent: _toDouble(json['markup_percent']),

      manualSellRateUsdPerMin: _toNullableDouble(
        json['manual_sell_rate_usd_per_min'],
      ),

      finalSellRateUsdPerMin: _toDouble(json['final_sell_rate_usd_per_min']),

      minProfitUsdPerMin: _toDouble(json['min_profit_usd_per_min']),

      profitUsdPerMin: _toDouble(json['profit_usd_per_min']),

      effectiveMarkupPercent: _toDouble(json['effective_markup_percent']),

      profitMarginPercent: _toDouble(json['profit_margin_percent']),

      isActive: _toBool(json['is_active'], fallback: true),

      publishRate: _toBool(json['publish_rate'], fallback: true),

      note: json['manual_rate_note']?.toString(),

      updatedAt: DateTime.tryParse(
        json['manual_rate_updated_at']?.toString() ?? '',
      ),

      updatedBy: _toNullableInt(json['manual_rate_updated_by']),

      updatedByPhone: json['updated_by_phone']?.toString(),
    );
  }

  String get normalizedPrefix {
    if (prefix.startsWith('+')) {
      return prefix;
    }

    return '+$prefix';
  }

  bool get hasProviderCost => providerCostUsdPerMin > 0;

  bool get isManualMode => pricingMode == CountryPricingMode.manualRate;
}

class AdminCountryPricingListResult {
  final int total;
  final List<AdminCountryPricingItem> items;

  const AdminCountryPricingListResult({
    required this.total,
    required this.items,
  });

  factory AdminCountryPricingListResult.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'];

    final items = rawItems is List
        ? rawItems
              .whereType<Map>()
              .map(
                (item) => AdminCountryPricingItem.fromJson(
                  Map<String, dynamic>.from(item),
                ),
              )
              .toList()
        : <AdminCountryPricingItem>[];

    return AdminCountryPricingListResult(
      total: _toInt(json['total'], fallback: items.length),
      items: items,
    );
  }
}

class CountryPricingUpdateRequest {
  final CountryPricingMode pricingMode;

  final String? countryCode;

  final double? markupPercent;

  final double? manualSellRateUsdPerMin;

  final bool? isActive;

  final String? note;

  const CountryPricingUpdateRequest({
    required this.pricingMode,
    this.countryCode,
    this.markupPercent,
    this.manualSellRateUsdPerMin,
    this.isActive,
    this.note,
  });

  factory CountryPricingUpdateRequest.autoMarkup({
    required double markupPercent,
    String? countryCode,
    bool? isActive,
    String? note,
  }) {
    return CountryPricingUpdateRequest(
      pricingMode: CountryPricingMode.autoMarkup,

      countryCode: countryCode,

      markupPercent: markupPercent,

      manualSellRateUsdPerMin: null,

      isActive: isActive,

      note: note,
    );
  }

  factory CountryPricingUpdateRequest.manualRate({
    required double manualSellRateUsdPerMin,
    String? countryCode,
    bool? isActive,
    String? note,
  }) {
    return CountryPricingUpdateRequest(
      pricingMode: CountryPricingMode.manualRate,

      countryCode: countryCode,

      markupPercent: null,

      manualSellRateUsdPerMin: manualSellRateUsdPerMin,

      isActive: isActive,

      note: note,
    );
  }

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{'pricing_mode': pricingMode.apiValue};

    if (countryCode != null && countryCode!.trim().isNotEmpty) {
      data['country_code'] = countryCode!.trim().toUpperCase();
    }

    if (pricingMode == CountryPricingMode.autoMarkup) {
      data['markup_percent'] = markupPercent;
    }

    if (pricingMode == CountryPricingMode.manualRate) {
      data['manual_sell_rate_usd_per_min'] = manualSellRateUsdPerMin;
    }

    if (isActive != null) {
      data['is_active'] = isActive;
    }

    if (note != null && note!.trim().isNotEmpty) {
      data['note'] = note!.trim();
    }

    return data;
  }
}

int _toInt(dynamic value, {int fallback = 0}) {
  if (value is int) {
    return value;
  }

  if (value is num) {
    return value.toInt();
  }

  return int.tryParse(value?.toString() ?? '') ?? fallback;
}

int? _toNullableInt(dynamic value) {
  if (value == null) {
    return null;
  }

  if (value is int) {
    return value;
  }

  if (value is num) {
    return value.toInt();
  }

  return int.tryParse(value.toString());
}

double _toDouble(dynamic value, {double fallback = 0}) {
  if (value is num) {
    return value.toDouble();
  }

  final parsed = double.tryParse(value?.toString() ?? '');

  if (parsed == null || !parsed.isFinite) {
    return fallback;
  }

  return parsed;
}

double? _toNullableDouble(dynamic value) {
  if (value == null) {
    return null;
  }

  if (value is num) {
    return value.toDouble();
  }

  final parsed = double.tryParse(value.toString());

  if (parsed == null || !parsed.isFinite) {
    return null;
  }

  return parsed;
}

bool _toBool(dynamic value, {bool fallback = false}) {
  if (value is bool) {
    return value;
  }

  if (value is num) {
    return value != 0;
  }

  final normalized = value?.toString().trim().toLowerCase();

  if (normalized == 'true' || normalized == '1' || normalized == 'yes') {
    return true;
  }

  if (normalized == 'false' || normalized == '0' || normalized == 'no') {
    return false;
  }

  return fallback;
}
