import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../../../core/config/app_config.dart';
import '../../../../shared/services/storage_service.dart';
import '../models/crypto_history_item_model.dart';
import '../models/payment_method_model.dart';
import '../models/payment_order_model.dart';

class PaymentEngineException implements Exception {
  final String message;
  final int? statusCode;
  final String? errorCode;
  final dynamic details;

  const PaymentEngineException({
    required this.message,
    this.statusCode,
    this.errorCode,
    this.details,
  });

  @override
  String toString() => message;
}

class PaymentEngineService {
  PaymentEngineService._();

  static final PaymentEngineService instance = PaymentEngineService._();

  static const String binanceOnchainProvider = 'binance_onchain';

  static const String binancePayProvider = 'binance_pay';

  static const String manualCryptoProvider = 'manual_crypto';

  static const Duration _requestTimeout = Duration(seconds: 25);

  static String get _basePath => '${AppConfig.baseUrl}/api/payment-engine';

  Future<Map<String, String>> _authenticatedHeaders() async {
    final token = await StorageService.getToken();

    if (token == null || token.trim().isEmpty) {
      throw const PaymentEngineException(
        message: 'Login session missing. Please log in again.',
        errorCode: 'login_token_missing',
      );
    }

    return <String, String>{
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      'Authorization': 'Bearer ${token.trim()}',
    };
  }

  /// =========================================
  /// GET REGISTERED PROVIDERS
  /// =========================================

  Future<List<Map<String, dynamic>>> fetchProviders() async {
    final response = await _get('/providers');

    final decoded = _decodeResponse(response);

    final rawProviders =
        decoded['providers'] ??
        decoded['data']?['providers'] ??
        decoded['data'] ??
        const <dynamic>[];

    return _parseMapList(rawProviders);
  }

  /// =========================================
  /// GET ENABLED PAYMENT METHODS
  /// =========================================

  Future<List<PaymentMethodModel>> fetchPaymentMethods({
    String provider = binanceOnchainProvider,
  }) async {
    final normalizedProvider = provider.trim();

    if (normalizedProvider.isEmpty) {
      throw const PaymentEngineException(
        message: 'Payment provider is required.',
        errorCode: 'payment_provider_required',
      );
    }

    final response = await _get(
      '/methods/${Uri.encodeComponent(normalizedProvider)}',
    );

    final decoded = _decodeResponse(response);

    final rawMethods = _findMethodsList(decoded);

    final methods = <PaymentMethodModel>[];

    for (final item in rawMethods) {
      try {
        final method = PaymentMethodModel.fromJson(item);

        // Backend endpoint already returns enabled methods only.
        methods.add(method);
      } catch (error) {
        debugPrint('PAYMENT METHOD PARSE ERROR: $error | DATA: $item');
      }
    }

    methods.sort((a, b) {
      if (a.isPrimary != b.isPrimary) {
        return a.isPrimary ? -1 : 1;
      }

      return a.displayOrder.compareTo(b.displayOrder);
    });

    return methods;
  }

  Future<PaymentMethodModel?> fetchPrimaryPaymentMethod({
    String provider = binanceOnchainProvider,
  }) async {
    final methods = await fetchPaymentMethods(provider: provider);

    if (methods.isEmpty) {
      return null;
    }

    for (final method in methods) {
      if (method.isPrimary) {
        return method;
      }
    }

    return methods.first;
  }

  /// =========================================
  /// CREATE BINANCE ON-CHAIN ORDER
  /// =========================================

  Future<PaymentOrderModel> createBinanceOnchainOrder({
    required double amountUsd,
    required String asset,
    required String network,
    double? quotedCryptoAmount,
  }) async {
    if (amountUsd.isNaN || amountUsd.isInfinite) {
      throw const PaymentEngineException(
        message: 'Enter a valid recharge amount.',
        errorCode: 'invalid_recharge_amount_usd',
      );
    }

    if (amountUsd < 5 || amountUsd > 500) {
      throw const PaymentEngineException(
        message: 'Recharge amount must be between \$5 and \$500.',
        errorCode: 'invalid_recharge_amount_range',
      );
    }

    final normalizedAsset = asset.trim().toUpperCase();
    final normalizedNetwork = network.trim().toUpperCase();

    if (normalizedAsset.isEmpty) {
      throw const PaymentEngineException(
        message: 'Crypto asset is required.',
        errorCode: 'asset_required',
      );
    }

    if (normalizedNetwork.isEmpty) {
      throw const PaymentEngineException(
        message: 'Crypto network is required.',
        errorCode: 'network_required',
      );
    }

    final body = <String, dynamic>{
      'provider': binanceOnchainProvider,
      'amountUsd': double.parse(amountUsd.toStringAsFixed(2)),
      'asset': normalizedAsset,
      'network': normalizedNetwork,
    };

    if (quotedCryptoAmount != null &&
        !quotedCryptoAmount.isNaN &&
        !quotedCryptoAmount.isInfinite &&
        quotedCryptoAmount > 0) {
      body['quotedCryptoAmount'] = quotedCryptoAmount.toString();
    }

    final response = await _post('/orders', body: body);

    final decoded = _decodeResponse(response);

    final orderJson = _findOrderMap(decoded);

    if (orderJson == null) {
      throw PaymentEngineException(
        message: 'Payment order was created, but order data is missing.',
        statusCode: response.statusCode,
        errorCode: 'payment_order_response_missing',
        details: decoded,
      );
    }

    final order = PaymentOrderModel.fromJson(orderJson);

    if (order.orderReference.trim().isEmpty) {
      throw PaymentEngineException(
        message: 'Invalid payment order response.',
        statusCode: response.statusCode,
        errorCode: 'payment_order_reference_missing',
        details: decoded,
      );
    }

    return order;
  }

  /// =========================================
  /// CREATE BINANCE PAY ORDER
  /// =========================================

  Future<PaymentOrderModel> createBinancePayOrder({
    required double amountUsd,
  }) async {
    if (amountUsd.isNaN || amountUsd.isInfinite) {
      throw const PaymentEngineException(
        message: 'Enter a valid recharge amount.',
        errorCode: 'invalid_recharge_amount_usd',
      );
    }

    if (amountUsd < 5 || amountUsd > 500) {
      throw const PaymentEngineException(
        message: 'Recharge amount must be between \$5 and \$500.',
        errorCode: 'invalid_recharge_amount_range',
      );
    }

    final response = await _post(
      '/orders',
      body: <String, dynamic>{
        'provider': binancePayProvider,
        'amountUsd': double.parse(amountUsd.toStringAsFixed(2)),
      },
    );

    final decoded = _decodeResponse(response);

    final orderJson = _findOrderMap(decoded);

    if (orderJson == null) {
      throw PaymentEngineException(
        message: 'Binance Pay order was created, but order data is missing.',
        statusCode: response.statusCode,
        errorCode: 'payment_order_response_missing',
        details: decoded,
      );
    }

    final order = PaymentOrderModel.fromJson(orderJson);

    if (order.orderReference.trim().isEmpty) {
      throw PaymentEngineException(
        message: 'Invalid Binance Pay order response.',
        statusCode: response.statusCode,
        errorCode: 'payment_order_reference_missing',
        details: decoded,
      );
    }

    return order;
  }

  /// =========================================
  /// SUBMIT BINANCE PAY TRANSACTION ID
  /// =========================================

  Future<PaymentOrderModel> submitBinancePayTransactionId({
    required String orderReference,
    required String transactionId,
  }) async {
    final reference = orderReference.trim();
    final normalizedTransactionId = transactionId.trim();

    if (reference.isEmpty) {
      throw const PaymentEngineException(
        message: 'Payment order reference is required.',
        errorCode: 'order_reference_required',
      );
    }

    if (normalizedTransactionId.isEmpty) {
      throw const PaymentEngineException(
        message: 'Enter your Binance Pay transaction ID.',
        errorCode: 'invalid_binance_pay_transaction_id',
      );
    }

    final response = await _post(
      '/orders/${Uri.encodeComponent(reference)}'
      '/binance-pay-transaction',
      body: <String, dynamic>{'transactionId': normalizedTransactionId},
    );

    final decoded = _decodeResponse(response);

    final orderJson = _findOrderMap(decoded);

    if (orderJson == null) {
      throw PaymentEngineException(
        message:
            'Binance Pay transaction was submitted, but updated order data is missing.',
        statusCode: response.statusCode,
        errorCode: 'updated_payment_order_missing',
        details: decoded,
      );
    }

    return PaymentOrderModel.fromJson(orderJson);
  }

  /// =========================================
  /// SUBMIT TX HASH
  /// =========================================

  Future<PaymentOrderModel> submitTransactionHash({
    required String orderReference,
    required String txHash,
  }) async {
    final reference = orderReference.trim();
    final transactionHash = txHash.trim();

    if (reference.isEmpty) {
      throw const PaymentEngineException(
        message: 'Payment order reference is required.',
        errorCode: 'order_reference_required',
      );
    }

    if (transactionHash.length < 20) {
      throw const PaymentEngineException(
        message: 'Enter a valid transaction hash or TXID.',
        errorCode: 'invalid_transaction_hash',
      );
    }

    final response = await _post(
      '/orders/${Uri.encodeComponent(reference)}/tx-hash',
      body: <String, dynamic>{'txHash': transactionHash},
    );

    final decoded = _decodeResponse(response);

    final orderJson = _findOrderMap(decoded);

    if (orderJson == null) {
      throw PaymentEngineException(
        message: 'TXID submitted, but updated order data is missing.',
        statusCode: response.statusCode,
        errorCode: 'updated_payment_order_missing',
        details: decoded,
      );
    }

    return PaymentOrderModel.fromJson(orderJson);
  }

  /// =========================================
  /// GET SINGLE ORDER
  /// =========================================

  Future<PaymentOrderModel> fetchOrder({required String orderReference}) async {
    final reference = orderReference.trim();

    if (reference.isEmpty) {
      throw const PaymentEngineException(
        message: 'Payment order reference is required.',
        errorCode: 'order_reference_required',
      );
    }

    final response = await _get('/orders/${Uri.encodeComponent(reference)}');

    final decoded = _decodeResponse(response);

    final orderJson = _findOrderMap(decoded);

    if (orderJson == null) {
      throw PaymentEngineException(
        message: 'Payment order data is missing.',
        statusCode: response.statusCode,
        errorCode: 'payment_order_response_missing',
        details: decoded,
      );
    }

    return PaymentOrderModel.fromJson(orderJson);
  }

  /// =========================================
  /// POLL ORDER UNTIL FINAL STATUS
  /// =========================================

  Future<PaymentOrderModel> waitForFinalOrderStatus({
    required String orderReference,
    Duration pollInterval = const Duration(seconds: 5),
    Duration timeout = const Duration(minutes: 5),
    void Function(PaymentOrderModel order)? onStatusChanged,
  }) async {
    final startedAt = DateTime.now();
    PaymentOrderModel? latestOrder;
    String? latestStatus;

    while (DateTime.now().difference(startedAt) < timeout) {
      final order = await fetchOrder(orderReference: orderReference);

      latestOrder = order;

      if (latestStatus != order.status) {
        latestStatus = order.status;
        onStatusChanged?.call(order);
      }

      if (order.isFinalStatus) {
        return order;
      }

      await Future<void>.delayed(pollInterval);
    }

    if (latestOrder != null) {
      return latestOrder;
    }

    throw const PaymentEngineException(
      message: 'Payment status check timed out.',
      errorCode: 'payment_status_timeout',
    );
  }

  /// =========================================
  /// LIST USER ORDERS
  /// =========================================

  Future<List<PaymentOrderModel>> fetchMyOrders({
    int limit = 20,
    int offset = 0,
  }) async {
    final safeLimit = limit.clamp(1, 100);
    final safeOffset = offset < 0 ? 0 : offset;

    final response = await _get('/orders?limit=$safeLimit&offset=$safeOffset');

    final decoded = _decodeResponse(response);

    final rawOrders =
        decoded['orders'] ??
        decoded['data']?['orders'] ??
        decoded['data'] ??
        const <dynamic>[];

    final orderMaps = _parseMapList(rawOrders);

    final orders = <PaymentOrderModel>[];

    for (final item in orderMaps) {
      try {
        orders.add(PaymentOrderModel.fromJson(item));
      } catch (_) {
        // Ignore malformed record, preserve valid records.
      }
    }

    return orders;
  }

  /// =========================================
  /// CRYPTO HISTORY
  /// =========================================

  Future<List<CryptoHistoryItemModel>> fetchCryptoHistory({
    int limit = 50,
    int offset = 0,
  }) async {
    final safeLimit = limit.clamp(1, 100);
    final safeOffset = offset < 0 ? 0 : offset;

    final response = await _get('/history?limit=$safeLimit&offset=$safeOffset');

    final decoded = _decodeResponse(response);

    final rawHistory =
        decoded['history'] ??
        decoded['data']?['history'] ??
        decoded['items'] ??
        decoded['data']?['items'] ??
        const <dynamic>[];

    final historyMaps = _parseMapList(rawHistory);

    final history = <CryptoHistoryItemModel>[];

    for (final item in historyMaps) {
      try {
        history.add(CryptoHistoryItemModel.fromJson(item));
      } catch (_) {
        // Ignore malformed history record.
      }
    }

    return history;
  }

  /// =========================================
  /// HTTP HELPERS
  /// =========================================

  Future<http.Response> _get(String path) async {
    try {
      final response = await http
          .get(
            Uri.parse('$_basePath$path'),
            headers: await _authenticatedHeaders(),
          )
          .timeout(_requestTimeout);

      _throwForErrorResponse(response);

      return response;
    } on TimeoutException {
      throw const PaymentEngineException(
        message: 'Payment server request timed out. Please try again.',
        errorCode: 'payment_request_timeout',
      );
    } on PaymentEngineException {
      rethrow;
    } catch (error) {
      throw PaymentEngineException(
        message: 'Unable to connect to the payment server.',
        errorCode: 'payment_network_error',
        details: error.toString(),
      );
    }
  }

  Future<http.Response> _post(
    String path, {
    required Map<String, dynamic> body,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$_basePath$path'),
            headers: await _authenticatedHeaders(),
            body: jsonEncode(body),
          )
          .timeout(_requestTimeout);

      _throwForErrorResponse(response);

      return response;
    } on TimeoutException {
      throw const PaymentEngineException(
        message: 'Payment server request timed out. Please try again.',
        errorCode: 'payment_request_timeout',
      );
    } on PaymentEngineException {
      rethrow;
    } catch (error) {
      throw PaymentEngineException(
        message: 'Unable to connect to the payment server.',
        errorCode: 'payment_network_error',
        details: error.toString(),
      );
    }
  }

  void _throwForErrorResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return;
    }

    final decoded = _tryDecodeMap(response.body);

    final backendMessage =
        decoded?['message']?.toString().trim() ??
        decoded?['error']?.toString().trim() ??
        decoded?['code']?.toString().trim();

    final errorCode = decoded?['code']?.toString().trim() ?? backendMessage;

    throw PaymentEngineException(
      message: _userFriendlyMessage(
        backendMessage,
        statusCode: response.statusCode,
      ),
      statusCode: response.statusCode,
      errorCode: errorCode,
      details: decoded ?? response.body,
    );
  }

  Map<String, dynamic> _decodeResponse(http.Response response) {
    if (response.body.trim().isEmpty) {
      throw PaymentEngineException(
        message: 'Payment server returned an empty response.',
        statusCode: response.statusCode,
        errorCode: 'empty_payment_response',
      );
    }

    final dynamic decoded;

    try {
      decoded = jsonDecode(response.body);
    } catch (_) {
      throw PaymentEngineException(
        message: 'Payment server returned an invalid response.',
        statusCode: response.statusCode,
        errorCode: 'invalid_payment_json',
        details: response.body,
      );
    }

    if (decoded is! Map) {
      throw PaymentEngineException(
        message: 'Payment server returned an invalid data format.',
        statusCode: response.statusCode,
        errorCode: 'invalid_payment_response_format',
        details: decoded,
      );
    }

    final data = Map<String, dynamic>.from(decoded);

    if (data['ok'] == false) {
      final message = data['message']?.toString() ?? data['error']?.toString();

      throw PaymentEngineException(
        message: _userFriendlyMessage(message, statusCode: response.statusCode),
        statusCode: response.statusCode,
        errorCode: message,
        details: data,
      );
    }

    return data;
  }

  Map<String, dynamic>? _tryDecodeMap(String body) {
    if (body.trim().isEmpty) {
      return null;
    }

    try {
      final decoded = jsonDecode(body);

      if (decoded is Map) {
        return Map<String, dynamic>.from(decoded);
      }
    } catch (_) {
      return null;
    }

    return null;
  }

  /// Supports current and future-compatible response nesting.
  Map<String, dynamic>? _findOrderMap(Map<String, dynamic> decoded) {
    final directOrder = decoded['order'];

    if (directOrder is Map) {
      return Map<String, dynamic>.from(directOrder);
    }

    final data = decoded['data'];

    if (data is Map) {
      final dataMap = Map<String, dynamic>.from(data);

      final nestedOrder = dataMap['order'];

      if (nestedOrder is Map) {
        return Map<String, dynamic>.from(nestedOrder);
      }

      final nestedData = dataMap['data'];

      if (nestedData is Map) {
        final nestedDataMap = Map<String, dynamic>.from(nestedData);

        final deepOrder = nestedDataMap['order'];

        if (deepOrder is Map) {
          return Map<String, dynamic>.from(deepOrder);
        }
      }

      if (_looksLikeOrder(dataMap)) {
        return dataMap;
      }
    }

    if (_looksLikeOrder(decoded)) {
      return decoded;
    }

    return null;
  }

  List<Map<String, dynamic>> _findMethodsList(Map<String, dynamic> decoded) {
    final candidates = <dynamic>[
      decoded['methods'],
      decoded['items'],
      decoded['payment_methods'],
      decoded['data']?['methods'],
      decoded['data']?['items'],
      decoded['data']?['payment_methods'],
      decoded['data'],
    ];

    for (final candidate in candidates) {
      final list = _parseMapList(candidate);

      if (list.isNotEmpty) {
        return list;
      }
    }

    return <Map<String, dynamic>>[];
  }

  List<Map<String, dynamic>> _parseMapList(dynamic value) {
    if (value is! List) {
      return <Map<String, dynamic>>[];
    }

    final result = <Map<String, dynamic>>[];

    for (final item in value) {
      if (item is Map<String, dynamic>) {
        result.add(Map<String, dynamic>.from(item));
      } else if (item is Map) {
        result.add(Map<String, dynamic>.from(item));
      }
    }

    return result;
  }

  bool _looksLikeOrder(Map<String, dynamic> value) {
    return value.containsKey('order_reference') ||
        value.containsKey('orderReference');
  }

  String _userFriendlyMessage(String? backendMessage, {int? statusCode}) {
    final message = backendMessage?.trim() ?? '';

    switch (message) {
      case 'invalid_user_id':
        return 'Your login session is invalid. Please log in again.';

      case 'payment_provider_required':
        return 'Please select a payment provider.';

      case 'unsupported_payment_provider':
        return 'This payment method is not supported.';

      case 'invalid_recharge_amount_usd':
        return 'Enter a valid recharge amount.';

      case 'asset_required':
        return 'Please select a crypto asset.';

      case 'network_required':
        return 'Please select a crypto network.';

      case 'order_reference_required':
        return 'Payment order reference is missing.';

      case 'invalid_transaction_hash':
        return 'Enter a valid transaction hash or TXID.';

      case 'payment_order_not_found':
        return 'Payment order was not found.';

      case 'payment_order_already_finalized':
        return 'This payment order is already finalized.';

      case 'transaction_hash_already_used':
        return 'This transaction hash has already been used.';

      case 'provider_transaction_already_used':
        return 'This payment transaction has already been used.';

      case 'binance_onchain_disabled':
        return 'Binance on-chain recharge is temporarily unavailable.';

      case 'binance_pay_disabled':
        return 'Binance Pay is temporarily unavailable.';

      case 'binance_pay_method_disabled':
        return 'Binance Pay is currently unavailable.';

      case 'invalid_binance_pay_transaction_id':
        return 'Enter a valid Binance Pay transaction ID.';

      case 'crypto_payment_method_disabled':
        return 'This crypto payment method is currently unavailable.';

      case 'login_token_missing':
        return 'Please log in again.';

      default:
        if (message.startsWith('recharge_amount_must_be_between_')) {
          return 'Recharge amount must be between \$5 and \$500.';
        }

        if (statusCode == 401 || statusCode == 403) {
          return 'Your login session has expired. Please log in again.';
        }

        if (statusCode == 404) {
          return 'Requested payment information was not found.';
        }

        if (statusCode != null && statusCode >= 500) {
          return 'Payment server is temporarily unavailable. Please try again.';
        }

        if (message.isNotEmpty) {
          return message
              .replaceAll('_', ' ')
              .replaceFirstMapped(
                RegExp(r'^[a-z]'),
                (match) => match.group(0)!.toUpperCase(),
              );
        }

        return 'Payment request failed. Please try again.';
    }
  }
}
