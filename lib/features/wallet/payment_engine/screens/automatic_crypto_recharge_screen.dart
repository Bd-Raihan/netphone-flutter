import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../models/payment_method_model.dart';
import '../models/payment_order_model.dart';
import '../services/payment_engine_service.dart';

class AutomaticCryptoRechargeScreen extends StatefulWidget {
  const AutomaticCryptoRechargeScreen({super.key});

  @override
  State<AutomaticCryptoRechargeScreen> createState() =>
      _AutomaticCryptoRechargeScreenState();
}

class _AutomaticCryptoRechargeScreenState
    extends State<AutomaticCryptoRechargeScreen> {
  final TextEditingController _amountController = TextEditingController(
    text: '5',
  );

  final TextEditingController _txHashController = TextEditingController();

  final TextEditingController _binancePayTransactionIdController =
      TextEditingController();

  final PaymentEngineService _paymentService = PaymentEngineService.instance;

  String _selectedProvider = PaymentEngineService.binanceOnchainProvider;

  PaymentMethodModel? _selectedMethod;
  PaymentOrderModel? _currentOrder;

  List<PaymentMethodModel> _methods = [];
  List<PaymentMethodModel> _binancePayMethods = [];

  bool _isLoadingMethods = true;
  bool _isRestoringOrder = false;
  bool _isCreatingOrder = false;
  bool _isSubmittingTxHash = false;
  bool _isRefreshingStatus = false;

  String? _errorMessage;

  Timer? _statusTimer;
  Timer? _countdownTimer;

  Duration _remainingTime = Duration.zero;
  bool _isLocallyExpired = false;

  @override
  void initState() {
    super.initState();
    _initializeScreen();
  }

  @override
  void dispose() {
    _statusTimer?.cancel();
    _countdownTimer?.cancel();
    _amountController.dispose();
    _txHashController.dispose();
    _binancePayTransactionIdController.dispose();
    super.dispose();
  }

  Future<void> _initializeScreen() async {
    await _loadPaymentMethods();

    if (!mounted) {
      return;
    }

    await _restorePendingOrder();
  }

  Future<void> _restorePendingOrder() async {
    if (_isRestoringOrder || _currentOrder != null) {
      return;
    }

    try {
      setState(() {
        _isRestoringOrder = true;
      });

      final orders = await _paymentService.fetchMyOrders(limit: 50, offset: 0);

      if (!mounted) {
        return;
      }

      final pendingOrders = orders.where((order) {
        final provider = order.provider.trim().toLowerCase();

        return provider == PaymentEngineService.binanceOnchainProvider &&
            !order.isFinalStatus;
      }).toList();

      pendingOrders.sort((first, second) {
        final firstCreatedAt = first.createdAt;
        final secondCreatedAt = second.createdAt;

        if (firstCreatedAt != null && secondCreatedAt != null) {
          final dateComparison = secondCreatedAt.compareTo(firstCreatedAt);

          if (dateComparison != 0) {
            return dateComparison;
          }
        } else if (firstCreatedAt != null) {
          return -1;
        } else if (secondCreatedAt != null) {
          return 1;
        }

        return second.id.compareTo(first.id);
      });

      PaymentOrderModel? restoredOrder;

      for (final candidate in pendingOrders) {
        try {
          final latestOrder = await _paymentService.fetchOrder(
            orderReference: candidate.orderReference,
          );

          if (!mounted) {
            return;
          }

          if (latestOrder.isFinalStatus || latestOrder.isExpiredByTime) {
            continue;
          }

          restoredOrder = latestOrder;
          break;
        } on PaymentEngineException {
          // One unavailable order must not block recovery
          // of another valid pending order.
          continue;
        } catch (_) {
          continue;
        }
      }

      if (!mounted || restoredOrder == null) {
        return;
      }
      final orderToRestore = restoredOrder;
      PaymentMethodModel? matchingMethod;

      for (final method in _methods) {
        final sameAsset =
            method.asset.trim().toUpperCase() ==
            (orderToRestore.asset ?? '').trim().toUpperCase();

        final sameNetwork =
            method.network.trim().toUpperCase() ==
            (orderToRestore.network ?? '').trim().toUpperCase();

        if (sameAsset && sameNetwork) {
          matchingMethod = method;
          break;
        }
      }

      setState(() {
        _currentOrder = orderToRestore;

        if (matchingMethod != null) {
          _selectedMethod = matchingMethod;
        }

        _amountController.text = orderToRestore.requestedAmountUsd
            .toStringAsFixed(2);

        _txHashController.clear();
        _errorMessage = null;
      });

      _startExpiryCountdown();
      _startStatusPolling();

      _showMessage('Your pending payment order has been restored.');
    } catch (_) {
      // Recovery failure must not block creating
      // a new payment order.
    } finally {
      if (mounted) {
        setState(() {
          _isRestoringOrder = false;
        });
      }
    }
  }

  Future<void> _loadPaymentMethods() async {
    try {
      setState(() {
        _isLoadingMethods = true;
        _errorMessage = null;
      });

      final onchainMethods = await _paymentService.fetchPaymentMethods(
        provider: PaymentEngineService.binanceOnchainProvider,
      );

      List<PaymentMethodModel> binancePayMethods = [];

      try {
        binancePayMethods = await _paymentService.fetchPaymentMethods(
          provider: PaymentEngineService.binancePayProvider,
        );
      } on PaymentEngineException {
        // Binance Pay unavailable হলেও existing
        // on-chain recharge বন্ধ হবে না.
        binancePayMethods = [];
      } catch (_) {
        binancePayMethods = [];
      }

      if (!mounted) {
        return;
      }

      setState(() {
        _methods = onchainMethods;
        _binancePayMethods = binancePayMethods;

        if (onchainMethods.isNotEmpty) {
          _selectedMethod = onchainMethods.firstWhere(
            (method) => method.isPrimary,
            orElse: () => onchainMethods.first,
          );
        } else {
          _selectedMethod = null;
        }

        if (_selectedProvider == PaymentEngineService.binanceOnchainProvider &&
            onchainMethods.isEmpty &&
            binancePayMethods.isNotEmpty) {
          _selectedProvider = PaymentEngineService.binancePayProvider;
        }
      });
    } on PaymentEngineException catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _errorMessage = error.message;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _errorMessage = 'Unable to load payment methods.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingMethods = false;
        });
      }
    }
  }

  Future<void> _createOrder() async {
    final amount = double.tryParse(_amountController.text.trim());

    if (amount == null || amount.isNaN || amount.isInfinite) {
      _showMessage('Enter a valid recharge amount.', isError: true);
      return;
    }

    final isBinancePay =
        _selectedProvider == PaymentEngineService.binancePayProvider;

    final method = _selectedMethod;

    if (!isBinancePay) {
      if (method == null) {
        _showMessage(
          'No enabled crypto payment method is available.',
          isError: true,
        );
        return;
      }

      if (!method.supportsAmount(amount)) {
        _showMessage(
          'Amount must be between '
          '\$${method.minimumAmountUsd.toStringAsFixed(2)} '
          'and '
          '\$${method.maximumAmountUsd.toStringAsFixed(2)}.',
          isError: true,
        );
        return;
      }
    }

    try {
      setState(() {
        _isCreatingOrder = true;
        _errorMessage = null;
      });

      final PaymentOrderModel order;

      if (isBinancePay) {
        order = await _paymentService.createBinancePayOrder(amountUsd: amount);
      } else {
        final selectedMethod = method!;

        order = await _paymentService.createBinanceOnchainOrder(
          amountUsd: amount,
          asset: selectedMethod.asset,
          network: selectedMethod.network,

          // বর্তমানে live on-chain methods USDT-based।
          // BTC/LTC live quote engine ছাড়া enable করা হবে না।
          quotedCryptoAmount:
              selectedMethod.asset.trim().toUpperCase() == 'USDT'
              ? amount
              : null,
        );
      }

      if (!mounted) {
        return;
      }

      _statusTimer?.cancel();
      _countdownTimer?.cancel();

      setState(() {
        _currentOrder = order;
        _txHashController.clear();
        _binancePayTransactionIdController.clear();
      });

      _startExpiryCountdown();
      _startStatusPolling();

      _showMessage(
        isBinancePay
            ? 'Binance Pay order created successfully.'
            : 'Payment order created successfully.',
      );
    } on PaymentEngineException catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _errorMessage = error.message;
      });

      _showMessage(error.message, isError: true);
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _errorMessage = 'Unable to create payment order.';
      });

      _showMessage('Unable to create payment order.', isError: true);
    } finally {
      if (mounted) {
        setState(() {
          _isCreatingOrder = false;
        });
      }
    }
  }

  Future<void> _submitTxHash() async {
    final order = _currentOrder;

    if (order == null) {
      _showMessage('Create a payment order first.', isError: true);
      return;
    }

    if (_isOrderExpired(order)) {
      _showMessage(
        'This payment order has expired. Create a new payment order.',
        isError: true,
      );
      return;
    }

    final txHash = _txHashController.text.trim();

    if (txHash.length < 20) {
      _showMessage('Enter a valid transaction hash or TXID.', isError: true);
      return;
    }

    try {
      setState(() {
        _isSubmittingTxHash = true;
        _errorMessage = null;
      });

      final updatedOrder = await _paymentService.submitTransactionHash(
        orderReference: order.orderReference,
        txHash: txHash,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _currentOrder = updatedOrder;
      });

      _startStatusPolling();

      _showMessage('Transaction submitted. Verification has started.');
    } on PaymentEngineException catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _errorMessage = error.message;
      });

      _showMessage(error.message, isError: true);
    } catch (_) {
      if (!mounted) {
        return;
      }

      _showMessage('Unable to submit transaction hash.', isError: true);
    } finally {
      if (mounted) {
        setState(() {
          _isSubmittingTxHash = false;
        });
      }
    }
  }

  Future<void> _submitBinancePayTransactionId() async {
    final order = _currentOrder;

    if (order == null) {
      _showMessage('Create a Binance Pay order first.', isError: true);
      return;
    }

    if (_isOrderExpired(order)) {
      _showMessage(
        'This payment order has expired. '
        'Create a new payment order.',
        isError: true,
      );
      return;
    }

    final transactionId = _binancePayTransactionIdController.text.trim();

    if (transactionId.isEmpty) {
      _showMessage('Enter your Binance Pay transaction ID.', isError: true);
      return;
    }

    try {
      setState(() {
        _isSubmittingTxHash = true;
        _errorMessage = null;
      });

      final updatedOrder = await _paymentService.submitBinancePayTransactionId(
        orderReference: order.orderReference,
        transactionId: transactionId,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _currentOrder = updatedOrder;
      });

      _startStatusPolling();

      _showMessage(
        'Binance Pay transaction submitted. '
        'Verification has started.',
      );
    } on PaymentEngineException catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _errorMessage = error.message;
      });

      _showMessage(error.message, isError: true);
    } catch (_) {
      if (!mounted) {
        return;
      }

      _showMessage(
        'Unable to submit Binance Pay transaction ID.',
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmittingTxHash = false;
        });
      }
    }
  }

  Future<void> _refreshOrderStatus() async {
    final order = _currentOrder;

    if (order == null || _isRefreshingStatus) {
      return;
    }

    try {
      setState(() {
        _isRefreshingStatus = true;
      });

      final updatedOrder = await _paymentService.fetchOrder(
        orderReference: order.orderReference,
      );

      if (!mounted) {
        return;
      }

      final oldStatus = _currentOrder?.status;

      setState(() {
        _currentOrder = updatedOrder;
      });

      if (updatedOrder.isFinalStatus || updatedOrder.isExpiredByTime) {
        _statusTimer?.cancel();
        _countdownTimer?.cancel();

        if (updatedOrder.isExpired || updatedOrder.isExpiredByTime) {
          setState(() {
            _remainingTime = Duration.zero;
            _isLocallyExpired = true;
          });
        }
      } else {
        _startExpiryCountdown();
      }

      if (updatedOrder.isCredited && oldStatus != updatedOrder.status) {
        _showPaymentSuccessDialog(updatedOrder);
      }
    } catch (_) {
      // Silent polling failure.
      // Manual refresh button remains available.
    } finally {
      if (mounted) {
        setState(() {
          _isRefreshingStatus = false;
        });
      }
    }
  }

  void _startStatusPolling() {
    _statusTimer?.cancel();

    final order = _currentOrder;

    if (order == null || order.isFinalStatus || _isOrderExpired(order)) {
      return;
    }

    _statusTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      _refreshOrderStatus();
    });
  }

  bool _isOrderExpired(PaymentOrderModel order) {
    return order.isExpired || order.isExpiredByTime || _isLocallyExpired;
  }

  void _startExpiryCountdown() {
    _countdownTimer?.cancel();

    final order = _currentOrder;
    final expiresAt = order?.expiresAt;

    if (order == null || expiresAt == null || order.isFinalStatus) {
      if (mounted) {
        setState(() {
          _remainingTime = Duration.zero;
          _isLocallyExpired = order?.isExpired ?? false;
        });
      }
      return;
    }

    void updateRemainingTime() {
      final difference = expiresAt.toLocal().difference(DateTime.now());
      final hasExpired = difference <= Duration.zero;

      if (!mounted) {
        return;
      }

      setState(() {
        _remainingTime = hasExpired ? Duration.zero : difference;
        _isLocallyExpired = hasExpired;
      });

      if (hasExpired) {
        _countdownTimer?.cancel();
        _statusTimer?.cancel();
      }
    }

    updateRemainingTime();

    if (!_isLocallyExpired) {
      _countdownTimer = Timer.periodic(
        const Duration(seconds: 1),
        (_) => updateRemainingTime(),
      );
    }
  }

  String _formatRemainingTime(Duration duration) {
    final totalSeconds = duration.inSeconds < 0 ? 0 : duration.inSeconds;
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    final seconds = totalSeconds % 60;

    final minuteText = minutes.toString().padLeft(2, '0');
    final secondText = seconds.toString().padLeft(2, '0');

    if (hours > 0) {
      final hourText = hours.toString().padLeft(2, '0');
      return '$hourText:$minuteText:$secondText';
    }

    return '$minuteText:$secondText';
  }

  void _resetOrder() {
    _statusTimer?.cancel();
    _countdownTimer?.cancel();

    setState(() {
      _currentOrder = null;
      _remainingTime = Duration.zero;
      _isLocallyExpired = false;
      _txHashController.clear();
      _binancePayTransactionIdController.clear();
      _errorMessage = null;
    });
  }

  void _showPaymentSuccessDialog(PaymentOrderModel order) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Recharge Successful'),
          content: Text(
            '\$${order.requestedAmountUsd.toStringAsFixed(2)} '
            'has been credited to your wallet.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                Navigator.of(context).pop(true);
              },
              child: const Text('Done'),
            ),
          ],
        );
      },
    );
  }

  void _showMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  String _statusLabel(PaymentOrderModel order) {
    if (_isOrderExpired(order)) {
      return 'Expired';
    }

    switch (order.status.toLowerCase()) {
      case 'created':
        return 'Order Created';

      case 'awaiting_payment':
        return 'Awaiting Payment';

      case 'payment_detected':
        return 'Payment Detected';

      case 'confirming':
        return 'Confirming';

      case 'credited':
        return 'Wallet Credited';

      case 'manual_review':
        return 'Manual Review';

      case 'expired':
        return 'Expired';

      case 'cancelled':
        return 'Cancelled';

      case 'rejected':
        return 'Rejected';

      case 'failed':
        return 'Failed';

      default:
        return order.status.replaceAll('_', ' ').toUpperCase();
    }
  }

  Color _statusColor(PaymentOrderModel order) {
    if (_isOrderExpired(order)) {
      return Colors.red;
    }

    if (order.isCredited) {
      return Colors.green;
    }

    if (order.isFailed ||
        order.isRejected ||
        order.isCancelled ||
        order.isExpired) {
      return Colors.red;
    }

    if (order.isManualReview) {
      return Colors.orange;
    }

    return Colors.blue;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: const Color(0xFF1145F5),
        foregroundColor: Colors.white,
        title: const Text('Automatic Crypto Recharge'),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          if (_currentOrder != null) {
            await _refreshOrderStatus();
          } else {
            await _initializeScreen();
          }
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildWarningCard(),
            const SizedBox(height: 16),
            if (_isLoadingMethods || _isRestoringOrder)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 32),
                child: Center(
                  child: Column(
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 14),
                      Text(
                        'Checking for pending payment orders...',
                        style: TextStyle(color: Colors.white70),
                      ),
                    ],
                  ),
                ),
              )
            else ...[
              if (_currentOrder == null) ...[
                _buildProviderSelector(),
                const SizedBox(height: 16),

                if (_selectedProvider ==
                    PaymentEngineService.binanceOnchainProvider) ...[
                  if (_methods.isEmpty)
                    _buildNoMethodsCard()
                  else
                    _buildMethodSelector(),
                  if (_methods.isNotEmpty) const SizedBox(height: 16),
                ] else ...[
                  _buildBinancePayInfoCard(),
                  const SizedBox(height: 16),
                ],

                _buildCreateOrderCard(),
              ] else
                _buildActiveOrderCard(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildWarningCard() {
    final isBinancePay =
        _selectedProvider == PaymentEngineService.binancePayProvider;

    final method = _selectedMethod;

    final message = isBinancePay
        ? 'Use Binance Pay and verify the recipient details before completing the payment.'
        : method == null
        ? 'Select a payment network before sending your payment.'
        : 'Use ${method.asset} on the ${method.network} network. '
              'Please confirm the selected network before sending.';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF10243A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF285F91)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.info_outline_rounded,
            color: Color(0xFF64B5F6),
            size: 23,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Color(0xFFD5E9FA),
                fontSize: 14,
                fontWeight: FontWeight.w500,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoMethodsCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1B1B1B),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          const Text(
            'No crypto payment method is currently available.',
            style: TextStyle(color: Colors.white70),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: _loadPaymentMethods,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildProviderSelector() {
    final binancePayAvailable = _binancePayMethods.isNotEmpty;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1B1B1B),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF2C313A)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Payment Provider',
            style: TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 14),

          SizedBox(
            width: double.infinity,
            child: SegmentedButton<String>(
              segments: [
                const ButtonSegment<String>(
                  value: PaymentEngineService.binanceOnchainProvider,
                  icon: Icon(Icons.currency_bitcoin_rounded),
                  label: Text('Multi-Coin'),
                ),
                ButtonSegment<String>(
                  value: PaymentEngineService.binancePayProvider,
                  enabled: binancePayAvailable,
                  icon: const Icon(Icons.account_balance_wallet_outlined),
                  label: const Text('Binance Pay'),
                ),
              ],

              selected: <String>{_selectedProvider},

              style: ButtonStyle(
                foregroundColor: WidgetStateProperty.resolveWith<Color>((
                  states,
                ) {
                  if (states.contains(WidgetState.selected)) {
                    return const Color(0xFF10233F);
                  }

                  if (states.contains(WidgetState.disabled)) {
                    return Colors.white38;
                  }

                  return Colors.white;
                }),

                backgroundColor: WidgetStateProperty.resolveWith<Color>((
                  states,
                ) {
                  if (states.contains(WidgetState.selected)) {
                    return const Color(0xFFBFD7FF);
                  }

                  return const Color(0xFF252A33);
                }),

                side: WidgetStateProperty.resolveWith<BorderSide>((states) {
                  if (states.contains(WidgetState.selected)) {
                    return const BorderSide(
                      color: Color(0xFF6EA1FF),
                      width: 1.4,
                    );
                  }

                  return const BorderSide(color: Color(0xFF414855));
                }),

                textStyle: WidgetStateProperty.all(
                  const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                ),

                iconColor: WidgetStateProperty.resolveWith<Color>((states) {
                  if (states.contains(WidgetState.selected)) {
                    return const Color(0xFF174A8B);
                  }

                  return Colors.white70;
                }),

                padding: WidgetStateProperty.all(
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                ),
              ),

              onSelectionChanged: _currentOrder != null
                  ? null
                  : (selection) {
                      if (selection.isEmpty) {
                        return;
                      }

                      final provider = selection.first;

                      setState(() {
                        _selectedProvider = provider;
                        _errorMessage = null;
                      });
                    },
            ),
          ),

          if (!binancePayAvailable) ...[
            const SizedBox(height: 10),
            const Text(
              'Binance Pay is currently unavailable.',
              style: TextStyle(color: Colors.white54, fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBinancePayInfoCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1B1B1B),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFFF3BA2F).withValues(alpha: 0.45),
        ),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.account_balance_wallet_outlined,
                color: Color(0xFFF3BA2F),
              ),
              SizedBox(width: 10),
              Text(
                'Binance Pay',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: 10),
          Text(
            'Pay using Binance Pay, then enter the '
            'Binance Pay transaction ID shown in your '
            'Binance payment details.',
            style: TextStyle(color: Colors.white70, height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _buildMethodSelector() {
    final method = _selectedMethod;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1B1B1B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2D3440)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Payment Method',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),

          const SizedBox(height: 10),

          InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: _currentOrder != null ? null : _showPaymentMethodPicker,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              decoration: BoxDecoration(
                color: const Color(0xFF22262E),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFF3B4554)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: const Color(0xFF173C67),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.currency_exchange_rounded,
                      color: Color(0xFF77B7FF),
                      size: 24,
                    ),
                  ),

                  const SizedBox(width: 13),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          method?.displayName.trim().isNotEmpty == true
                              ? method!.displayName
                              : method?.assetNetworkLabel ??
                                    'Choose payment method',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: _currentOrder == null
                                ? Colors.white
                                : Colors.white54,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),

                        if (method != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            '${method.assetNetworkLabel}  •  '
                            '${method.amountRangeLabel}',
                            style: const TextStyle(
                              color: Colors.white54,
                              fontSize: 12.5,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(width: 8),

                  Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: _currentOrder == null
                        ? Colors.white70
                        : Colors.white30,
                    size: 28,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showPaymentMethodPicker() async {
    if (_currentOrder != null || _methods.isEmpty) {
      return;
    }

    final selected = await showModalBottomSheet<PaymentMethodModel>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) {
        return SafeArea(
          child: Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
            decoration: BoxDecoration(
              color: const Color(0xFF181A1F),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFF303641)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),

                const SizedBox(height: 18),

                const Text(
                  'Choose Payment Method',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 6),

                const Text(
                  'Select the network you want to use for this recharge.',
                  style: TextStyle(color: Colors.white54, fontSize: 12),
                ),

                const SizedBox(height: 18),

                ..._methods.map((method) {
                  final isSelected = _selectedMethod?.id == method.id;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () {
                        Navigator.of(sheetContext).pop(method);
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFF172C46)
                              : const Color(0xFF22252B),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected
                                ? const Color(0xFF579CFF)
                                : const Color(0xFF343A44),
                            width: isSelected ? 1.4 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? const Color(0xFF225B96)
                                    : const Color(0xFF303641),
                                borderRadius: BorderRadius.circular(13),
                              ),
                              child: Icon(
                                method.network.trim().toUpperCase() == 'TRC20'
                                    ? Icons.flash_on_rounded
                                    : Icons.hub_rounded,
                                color: isSelected
                                    ? const Color(0xFF9AC8FF)
                                    : Colors.white70,
                              ),
                            ),

                            const SizedBox(width: 13),

                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    method.displayName.trim().isNotEmpty
                                        ? method.displayName
                                        : method.assetNetworkLabel,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),

                                  const SizedBox(height: 4),

                                  Text(
                                    '${method.assetNetworkLabel}  •  '
                                    '${method.amountRangeLabel}',
                                    style: const TextStyle(
                                      color: Colors.white54,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            if (isSelected)
                              const Icon(
                                Icons.check_circle_rounded,
                                color: Color(0xFF66A9FF),
                                size: 25,
                              )
                            else
                              const Icon(
                                Icons.chevron_right_rounded,
                                color: Colors.white38,
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        );
      },
    );

    if (!mounted || selected == null) {
      return;
    }

    setState(() {
      _selectedMethod = selected;
      _errorMessage = null;
    });
  }

  Widget _buildCreateOrderCard() {
    final method = _selectedMethod;

    final isBinancePay =
        _selectedProvider == PaymentEngineService.binancePayProvider;

    final binancePayMethod = _binancePayMethods.isNotEmpty
        ? _binancePayMethods.first
        : null;

    final displayMethod = isBinancePay ? binancePayMethod : method;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1B1B1B),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isBinancePay
                ? 'USDT • BINANCE PAY'
                : displayMethod?.assetNetworkLabel ?? 'Crypto Recharge',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            displayMethod == null
                ? ''
                : 'Allowed amount: ${displayMethod.amountRangeLabel}',
            style: const TextStyle(color: Colors.white54),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _amountController,
            enabled: !_isCreatingOrder,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              labelText: 'Recharge Amount (USD)',
              labelStyle: TextStyle(color: Colors.white70),
              hintText: 'Example: 5',
              hintStyle: TextStyle(color: Colors.white38),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _isCreatingOrder ? null : _createOrder,
              child: _isCreatingOrder
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Create Payment Order'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveOrderCard() {
    final order = _currentOrder!;

    return Column(
      children: [
        _buildStatusCard(order),
        const SizedBox(height: 16),
        _buildOrderDetailsCard(order),
        if (_isOrderExpired(order)) ...[
          const SizedBox(height: 16),
          _buildExpiredOrderCard(),
        ] else ...[
          if (order.hasDestinationAddress) ...[
            const SizedBox(height: 16),
            _buildQrCard(order),
            const SizedBox(height: 16),
            _buildAddressCard(order),
          ],
          if (!order.isFinalStatus) ...[
            const SizedBox(height: 16),

            if (order.provider.trim().toLowerCase() ==
                PaymentEngineService.binancePayProvider)
              _buildBinancePayTransactionCard(order)
            else
              _buildTxHashCard(order),
          ],
        ],
        const SizedBox(height: 16),
        _buildOrderActions(order),
      ],
    );
  }

  Widget _buildStatusCard(PaymentOrderModel order) {
    final color = _statusColor(order);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          Icon(
            order.isCredited
                ? Icons.check_circle
                : _isOrderExpired(order)
                ? Icons.timer_off_outlined
                : Icons.hourglass_top,
            color: color,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _statusLabel(order),
              style: TextStyle(
                color: color,
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          if (_isRefreshingStatus)
            const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
        ],
      ),
    );
  }

  Widget _buildOrderDetailsCard(PaymentOrderModel order) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1B1B1B),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Payment Order',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 14),
          _detailRow('Reference', order.orderReference),
          _detailRow(
            'Amount',
            '\$${order.requestedAmountUsd.toStringAsFixed(2)}',
          ),
          _detailRow('Method', order.displayAssetNetwork),
          if (order.expectedCryptoAmount != null)
            _detailRow(
              'Expected Crypto',
              order.expectedCryptoAmount!.toString(),
            ),
          if (order.expiresAt != null) ...[
            _detailRow(
              'Time Remaining',
              _isOrderExpired(order)
                  ? 'Expired'
                  : _formatRemainingTime(_remainingTime),
            ),
            _detailRow('Expires At', order.expiresAt!.toLocal().toString()),
          ],
        ],
      ),
    );
  }

  Widget _buildExpiredOrderCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.red.withValues(alpha: 0.45)),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.timer_off_outlined,
            color: Colors.redAccent,
            size: 42,
          ),
          const SizedBox(height: 12),
          const Text(
            'Payment Order Expired',
            style: TextStyle(
              color: Colors.redAccent,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Do not send funds to this expired order. Create a new payment '
            'order to receive a valid QR code and deposit instruction.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white70, height: 1.4),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: _resetOrder,
              icon: const Icon(Icons.add),
              label: const Text('Create New Payment'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQrCard(PaymentOrderModel order) {
    final address = order.destinationAddress!;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Center(
        child: QrImageView(
          data: address,
          size: 190,
          backgroundColor: Colors.white,
        ),
      ),
    );
  }

  Widget _buildAddressCard(PaymentOrderModel order) {
    final address = order.destinationAddress!;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1B1B1B),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Deposit Address',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          SelectableText(
            address,
            style: const TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _isOrderExpired(order)
                  ? null
                  : () {
                      Clipboard.setData(ClipboardData(text: address));

                      _showMessage('Deposit address copied.');
                    },
              icon: const Icon(Icons.copy),
              label: const Text('Copy Address'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBinancePayTransactionCard(PaymentOrderModel order) {
    final submittedId = order.providerTransactionId?.trim();

    final alreadySubmitted = submittedId != null && submittedId.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1B1B1B),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            alreadySubmitted
                ? 'Submitted Binance Pay Transaction ID'
                : 'Binance Pay Transaction ID',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),

          if (alreadySubmitted)
            SelectableText(
              submittedId,
              style: const TextStyle(color: Colors.white70),
            )
          else ...[
            TextField(
              controller: _binancePayTransactionIdController,
              enabled: !_isSubmittingTxHash && !_isOrderExpired(order),
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Binance Pay Transaction ID',
                labelStyle: TextStyle(color: Colors.white70),
                hintText: 'Paste Binance Pay transaction ID',
                hintStyle: TextStyle(color: Colors.white38),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _isSubmittingTxHash || _isOrderExpired(order)
                    ? null
                    : _submitBinancePayTransactionId,
                child: _isSubmittingTxHash
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Submit Binance Pay Transaction ID'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTxHashCard(PaymentOrderModel order) {
    final txAlreadySubmitted = order.hasTransactionHash;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1B1B1B),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            txAlreadySubmitted
                ? 'Submitted TXID'
                : 'Submit Transaction Hash / TXID',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          if (txAlreadySubmitted)
            SelectableText(
              order.txHash!,
              style: const TextStyle(color: Colors.white70),
            )
          else ...[
            TextField(
              controller: _txHashController,
              enabled: !_isSubmittingTxHash && !_isOrderExpired(order),
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Transaction Hash / TXID',
                labelStyle: TextStyle(color: Colors.white70),
                hintText: 'Paste your crypto transaction ID',
                hintStyle: TextStyle(color: Colors.white38),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _isSubmittingTxHash || _isOrderExpired(order)
                    ? null
                    : _submitTxHash,
                child: _isSubmittingTxHash
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Submit TXID'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildOrderActions(PaymentOrderModel order) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _isRefreshingStatus || _isOrderExpired(order)
                ? null
                : _refreshOrderStatus,
            icon: const Icon(Icons.refresh),
            label: const Text('Refresh Status'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: order.isCredited
                ? () {
                    Navigator.pop(context, true);
                  }
                : _resetOrder,
            icon: Icon(
              order.isCredited
                  ? Icons.done
                  : _isOrderExpired(order)
                  ? Icons.add
                  : Icons.refresh,
            ),
            label: Text(
              order.isCredited
                  ? 'Done'
                  : _isOrderExpired(order)
                  ? 'New Payment'
                  : 'New Order',
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorCard(String message) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(message, style: const TextStyle(color: Colors.redAccent)),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(label, style: const TextStyle(color: Colors.white54)),
          ),
          Expanded(
            child: SelectableText(
              value,
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
