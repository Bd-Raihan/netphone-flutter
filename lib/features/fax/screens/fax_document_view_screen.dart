import 'dart:io';

import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';

import '../models/fax_model.dart';
import '../services/fax_api_service.dart';
import '../widgets/fax_status_chip.dart';

class FaxDocumentViewScreen extends StatefulWidget {
  final FaxModel fax;

  const FaxDocumentViewScreen({super.key, required this.fax});

  @override
  State<FaxDocumentViewScreen> createState() => _FaxDocumentViewScreenState();
}

class _FaxDocumentViewScreenState extends State<FaxDocumentViewScreen> {
  bool _opening = false;

  Future<void> _openDocument() async {
    if (_opening) return;

    setState(() {
      _opening = true;
    });

    try {
      final File file = await FaxApiService.downloadDocument(
        faxId: widget.fax.id,
      );

      await OpenFilex.open(file.path);
    } on FaxApiException catch (e) {
      _showMessage(e.message);
    } catch (_) {
      _showMessage('Unable to open fax document.');
    } finally {
      if (mounted) {
        setState(() {
          _opening = false;
        });
      }
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Widget _row(String title, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(title, style: const TextStyle(color: Colors.grey)),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final fax = widget.fax;

    return Scaffold(
      appBar: AppBar(title: const Text('Fax Details')),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          Center(child: FaxStatusChip(status: fax.status)),

          const SizedBox(height: 28),

          _row('Direction', fax.direction.isEmpty ? '-' : fax.direction),
          _row('From', fax.fromNumber ?? '-'),
          _row('To', fax.toNumber ?? '-'),
          _row('Sender', fax.senderName ?? '-'),
          _row('Pages', fax.pages?.toString() ?? '-'),

          if (fax.failureReason != null && fax.failureReason!.isNotEmpty)
            _row('Reason', fax.failureReason!),

          const SizedBox(height: 16),

          SizedBox(
            height: 52,
            child: ElevatedButton.icon(
              onPressed: _opening ? null : _openDocument,
              icon: _opening
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.description_outlined),
              label: Text(_opening ? 'Opening...' : 'View Document'),
            ),
          ),
        ],
      ),
    );
  }
}
