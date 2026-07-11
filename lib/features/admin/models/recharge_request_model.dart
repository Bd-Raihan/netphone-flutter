class RechargeRequestModel {
  final int id;
  final String phone;
  final String amountUsd;
  final String currency;
  final String network;
  final String txHash;
  final String status;
  final String createdAt;

  RechargeRequestModel({
    required this.id,
    required this.phone,
    required this.amountUsd,
    required this.currency,
    required this.network,
    required this.txHash,
    required this.status,
    required this.createdAt,
  });

  factory RechargeRequestModel.fromJson(Map<String, dynamic> json) {
    return RechargeRequestModel(
      id: int.parse(json["id"].toString()),
      phone: json["phone_e164"] ?? "",
      amountUsd: json["amount_usd"].toString(),
      currency: json["crypto_currency"] ?? "USDT",
      network: json["network"] ?? "TRC20",
      txHash: json["tx_hash"] ?? "",
      status: json["status"] ?? "",
      createdAt: json["created_at"] ?? "",
    );
  }
}
