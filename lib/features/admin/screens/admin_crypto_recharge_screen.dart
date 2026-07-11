import 'package:flutter/material.dart';

import '../models/recharge_request_model.dart';
import '../services/admin_crypto_service.dart';
import '../widgets/recharge_request_card.dart';
import '../dialogs/reject_dialog.dart';

class AdminCryptoRechargeScreen extends StatefulWidget {
  const AdminCryptoRechargeScreen({super.key});

  @override
  State<AdminCryptoRechargeScreen> createState() =>
      _AdminCryptoRechargeScreenState();
}

class _AdminCryptoRechargeScreenState extends State<AdminCryptoRechargeScreen> {
  bool loading = true;
  List<RechargeRequestModel> items = [];

  @override
  void initState() {
    super.initState();
    loadRequests();
  }

  Future<void> loadRequests() async {
    try {
      setState(() => loading = true);
      items = await AdminCryptoService.fetchPendingRequests();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Load failed: $e")));
      }
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> approve(int id) async {
    try {
      await AdminCryptoService.approveRequest(id);
      await loadRequests();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Recharge approved")));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Approve failed: $e")));
      }
    }
  }

  Future<void> reject(int id) async {
    final note = await showRejectDialog(context);
    if (note == null) return;

    try {
      await AdminCryptoService.rejectRequest(id, note);
      await loadRequests();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Recharge rejected")));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Reject failed: $e")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("Crypto Recharge Requests"),
        backgroundColor: const Color(0xFF1145F5),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: loadRequests,
              child: items.isEmpty
                  ? const Center(
                      child: Text(
                        "No pending recharge requests",
                        style: TextStyle(color: Colors.white),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(14),
                      itemCount: items.length,
                      itemBuilder: (_, index) {
                        final item = items[index];

                        return RechargeRequestCard(
                          item: item,
                          onApprove: () => approve(item.id),
                          onReject: () => reject(item.id),
                        );
                      },
                    ),
            ),
    );
  }
}
