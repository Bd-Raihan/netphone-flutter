import 'package:flutter/material.dart';

Future<String?> showRejectDialog(BuildContext context) async {
  final controller = TextEditingController();

  return showDialog<String>(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text("Reject Recharge"),
      content: TextField(
        controller: controller,
        decoration: const InputDecoration(hintText: "Reason for rejection"),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Cancel"),
        ),
        ElevatedButton(
          onPressed: () {
            final note = controller.text.trim();
            if (note.isNotEmpty) Navigator.pop(context, note);
          },
          child: const Text("Reject"),
        ),
      ],
    ),
  );
}
