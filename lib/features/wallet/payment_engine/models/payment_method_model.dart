class PaymentMethodModel {
  final int id;

  final String provider;
  final String asset;
  final String network;
  final String displayName;

  final String? depositAddress;
  final String? destinationTag;

  final double minimumAmountUsd;
  final double maximumAmountUsd;

  final int requiredConfirmations;
  final int displayOrder;

  final bool isEnabled;
  final bool isPrimary;

  final Map<String, dynamic> settings;

  const PaymentMethodModel({
    required this.id,
    required this.provider,
    required this.asset,
    required this.network,
    required this.displayName,
    required this.depositAddress,
    required this.destinationTag,
    required this.minimumAmountUsd,
    required this.maximumAmountUsd,
    required this.requiredConfirmations,
    required this.displayOrder,
    required this.isEnabled,
    required this.isPrimary,
    required this.settings,
  });

  factory PaymentMethodModel.fromJson(Map<String, dynamic> json) {
    return PaymentMethodModel(
      id: _parseInt(json['id']),
      provider: _parseString(json['provider']),
      asset: _parseString(json['asset']),
      network: _parseString(json['network']),
      displayName: _parseString(json['display_name'] ?? json['displayName']),
      depositAddress: _parseNullableString(
        json['deposit_address'] ?? json['depositAddress'] ?? json['address'],
      ),
      destinationTag: _parseNullableString(
        json['destination_tag'] ?? json['destinationTag'],
      ),
      minimumAmountUsd: _parseDouble(
        json['minimum_amount_usd'] ?? json['minimumAmountUsd'],
      ),
      maximumAmountUsd: _parseDouble(
        json['maximum_amount_usd'] ?? json['maximumAmountUsd'],
      ),
      requiredConfirmations: _parseInt(
        json['required_confirmations'] ?? json['requiredConfirmations'],
      ),
      displayOrder: _parseInt(json['display_order'] ?? json['displayOrder']),
      isEnabled: _parseBool(json['is_enabled'] ?? json['isEnabled']),
      isPrimary: _parseBool(json['is_primary'] ?? json['isPrimary']),
      settings: _parseMap(json['settings']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'provider': provider,
      'asset': asset,
      'network': network,
      'display_name': displayName,
      'deposit_address': depositAddress,
      'destination_tag': destinationTag,
      'minimum_amount_usd': minimumAmountUsd,
      'maximum_amount_usd': maximumAmountUsd,
      'required_confirmations': requiredConfirmations,
      'display_order': displayOrder,
      'is_enabled': isEnabled,
      'is_primary': isPrimary,
      'settings': settings,
    };
  }

  PaymentMethodModel copyWith({
    int? id,
    String? provider,
    String? asset,
    String? network,
    String? displayName,
    String? depositAddress,
    String? destinationTag,
    double? minimumAmountUsd,
    double? maximumAmountUsd,
    int? requiredConfirmations,
    int? displayOrder,
    bool? isEnabled,
    bool? isPrimary,
    Map<String, dynamic>? settings,
  }) {
    return PaymentMethodModel(
      id: id ?? this.id,
      provider: provider ?? this.provider,
      asset: asset ?? this.asset,
      network: network ?? this.network,
      displayName: displayName ?? this.displayName,
      depositAddress: depositAddress ?? this.depositAddress,
      destinationTag: destinationTag ?? this.destinationTag,
      minimumAmountUsd: minimumAmountUsd ?? this.minimumAmountUsd,
      maximumAmountUsd: maximumAmountUsd ?? this.maximumAmountUsd,
      requiredConfirmations:
          requiredConfirmations ?? this.requiredConfirmations,
      displayOrder: displayOrder ?? this.displayOrder,
      isEnabled: isEnabled ?? this.isEnabled,
      isPrimary: isPrimary ?? this.isPrimary,
      settings: settings ?? this.settings,
    );
  }

  bool get hasDepositAddress {
    return depositAddress != null && depositAddress!.trim().isNotEmpty;
  }

  bool get requiresTransactionHash {
    return _parseBool(
      settings['tx_hash_required'] ?? settings['transaction_hash_required'],
    );
  }

  bool get requiresTransactionId {
    return _parseBool(settings['transaction_id_required']);
  }

  bool supportsAmount(double amountUsd) {
    if (amountUsd.isNaN || amountUsd.isInfinite) {
      return false;
    }
    return amountUsd >= minimumAmountUsd && amountUsd <= maximumAmountUsd;
  }

  String get assetNetworkLabel {
    final assetText = asset.trim();
    final networkText = network.trim();

    if (assetText.isEmpty && networkText.isEmpty) {
      return displayName;
    }

    if (networkText.isEmpty) {
      return assetText;
    }

    if (assetText.isEmpty) {
      return networkText;
    }

    return '$assetText • $networkText';
  }

  String get amountRangeLabel {
    return '\$${minimumAmountUsd.toStringAsFixed(2)}'
        ' - '
        '\$${maximumAmountUsd.toStringAsFixed(2)}';
  }

  static String _parseString(dynamic value) {
    return value?.toString().trim() ?? '';
  }

  static String? _parseNullableString(dynamic value) {
    if (value == null) {
      return null;
    }

    final text = value.toString().trim();

    return text.isEmpty ? null : text;
  }

  static int _parseInt(dynamic value) {
    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static double _parseDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(value?.toString() ?? '') ?? 0.0;
  }

  static bool _parseBool(dynamic value) {
    if (value is bool) {
      return value;
    }

    if (value is num) {
      return value != 0;
    }

    final normalized = value?.toString().trim().toLowerCase();

    return normalized == 'true' ||
        normalized == '1' ||
        normalized == 'yes' ||
        normalized == 'on' ||
        normalized == 't';
  }

  static Map<String, dynamic> _parseMap(dynamic value) {
    if (value is Map<String, dynamic>) {
      return Map<String, dynamic>.from(value);
    }

    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }

    return <String, dynamic>{};
  }
}
