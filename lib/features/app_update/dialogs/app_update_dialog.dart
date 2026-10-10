import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/app_update_service.dart';

// ============================================================
// 🇧🇩 NETPHONE APP UPDATE DIALOG
//
// কাজ:
// - নতুন version available হলে user-কে popup দেখানো
// - Optional update হলে Later + Update Now
// - Force update হলে শুধু Update Now
// - Play Store link open করা
// ============================================================

Future<void> showNetPhoneUpdateDialog(
  BuildContext context,
  AppUpdateCheckResult result,
) async {
  final update = result.update;

  Future<void> openStore() async {
    final url = update.playStoreUrl?.trim();

    if (url == null || url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Play Store link is not available.')),
      );
      return;
    }

    final uri = Uri.tryParse(url);

    if (uri == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Invalid Play Store link.')));
      return;
    }

    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);

    if (!opened && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to open Google Play Store.')),
      );
    }
  }

  await showDialog<void>(
    context: context,
    barrierDismissible: !result.forceUpdateRequired,
    builder: (dialogContext) {
      return PopScope(
        canPop: !result.forceUpdateRequired,
        child: AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),

          titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 8),

          contentPadding: const EdgeInsets.fromLTRB(20, 8, 20, 8),

          actionsPadding: const EdgeInsets.fromLTRB(16, 8, 16, 16),

          title: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.system_update_alt,
                  color: Color.fromARGB(255, 33, 170, 243),
                  size: 19,
                ),
              ),

              const SizedBox(width: 14),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      update.title.isEmpty
                          ? (result.forceUpdateRequired
                                ? 'Update Required'
                                : 'Update Available')
                          : update.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 5),

                    Text(
                      'Version '
                      '${update.versionName}',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 6),

              Text(
                update.message,
                style: const TextStyle(fontSize: 14, height: 1.45),
              ),

              const SizedBox(height: 14),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: result.forceUpdateRequired
                      ? Colors.orange.withValues(alpha: 0.10)
                      : Colors.blue.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      result.forceUpdateRequired
                          ? Icons.warning_amber
                          : Icons.info_outline,
                      size: 21,
                      color: result.forceUpdateRequired
                          ? Colors.orange
                          : Colors.blue,
                    ),

                    const SizedBox(width: 10),

                    Expanded(
                      child: Text(
                        result.forceUpdateRequired
                            ? 'This version must be updated before you can continue using NetPhone.'
                            : 'Update NetPhone to get the latest improvements and fixes.',
                        style: const TextStyle(fontSize: 13, height: 1.35),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          actions: [
            if (!result.forceUpdateRequired)
              TextButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                },
                child: const Text('Later'),
              ),

            FilledButton.icon(
              onPressed: openStore,
              icon: const Icon(Icons.open_in_new, size: 18),
              label: const Text('Update Now'),
            ),
          ],
        ),
      );
    },
  );
}
