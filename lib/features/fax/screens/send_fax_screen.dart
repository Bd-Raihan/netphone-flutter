import '../widgets/fax_help_panel.dart';
import '../widgets/fax_blue_theme.dart';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../services/fax_api_service.dart';
import '../services/fax_platform_api.dart';
import '../widgets/fax_status_chip.dart';
import 'fax_history_screen.dart';

class SendFaxScreen extends StatefulWidget {
  const SendFaxScreen({super.key});

  @override
  State<SendFaxScreen> createState() => _SendFaxScreenState();
}

class _SendFaxScreenState extends State<SendFaxScreen> {
  final _formKey = GlobalKey<FormState>();

  final _toController = TextEditingController();
  final _senderController = TextEditingController();
  final _emailController = TextEditingController();
  final _countryController = TextEditingController();

  File? _selectedFile;
  String? _selectedFileName;

  bool _sending = false;
  int? _uploadedId;
  Map<String, dynamic>? _quote;
  String? _quotedNumber;
  bool _submissionAttempted = false;

  @override
  void dispose() {
    _toController.dispose();
    _senderController.dispose();
    _emailController.dispose();
    _countryController.dispose();
    super.dispose();
  }

  Future<void> _pickDocument() async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
        allowMultiple: false,
      );

      if (result == null || result.files.isEmpty) return;

      final selected = result.files.single;

      if (selected.path == null) {
        _showMessage('Unable to access selected document.');
        return;
      }

      setState(() {
        _selectedFile = File(selected.path!);
        _selectedFileName = selected.name;
        _uploadedId = null;
        _quote = null;
        _quotedNumber = null;
        _submissionAttempted = false;
      });
    } catch (e) {
      _showMessage('Unable to select document.');
    }
  }

  Future<void> _sendFax() async {
    if (_sending) return;

    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedFile == null) {
      _showMessage('Please select a fax document.');
      return;
    }

    setState(() {
      _sending = true;
    });

    bool submissionStarted = false;
    try {
      _uploadedId ??= await FaxApiService.uploadDocument(_selectedFile!);
      final uploadId = _uploadedId!;

      if (!mounted) return;
      final number = _toController.text.trim();
      if (_submissionAttempted && _quotedNumber != number) {
        _showMessage('Check Fax History before changing this fax submission.');
        return;
      }
      final expired = DateTime.tryParse(_quote?['expires_at']?.toString() ?? '')
          ?.isBefore(DateTime.now()) ?? false;
      if (_quote == null || (!_submissionAttempted && (expired || _quotedNumber != number))) {
        _quote = await FaxPlatformApi.request('/quote', method: 'POST', body: {
          'upload_id': uploadId,
          'to_number': number,
        });
        _quotedNumber = number;
      }
      final quote = _quote!;
      if (!mounted) return;
      if (quote['billing_enabled'] == true) {
        final fee = double.parse(quote['amount_usd'].toString());
        final available = double.parse(quote['balance_usd'].toString());
        if (available < fee) {
          _showMessage('Insufficient balance. Recharge your wallet before sending.');
          return;
        }
      }
      final confirmed = await showDialog<bool>(context: context, builder: (context) => AlertDialog(backgroundColor: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF16232F) : Colors.white, surfaceTintColor: Colors.transparent, 
        title: const Text('Confirm Fax'),
        content: Text('To: ${_toController.text.trim()}\n'
          '${quote['pages'] == null ? '' : 'Pages: ${quote['pages']}\n'}'
          'Prepaid ceiling: ${FaxPlatformApi.usd(quote['amount_usd'])}\n\n'
          '${quote['dynamic'] == true ? 'The prepaid amount is deducted now. Final fee = actual Fax API + SIP cost plus 40%, or the applicable manual per-page minimum if higher, up to this ceiling. Unused funds are refunded after provider billing arrives. Failed attempts may have a fee.' : 'The fee is charged before sending. If the fax fails, the prepaid fax fee is refunded.'}'),
        actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(style: FilledButton.styleFrom(backgroundColor: const Color(0xFF168FE5), foregroundColor: Colors.white), onPressed: () => Navigator.pop(context, true), child: const Text('Confirm & Send'))],
      ));
      if (confirmed != true || !mounted) return;
      submissionStarted = true;
      _submissionAttempted = true;

      final fax = await FaxApiService.sendFax(
        uploadId: uploadId,
        quoteId: quote['quote_id']?.toString(),
        toNumber: _toController.text,
        senderName: _senderController.text,
        userEmail: _emailController.text,
        countryCode: _countryController.text,
      );

      if (!mounted) return;

      if (FaxStatusChip.isSuccessful(fax.status)) {
        _showMessage(
          'Successful — fax delivered.',
          backgroundColor: Colors.green.shade700,
        );
      } else if (FaxStatusChip.normalize(fax.status) == 'failed') {
        _showMessage(
          'Failed — ${FaxStatusChip.failureMessage(fax.failureReason)}',
          backgroundColor: Colors.red.shade700,
        );
      } else {
        _showMessage(
          'Delivery pending. Open Fax History for the final result.',
          backgroundColor: Colors.orange.shade800,
        );
      }

      Navigator.pop(context, true);
    } on FaxApiException catch (e) {
      if (!mounted) return;
      if (e.statusCode != null && e.statusCode! < 500) {
        _submissionAttempted = false;
        if (e.statusCode == 409) _quote = null;
      }
      final unconfirmed =
          submissionStarted && (e.statusCode == null || e.statusCode! >= 500);
      _showMessage(
        unconfirmed
            ? 'Submission not confirmed. Check Fax History before trying again.'
            : 'Not sent — ${e.message}',
        backgroundColor: unconfirmed
            ? Colors.orange.shade800
            : Colors.red.shade700,
        showHistoryAction: unconfirmed,
      );
    } on SocketException catch (_) {
      if (!mounted) return;
      _showMessage(
        submissionStarted
            ? 'Connection lost. Check Fax History before trying again.'
            : 'Not sent — connection unavailable. Please reconnect.',
        backgroundColor: submissionStarted
            ? Colors.orange.shade800
            : Colors.red.shade700,
        showHistoryAction: submissionStarted,
      );
    } catch (e) {
      if (!mounted) return;
      _showMessage(
        submissionStarted
            ? 'Submission not confirmed. Check Fax History before trying again.'
            : 'Not sent — unable to submit the fax document.',
        backgroundColor: submissionStarted
            ? Colors.orange.shade800
            : Colors.red.shade700,
        showHistoryAction: submissionStarted,
      );
    } finally {
      if (mounted) {
        setState(() {
          _sending = false;
        });
      }
    }
  }

  void _showMessage(
    String message, {
    Color? backgroundColor,
    bool showHistoryAction = false,
  }) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
        action: showHistoryAction
            ? SnackBarAction(
                label: 'History',
                textColor: Colors.white,
                onPressed: () {
                  if (!mounted) return;
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const FaxHistoryScreen()),
                  );
                },
              )
            : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) => FaxBlueTheme(builder: _buildFax);

  Widget _buildFax(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Send Fax')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const FaxHelpPanel(),
              const SizedBox(height: 12),
              InkWell(
                onTap: _sending ? null : _pickDocument,
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    border: Border.all(color: Theme.of(context).dividerColor),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.upload_file, size: 42),
                      const SizedBox(height: 10),
                      Text(
                        _selectedFileName ?? 'Select PDF, JPG or PNG',
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 5),
                      const Text(
                        'Maximum file size: 20 MB',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 22),

              TextFormField(
                controller: _toController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Recipient Fax Number',
                  hintText: '+12025550123',
                  prefixIcon: Icon(Icons.phone),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  final text = value?.trim() ?? '';

                  if (text.isEmpty) {
                    return 'Recipient fax number is required';
                  }

                  if (!RegExp(r'^\+[1-9]\d{7,14}$').hasMatch(text)) {
                    return 'Enter number in international format';
                  }

                  return null;
                },
              ),

              const SizedBox(height: 16),

              TextFormField(
                controller: _senderController,
                decoration: const InputDecoration(
                  labelText: 'Sender Name',
                  prefixIcon: Icon(Icons.person_outline),
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 16),

              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email (Optional)',
                  prefixIcon: Icon(Icons.email_outlined),
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 16),

              TextFormField(
                controller: _countryController,
                textCapitalization: TextCapitalization.characters,
                decoration: const InputDecoration(
                  labelText: 'Country Code (Optional)',
                  hintText: 'US',
                  prefixIcon: Icon(Icons.public),
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 24),

              SizedBox(
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _sending ? null : _sendFax,
                  icon: _sending
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.send),
                  label: Text(_sending ? 'Sending...' : 'Send Fax'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
