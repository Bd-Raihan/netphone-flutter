import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../services/stripe_payment_service.dart';

class StripeRechargeScreen extends StatefulWidget {
  const StripeRechargeScreen({super.key});

  @override
  State<StripeRechargeScreen> createState() => _StripeRechargeScreenState();
}

class _StripeRechargeScreenState extends State<StripeRechargeScreen> {
  static const _requestKey = 'netphone_stripe_pending_request';
  static const _orderKey = 'netphone_stripe_pending_order';
  static const _amountKey = 'netphone_stripe_pending_amount';

  final _amount = TextEditingController(text: '5.00');
  final _service = StripePaymentService.instance;

  bool _busy = true;
  int? _orderId;
  String? _requestId;
  String? _statusMessage;

  @override
  void initState() {
    super.initState();
    _restorePending();
  }

  Future<void> _restorePending() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final requestId = prefs.getString(_requestKey);
      final orderId = prefs.getInt(_orderKey);
      final amount = prefs.getString(_amountKey);

      if (!mounted) return;

      setState(() {
        _requestId = requestId;
        _orderId = orderId;
        if (amount != null) _amount.text = amount;

        _statusMessage = requestId == null
            ? null
            : 'Previous recharge found. '
                  'Check its status or safely resume it.';
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _statusMessage =
            'Unable to read pending recharge. '
            'Do not start a new payment.';
      });
      return;
    }

    if (mounted) setState(() => _busy = false);
  }

  Future<void> _savePending(String requestId, String amount) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_requestKey, requestId);
    await prefs.setString(_amountKey, amount);
  }

  Future<void> _saveOrder(int orderId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_orderKey, orderId);
  }

  Future<void> _clearPending() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_requestKey);
    await prefs.remove(_orderKey);
    await prefs.remove(_amountKey);
  }

  Future<void> _pay() async {
    if (_busy || _orderId != null) return;

    final amount = double.tryParse(_amount.text.trim());

    if (amount == null ||
        !amount.isFinite ||
        amount < 5 ||
        amount > 500 ||
        ((amount * 100) - (amount * 100).round()).abs() > 0.000001) {
      _message('Enter USD 5–500, up to 2 decimals.');
      return;
    }

    if (!Stripe.publishableKey.startsWith('pk_test_') &&
        !Stripe.publishableKey.startsWith('pk_live_')) {
      _message('Stripe publishable key is not configured.');
      return;
    }

    setState(() {
      _busy = true;
      _statusMessage = null;
    });

    try {
      // Reuse the same ID after timeout or app restart.
      final requestId = _requestId ?? const Uuid().v4();

      // Save BEFORE contacting the backend.
      await _savePending(requestId, amount.toStringAsFixed(2));

      _requestId = requestId;

      final order = await _service.createPayment(
        amountUsd: amount,
        clientRequestId: requestId,
      );

      final orderId = int.tryParse('${order['orderId']}');

      if (orderId == null || orderId <= 0) {
        throw StateError('Invalid Stripe order ID.');
      }

      await _saveOrder(orderId);
      _orderId = orderId;

      final status = '${order['status'] ?? ''}';

      if (status == 'credited') {
        await _confirmCredited();
        return;
      }

      final secret = order['clientSecret'];

      if (secret is! String || secret.isEmpty) {
        if (!mounted) return;
        setState(() {
          _statusMessage =
              'Order #$orderId: ${status.isEmpty ? 'pending' : status}. '
              'Payment requires server reconciliation. '
              'Do not start another recharge.';
        });
        return;
      }

      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: secret,
          merchantDisplayName: 'NetPhone',
        ),
      );

      await Stripe.instance.presentPaymentSheet();

      if (!mounted) return;

      setState(() {
        _statusMessage = 'Payment submitted. Waiting for wallet confirmation.';
      });

      await _refreshStatus();
    } on StripeException catch (e) {
      if (!mounted) return;
      setState(() {
        _statusMessage =
            'Payment not completed: '
            '${e.error.localizedMessage ?? 'Cancelled or failed'}. '
            'Check the existing order before retrying.';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _statusMessage =
            'Payment request needs verification: $e. '
            'Do not start another recharge.';
      });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _confirmCredited() async {
    await _clearPending();

    if (!mounted) return;

    setState(() {
      _orderId = null;
      _requestId = null;
      _statusMessage = 'Recharge confirmed. Wallet credited successfully.';
    });
  }

  Future<void> _refreshStatus() async {
    if (_busy) return;

    final id = _orderId;
    if (id == null) return;

    setState(() => _busy = true);

    try {
      final data = await _service.getPaymentStatus(orderId: id);

      if (!mounted) return;

      final status = '${data['status'] ?? 'pending'}';

      if (status == 'credited') {
        await _confirmCredited();
        return;
      }

      setState(() {
        _statusMessage =
            'Order #$id: $status. '
            'Wallet credit is not yet confirmed.';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _statusMessage =
            'Could not verify order #$id: $e. '
            'Keep this order pending.';
      });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _message(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasPending = _requestId != null;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(title: const Text('Visa / Mastercard Recharge')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Recharge amount (USD)',
              style: TextStyle(color: Colors.white, fontSize: 17),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _amount,
              enabled: !_busy && !hasPending,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
              ],
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                prefixText: '\$ ',
                hintText: '5.00',
                filled: true,
                fillColor: Color(0xFF20232B),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 18),
            ElevatedButton(
              onPressed: _busy || _orderId != null ? null : _pay,
              child: _busy
                  ? const CircularProgressIndicator()
                  : Text(
                      hasPending
                          ? 'Resume existing recharge'
                          : 'Continue to secure card payment',
                    ),
            ),
            if (_orderId != null) ...[
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: _busy ? null : _refreshStatus,
                child: const Text('Check payment status'),
              ),
            ],
            if (_statusMessage != null) ...[
              const SizedBox(height: 18),
              Text(
                _statusMessage!,
                style: const TextStyle(color: Colors.white70),
              ),
            ],
            const SizedBox(height: 20),
            const Text(
              'Wallet credit is confirmed only by '
              'the NetPhone backend after Stripe verification. '
              'Never repeat an uncertain payment.',
              style: TextStyle(color: Colors.white54),
            ),
          ],
        ),
      ),
    );
  }
}
