class CryptoHistoryItemModel {
  final int id;
  final int paymentOrderId;
  final int userId;

  final String provider;
  final String eventKey;
  final String eventType;
  final String orderStatus;

  final String? asset;
  final String? network;

  final double? cryptoAmount;
  final double usdAmount;
  final int amountMicroUsd;

  final String? txHash;
  final String? providerOrderId;
  final String? providerTransactionId;

  final int? confirmations;
  final int? requiredConfirmations;

  final String? fromAddress;
  final String? toAddress;

  final String verificationResult;
  final String? note;

  final Map<String, dynamic> rawPayload;

  final DateTime? createdAt;

  const CryptoHistoryItemModel({
    required this.id,
    required this.paymentOrderId,
    required this.userId,
    required this.provider,
    required this.eventKey,
    required this.eventType,
    required this.orderStatus,
    required this.asset,
    required this.network,
    required this.cryptoAmount,
    required this.usdAmount,
    required this.amountMicroUsd,
    required this.txHash,
    required this.providerOrderId,
    required this.providerTransactionId,
    required this.confirmations,
    required this.requiredConfirmations,
    required this.fromAddress,
    required this.toAddress,
    required this.verificationResult,
    required this.note,
    required this.rawPayload,
    required this.createdAt,
  });

  factory CryptoHistoryItemModel.fromJson(Map<String, dynamic> json) {
    return CryptoHistoryItemModel(
      id: _parseInt(json['id']),
      paymentOrderId: _parseInt(
        json['payment_order_id'] ?? json['paymentOrderId'],
      ),
      userId: _parseInt(json['user_id'] ?? json['userId']),
      provider: _parseString(json['provider']),
      eventKey: _parseString(json['event_key'] ?? json['eventKey']),
      eventType: _parseString(json['event_type'] ?? json['eventType']),
      orderStatus: _parseString(json['order_status'] ?? json['orderStatus']),
      asset: _parseNullableString(json['asset']),
      network: _parseNullableString(json['network']),
      cryptoAmount: _parseNullableDouble(
        json['crypto_amount'] ?? json['cryptoAmount'],
      ),
      usdAmount: _resolveUsdAmount(json),
      amountMicroUsd: _resolveMicroUsd(json),
      txHash: _parseNullableString(json['tx_hash'] ?? json['txHash']),
      providerOrderId: _parseNullableString(
        json['provider_order_id'] ?? json['providerOrderId'],
      ),
      providerTransactionId: _parseNullableString(
        json['provider_transaction_id'] ?? json['providerTransactionId'],
      ),
      confirmations: _parseNullableInt(json['confirmations']),
      requiredConfirmations: _parseNullableInt(
        json['required_confirmations'] ?? json['requiredConfirmations'],
      ),
      fromAddress: _parseNullableString(
        json['from_address'] ?? json['fromAddress'],
      ),
      toAddress: _parseNullableString(json['to_address'] ?? json['toAddress']),
      verificationResult: _parseString(
        json['verification_result'] ?? json['verificationResult'] ?? 'pending',
      ),
      note: _parseNullableString(json['note']),
      rawPayload: _parseMap(json['raw_payload'] ?? json['rawPayload']),
      createdAt: _parseDateTime(json['created_at'] ?? json['createdAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'payment_order_id': paymentOrderId,
      'user_id': userId,
      'provider': provider,
      'event_key': eventKey,
      'event_type': eventType,
      'order_status': orderStatus,
      'asset': asset,
      'network': network,
      'crypto_amount': cryptoAmount,
      'usd_amount': usdAmount,
      'amount_microusd': amountMicroUsd,
      'tx_hash': txHash,
      'provider_order_id': providerOrderId,
      'provider_transaction_id': providerTransactionId,
      'confirmations': confirmations,
      'required_confirmations': requiredConfirmations,
      'from_address': fromAddress,
      'to_address': toAddress,
      'verification_result': verificationResult,
      'note': note,
      'raw_payload': rawPayload,
      'created_at': createdAt?.toIso8601String(),
    };
  }

  CryptoHistoryItemModel copyWith({
    int? id,
    int? paymentOrderId,
    int? userId,
    String? provider,
    String? eventKey,
    String? eventType,
    String? orderStatus,
    String? asset,
    String? network,
    double? cryptoAmount,
    double? usdAmount,
    int? amountMicroUsd,
    String? txHash,
    String? providerOrderId,
    String? providerTransactionId,
    int? confirmations,
    int? requiredConfirmations,
    String? fromAddress,
    String? toAddress,
    String? verificationResult,
    String? note,
    Map<String, dynamic>? rawPayload,
    DateTime? createdAt,
  }) {
    return CryptoHistoryItemModel(
      id: id ?? this.id,
      paymentOrderId: paymentOrderId ?? this.paymentOrderId,
      userId: userId ?? this.userId,
      provider: provider ?? this.provider,
      eventKey: eventKey ?? this.eventKey,
      eventType: eventType ?? this.eventType,
      orderStatus: orderStatus ?? this.orderStatus,
      asset: asset ?? this.asset,
      network: network ?? this.network,
      cryptoAmount: cryptoAmount ?? this.cryptoAmount,
      usdAmount: usdAmount ?? this.usdAmount,
      amountMicroUsd: amountMicroUsd ?? this.amountMicroUsd,
      txHash: txHash ?? this.txHash,
      providerOrderId: providerOrderId ?? this.providerOrderId,
      providerTransactionId:
          providerTransactionId ?? this.providerTransactionId,
      confirmations: confirmations ?? this.confirmations,
      requiredConfirmations:
          requiredConfirmations ?? this.requiredConfirmations,
      fromAddress: fromAddress ?? this.fromAddress,
      toAddress: toAddress ?? this.toAddress,
      verificationResult: verificationResult ?? this.verificationResult,
      note: note ?? this.note,
      rawPayload: rawPayload ?? this.rawPayload,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  bool get isVerificationPassed {
    return verificationResult.toLowerCase() == 'passed';
  }

  bool get isVerificationPending {
    return verificationResult.toLowerCase() == 'pending';
  }

  bool get isVerificationFailed {
    return verificationResult.toLowerCase() == 'failed';
  }

  bool get isWalletCredited {
    return eventType.toLowerCase() == 'wallet_credited' ||
        orderStatus.toLowerCase() == 'credited';
  }

  bool get isPaymentPaid {
    return eventType.toLowerCase() == 'payment_paid';
  }

  bool get isDepositDetected {
    return eventType.toLowerCase() == 'deposit_detected';
  }

  bool get isTransactionSubmitted {
    return eventType.toLowerCase() == 'tx_submitted';
  }

  bool get hasTransactionHash {
    return txHash != null && txHash!.trim().isNotEmpty;
  }

  bool get hasConfirmationProgress {
    return confirmations != null || requiredConfirmations != null;
  }

  double get confirmationProgress {
    final current = confirmations ?? 0;
    final required = requiredConfirmations ?? 0;

    if (required <= 0) {
      return 0.0;
    }

    final value = current / required;

    if (value < 0) {
      return 0.0;
    }

    if (value > 1) {
      return 1.0;
    }

    return value;
  }

  String get assetNetworkLabel {
    final assetText = asset?.trim() ?? '';
    final networkText = network?.trim() ?? '';

    if (assetText.isEmpty && networkText.isEmpty) {
      return provider;
    }

    if (networkText.isEmpty) {
      return assetText;
    }

    if (assetText.isEmpty) {
      return networkText;
    }

    return '$assetText • $networkText';
  }

  String get eventTitle {
    switch (eventType.toLowerCase()) {
      case 'order_created':
        return 'Payment Order Created';

      case 'awaiting_payment':
        return 'Awaiting Payment';

      case 'tx_submitted':
        return 'Transaction Submitted';

      case 'deposit_detected':
        return 'Deposit Detected';

      case 'confirmation_updated':
        return 'Confirmations Updated';

      case 'verification_passed':
        return 'Payment Verified';

      case 'verification_failed':
        return 'Verification Failed';

      case 'payment_paid':
        return 'Payment Completed';

      case 'wallet_credited':
        return 'Wallet Credited';

      case 'manual_review':
        return 'Manual Review';

      case 'approved':
        return 'Payment Approved';

      case 'rejected':
        return 'Payment Rejected';

      case 'expired':
        return 'Payment Expired';

      case 'cancelled':
        return 'Payment Cancelled';

      case 'failed':
        return 'Payment Failed';

      default:
        return _formatEventName(eventType);
    }
  }

  String get formattedUsdAmount {
    return '\$${usdAmount.toStringAsFixed(2)}';
  }

  String get confirmationLabel {
    final current = confirmations ?? 0;
    final required = requiredConfirmations ?? 0;

    if (required <= 0) {
      return '$current confirmation(s)';
    }

    return '$current / $required confirmations';
  }

  static double _resolveUsdAmount(Map<String, dynamic> json) {
    final directUsd = _parseNullableDouble(
      json['usd_amount'] ?? json['usdAmount'],
    );

    if (directUsd != null) {
      return directUsd;
    }

    final microUsd = _parseNullableInt(
      json['amount_microusd'] ?? json['amountMicroUsd'],
    );

    if (microUsd != null) {
      return microUsd / 1000000.0;
    }

    return 0.0;
  }

  static int _resolveMicroUsd(Map<String, dynamic> json) {
    final directMicroUsd = _parseNullableInt(
      json['amount_microusd'] ?? json['amountMicroUsd'],
    );

    if (directMicroUsd != null) {
      return directMicroUsd;
    }

    final usdAmount =
        _parseNullableDouble(json['usd_amount'] ?? json['usdAmount']) ?? 0.0;

    return (usdAmount * 1000000).round();
  }

  static String _formatEventName(String value) {
    final normalized = value
        .trim()
        .replaceAll('-', '_')
        .split('_')
        .where((part) => part.isNotEmpty)
        .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
        .join(' ');

    return normalized.isEmpty ? 'Payment Update' : normalized;
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

  static int? _parseNullableInt(dynamic value) {
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

  static double? _parseNullableDouble(dynamic value) {
    if (value == null) {
      return null;
    }

    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(value.toString());
  }

  static DateTime? _parseDateTime(dynamic value) {
    final text = _parseNullableString(value);

    if (text == null) {
      return null;
    }

    return DateTime.tryParse(text);
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
