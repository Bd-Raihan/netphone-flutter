class PaymentOrderModel {
  final int id;
  final String orderReference;
  final int userId;

  final String provider;
  final String paymentType;
  final String status;

  final double requestedAmountUsd;
  final int requestedAmountMicroUsd;

  final String? asset;
  final String? network;

  final double? expectedCryptoAmount;

  final String? destinationAddress;
  final String? destinationTag;

  final String? providerOrderId;
  final String? providerTransactionId;
  final String? txHash;

  final int? requiredConfirmations;
  final int? verificationAttempts;

  final int? walletTxId;
  final int? cryptoPaymentMethodId;
  final int? reconciliationJobId;

  final DateTime? expiresAt;
  final DateTime? paymentDetectedAt;
  final DateTime? paidAt;
  final DateTime? creditedAt;
  final DateTime? failedAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  final String? failureCode;
  final String? failureMessage;
  final String? reviewReason;

  final Map<String, dynamic> metadata;

  const PaymentOrderModel({
    required this.id,
    required this.orderReference,
    required this.userId,
    required this.provider,
    required this.paymentType,
    required this.status,
    required this.requestedAmountUsd,
    required this.requestedAmountMicroUsd,
    required this.asset,
    required this.network,
    required this.expectedCryptoAmount,
    required this.destinationAddress,
    required this.destinationTag,
    required this.providerOrderId,
    required this.providerTransactionId,
    required this.txHash,
    required this.requiredConfirmations,
    required this.verificationAttempts,
    required this.walletTxId,
    required this.cryptoPaymentMethodId,
    required this.reconciliationJobId,
    required this.expiresAt,
    required this.paymentDetectedAt,
    required this.paidAt,
    required this.creditedAt,
    required this.failedAt,
    required this.createdAt,
    required this.updatedAt,
    required this.failureCode,
    required this.failureMessage,
    required this.reviewReason,
    required this.metadata,
  });

  factory PaymentOrderModel.fromJson(Map<String, dynamic> json) {
    return PaymentOrderModel(
      id: _parseInt(json['id']),
      orderReference: _parseString(
        json['order_reference'] ?? json['orderReference'],
      ),
      userId: _parseInt(json['user_id'] ?? json['userId']),
      provider: _parseString(json['provider']),
      paymentType: _parseString(json['payment_type'] ?? json['paymentType']),
      status: _parseString(json['status']),
      requestedAmountUsd: _parseDouble(
        json['requested_amount_usd'] ??
            json['requestedAmountUsd'] ??
            json['amount_usd'] ??
            json['amountUsd'],
      ),
      requestedAmountMicroUsd: _resolveMicroUsd(json),
      asset: _parseNullableString(json['asset']),
      network: _parseNullableString(json['network']),
      expectedCryptoAmount: _parseNullableDouble(
        json['expected_crypto_amount'] ??
            json['expectedCryptoAmount'] ??
            json['crypto_amount'] ??
            json['cryptoAmount'],
      ),
      destinationAddress: _parseNullableString(
        json['destination_address'] ??
            json['destinationAddress'] ??
            json['address'],
      ),
      destinationTag: _parseNullableString(
        json['destination_tag'] ?? json['destinationTag'],
      ),
      providerOrderId: _parseNullableString(
        json['provider_order_id'] ?? json['providerOrderId'],
      ),
      providerTransactionId: _parseNullableString(
        json['provider_transaction_id'] ?? json['providerTransactionId'],
      ),
      txHash: _parseNullableString(json['tx_hash'] ?? json['txHash']),
      requiredConfirmations: _parseNullableInt(
        json['required_confirmations'] ?? json['requiredConfirmations'],
      ),
      verificationAttempts: _parseNullableInt(
        json['verification_attempts'] ?? json['verificationAttempts'],
      ),
      walletTxId: _parseNullableInt(json['wallet_tx_id'] ?? json['walletTxId']),
      cryptoPaymentMethodId: _parseNullableInt(
        json['crypto_payment_method_id'] ?? json['cryptoPaymentMethodId'],
      ),
      reconciliationJobId: _parseNullableInt(
        json['reconciliation_job_id'] ?? json['reconciliationJobId'],
      ),
      expiresAt: _parseDateTime(json['expires_at'] ?? json['expiresAt']),
      paymentDetectedAt: _parseDateTime(
        json['payment_detected_at'] ?? json['paymentDetectedAt'],
      ),
      paidAt: _parseDateTime(json['paid_at'] ?? json['paidAt']),
      creditedAt: _parseDateTime(json['credited_at'] ?? json['creditedAt']),
      failedAt: _parseDateTime(json['failed_at'] ?? json['failedAt']),
      createdAt: _parseDateTime(json['created_at'] ?? json['createdAt']),
      updatedAt: _parseDateTime(json['updated_at'] ?? json['updatedAt']),
      failureCode: _parseNullableString(
        json['failure_code'] ?? json['failureCode'],
      ),
      failureMessage: _parseNullableString(
        json['failure_message'] ?? json['failureMessage'],
      ),
      reviewReason: _parseNullableString(
        json['review_reason'] ?? json['reviewReason'],
      ),
      metadata: _parseMap(json['metadata']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'order_reference': orderReference,
      'user_id': userId,
      'provider': provider,
      'payment_type': paymentType,
      'status': status,
      'requested_amount_usd': requestedAmountUsd,
      'requested_amount_microusd': requestedAmountMicroUsd,
      'asset': asset,
      'network': network,
      'expected_crypto_amount': expectedCryptoAmount,
      'destination_address': destinationAddress,
      'destination_tag': destinationTag,
      'provider_order_id': providerOrderId,
      'provider_transaction_id': providerTransactionId,
      'tx_hash': txHash,
      'required_confirmations': requiredConfirmations,
      'verification_attempts': verificationAttempts,
      'wallet_tx_id': walletTxId,
      'crypto_payment_method_id': cryptoPaymentMethodId,
      'reconciliation_job_id': reconciliationJobId,
      'expires_at': expiresAt?.toIso8601String(),
      'payment_detected_at': paymentDetectedAt?.toIso8601String(),
      'paid_at': paidAt?.toIso8601String(),
      'credited_at': creditedAt?.toIso8601String(),
      'failed_at': failedAt?.toIso8601String(),
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'failure_code': failureCode,
      'failure_message': failureMessage,
      'review_reason': reviewReason,
      'metadata': metadata,
    };
  }

  PaymentOrderModel copyWith({
    int? id,
    String? orderReference,
    int? userId,
    String? provider,
    String? paymentType,
    String? status,
    double? requestedAmountUsd,
    int? requestedAmountMicroUsd,
    String? asset,
    String? network,
    double? expectedCryptoAmount,
    String? destinationAddress,
    String? destinationTag,
    String? providerOrderId,
    String? providerTransactionId,
    String? txHash,
    int? requiredConfirmations,
    int? verificationAttempts,
    int? walletTxId,
    int? cryptoPaymentMethodId,
    int? reconciliationJobId,
    DateTime? expiresAt,
    DateTime? paymentDetectedAt,
    DateTime? paidAt,
    DateTime? creditedAt,
    DateTime? failedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? failureCode,
    String? failureMessage,
    String? reviewReason,
    Map<String, dynamic>? metadata,
  }) {
    return PaymentOrderModel(
      id: id ?? this.id,
      orderReference: orderReference ?? this.orderReference,
      userId: userId ?? this.userId,
      provider: provider ?? this.provider,
      paymentType: paymentType ?? this.paymentType,
      status: status ?? this.status,
      requestedAmountUsd: requestedAmountUsd ?? this.requestedAmountUsd,
      requestedAmountMicroUsd:
          requestedAmountMicroUsd ?? this.requestedAmountMicroUsd,
      asset: asset ?? this.asset,
      network: network ?? this.network,
      expectedCryptoAmount: expectedCryptoAmount ?? this.expectedCryptoAmount,
      destinationAddress: destinationAddress ?? this.destinationAddress,
      destinationTag: destinationTag ?? this.destinationTag,
      providerOrderId: providerOrderId ?? this.providerOrderId,
      providerTransactionId:
          providerTransactionId ?? this.providerTransactionId,
      txHash: txHash ?? this.txHash,
      requiredConfirmations:
          requiredConfirmations ?? this.requiredConfirmations,
      verificationAttempts: verificationAttempts ?? this.verificationAttempts,
      walletTxId: walletTxId ?? this.walletTxId,
      cryptoPaymentMethodId:
          cryptoPaymentMethodId ?? this.cryptoPaymentMethodId,
      reconciliationJobId: reconciliationJobId ?? this.reconciliationJobId,
      expiresAt: expiresAt ?? this.expiresAt,
      paymentDetectedAt: paymentDetectedAt ?? this.paymentDetectedAt,
      paidAt: paidAt ?? this.paidAt,
      creditedAt: creditedAt ?? this.creditedAt,
      failedAt: failedAt ?? this.failedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      failureCode: failureCode ?? this.failureCode,
      failureMessage: failureMessage ?? this.failureMessage,
      reviewReason: reviewReason ?? this.reviewReason,
      metadata: metadata ?? this.metadata,
    );
  }

  bool get isAwaitingPayment => status.toLowerCase() == 'awaiting_payment';

  bool get isPaymentDetected => status.toLowerCase() == 'payment_detected';

  bool get isConfirming => status.toLowerCase() == 'confirming';

  bool get isCredited => status.toLowerCase() == 'credited';

  bool get isManualReview => status.toLowerCase() == 'manual_review';

  bool get isFailed => status.toLowerCase() == 'failed';

  bool get isCancelled => status.toLowerCase() == 'cancelled';

  bool get isExpired => status.toLowerCase() == 'expired';

  bool get isRejected => status.toLowerCase() == 'rejected';

  bool get isFinalStatus {
    return isCredited || isFailed || isCancelled || isExpired || isRejected;
  }

  bool get canSubmitTxHash {
    return provider == 'binance_onchain' &&
        !isFinalStatus &&
        (txHash == null || txHash!.trim().isEmpty);
  }

  bool get hasDestinationAddress {
    return destinationAddress != null && destinationAddress!.trim().isNotEmpty;
  }

  bool get hasTransactionHash {
    return txHash != null && txHash!.trim().isNotEmpty;
  }

  bool get isExpiredByTime {
    final expiry = expiresAt;

    if (expiry == null) {
      return false;
    }

    return DateTime.now().toUtc().isAfter(expiry.toUtc());
  }

  String get displayAssetNetwork {
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

  static int _resolveMicroUsd(Map<String, dynamic> json) {
    final direct = _parseNullableInt(
      json['requested_amount_microusd'] ??
          json['requestedAmountMicroUsd'] ??
          json['amount_microusd'] ??
          json['amountMicroUsd'],
    );

    if (direct != null) {
      return direct;
    }

    final amountUsd = _parseDouble(
      json['requested_amount_usd'] ??
          json['requestedAmountUsd'] ??
          json['amount_usd'] ??
          json['amountUsd'],
    );

    return (amountUsd * 1000000).round();
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

  static double _parseDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(value?.toString() ?? '') ?? 0.0;
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
