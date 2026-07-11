import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

import '../../../core/config/app_config.dart';
import '../../../shared/services/storage_service.dart';

class AdminRechargeScreen extends StatefulWidget {
  const AdminRechargeScreen({super.key});

  @override
  State<AdminRechargeScreen> createState() => _AdminRechargeScreenState();
}

class _AdminRechargeScreenState extends State<AdminRechargeScreen> {
  bool isLoading = true;
  bool isActionLoading = false;
  String? errorMessage;
  List<CryptoRechargeRequest> requests = [];

  @override
  void initState() {
    super.initState();
    loadPendingRequests();
  }

  Future<void> loadPendingRequests() async {
    try {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });

      final token = await StorageService.getToken();
      final response = await http
          .get(
            Uri.parse("${AppConfig.baseUrl}/api/admin/crypto/pending"),
            headers: {
              "Authorization": "Bearer $token",
              "Content-Type": "application/json",
            },
          )
          .timeout(const Duration(seconds: 20));

      debugPrint("ADMIN CRYPTO PENDING STATUS => ${response.statusCode}");
      debugPrint("ADMIN CRYPTO PENDING BODY => ${response.body}");

      final data = response.body.isNotEmpty
          ? jsonDecode(response.body)
          : <String, dynamic>{};

      if (response.statusCode == 200 && data["ok"] == true) {
        final List list =
            (data["items"] ?? data["requests"] ?? data["data"] ?? []) as List;
        requests = list
            .map((item) => CryptoRechargeRequest.fromJson(item))
            .toList();
      } else {
        errorMessage = data["message"] ?? data["error"] ?? "Load failed";
      }
    } catch (e) {
      errorMessage = "Load failed: $e";
    } finally {
      if (!mounted) return;
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> approveRequest(CryptoRechargeRequest item) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Approve Recharge?"),
        content: Text(
          "Approve ${item.amountUsd.toStringAsFixed(2)} USD for ${item.phoneE164}?\n\nMake sure TXID is confirmed on TRONSCAN before approval.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Approve"),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    await updateRequestStatus(
      item: item,
      action: "approve",
      successMessage: "Recharge approved and wallet credited",
    );
  }

  Future<void> rejectRequest(CryptoRechargeRequest item) async {
    final reasonController = TextEditingController();

    final reason = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Reject Recharge"),
        content: TextField(
          controller: reasonController,
          decoration: const InputDecoration(
            labelText: "Reject reason",
            hintText: "Example: TXID not found / wrong amount",
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context, reasonController.text.trim());
            },
            child: const Text("Reject"),
          ),
        ],
      ),
    );

    if (reason == null || reason.isEmpty) return;

    await updateRequestStatus(
      item: item,
      action: "reject",
      rejectReason: reason,
      successMessage: "Recharge request rejected",
    );
  }

  Future<void> updateRequestStatus({
    required CryptoRechargeRequest item,
    required String action,
    String? rejectReason,
    required String successMessage,
  }) async {
    try {
      setState(() {
        isActionLoading = true;
      });

      final token = await StorageService.getToken();
      final response = await http
          .post(
            Uri.parse(
              "${AppConfig.baseUrl}/api/admin/crypto/${item.id}/$action",
            ),
            headers: {
              "Authorization": "Bearer $token",
              "Content-Type": "application/json",
            },
            body: jsonEncode({
              if (rejectReason != null) "reason": rejectReason,
            }),
          )
          .timeout(const Duration(seconds: 20));

      debugPrint("ADMIN CRYPTO $action STATUS => ${response.statusCode}");
      debugPrint("ADMIN CRYPTO $action BODY => ${response.body}");

      final data = response.body.isNotEmpty
          ? jsonDecode(response.body)
          : <String, dynamic>{};

      if (response.statusCode == 200 && data["ok"] == true) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(successMessage),
            backgroundColor: Colors.green,
          ),
        );
        await loadPendingRequests();
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(data["message"] ?? data["error"] ?? "Action failed"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Action error: $e"),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (!mounted) return;
      setState(() {
        isActionLoading = false;
      });
    }
  }

  Future<void> openTx(CryptoRechargeRequest item) async {
    if (item.txHash.isEmpty) return;
    final uri = Uri.parse("https://tronscan.org/#/transaction/${item.txHash}");
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1145F5),
        title: Text(
          "Crypto Recharge Requests",
          style: TextStyle(
            color: Colors.white,
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            onPressed: isLoading ? null : loadPendingRequests,
            icon: const Icon(Icons.refresh, color: Colors.white),
          ),
        ],
      ),
      body: Stack(
        children: [
          if (isLoading)
            const Center(child: CircularProgressIndicator())
          else if (errorMessage != null)
            Center(
              child: Padding(
                padding: EdgeInsets.all(20.w),
                child: Text(
                  errorMessage!,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.red, fontSize: 15.sp),
                ),
              ),
            )
          else if (requests.isEmpty)
            Center(
              child: Text(
                "No pending recharge requests",
                style: TextStyle(fontSize: 16.sp, color: Colors.black54),
              ),
            )
          else
            ListView.builder(
              padding: EdgeInsets.all(16.w),
              itemCount: requests.length,
              itemBuilder: (context, index) {
                final item = requests[index];
                return Card(
                  margin: EdgeInsets.only(bottom: 14.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14.r),
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(16.w),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "${item.amountUsd.toStringAsFixed(2)} USD / ${item.cryptoCurrency}",
                          style: TextStyle(
                            fontSize: 18.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 10.h),
                        infoText("User", item.phoneE164),
                        infoText("Network", item.network),
                        infoText("TXID", item.txHash),
                        infoText("Status", item.status),
                        infoText("Created", item.createdAt),
                        SizedBox(height: 14.h),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () => openTx(item),
                                icon: const Icon(Icons.open_in_new),
                                label: const Text("TRONSCAN"),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 10.h),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton(
                                onPressed: isActionLoading
                                    ? null
                                    : () => approveRequest(item),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                ),
                                child: const Text(
                                  "Approve",
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),
                            ),
                            SizedBox(width: 10.w),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: isActionLoading
                                    ? null
                                    : () => rejectRequest(item),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                ),
                                child: const Text(
                                  "Reject",
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          if (isActionLoading)
            Container(
              color: Colors.black.withOpacity(0.25),
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }

  Widget infoText(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 6.h),
      child: SelectableText(
        "$label: ${value.isEmpty ? "N/A" : value}",
        style: TextStyle(fontSize: 13.sp, color: Colors.black87),
      ),
    );
  }
}

class CryptoRechargeRequest {
  final String id;
  final String phoneE164;
  final double amountUsd;
  final String cryptoCurrency;
  final String network;
  final String txHash;
  final String status;
  final String createdAt;

  CryptoRechargeRequest({
    required this.id,
    required this.phoneE164,
    required this.amountUsd,
    required this.cryptoCurrency,
    required this.network,
    required this.txHash,
    required this.status,
    required this.createdAt,
  });

  factory CryptoRechargeRequest.fromJson(Map<String, dynamic> json) {
    return CryptoRechargeRequest(
      id: (json["id"] ?? json["request_id"] ?? "").toString(),
      phoneE164:
          (json["phone_e164"] ?? json["phone"] ?? json["user_phone"] ?? "")
              .toString(),
      amountUsd:
          double.tryParse(
            (json["amount_usd"] ?? json["amount"] ?? 0).toString(),
          ) ??
          0,
      cryptoCurrency: (json["crypto_currency"] ?? json["currency"] ?? "USDT")
          .toString(),
      network: (json["network"] ?? "TRC20").toString(),
      txHash:
          (json["tx_hash"] ?? json["txid"] ?? json["transaction_hash"] ?? "")
              .toString(),
      status: (json["status"] ?? "pending").toString(),
      createdAt: (json["created_at"] ?? "").toString(),
    );
  }
}
