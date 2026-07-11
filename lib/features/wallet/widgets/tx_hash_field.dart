import 'package:flutter/material.dart';

class TxHashField extends StatelessWidget {
  final TextEditingController controller;

  const TxHashField({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: "Transaction Hash / TXID",
        hintText: "Paste your USDT TRC20 transaction hash",
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
