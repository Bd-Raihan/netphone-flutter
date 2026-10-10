import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../services/fax_api_service.dart';

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

    try {
      final uploadId = await FaxApiService.uploadDocument(_selectedFile!);

      final fax = await FaxApiService.sendFax(
        uploadId: uploadId,
        toNumber: _toController.text,
        senderName: _senderController.text,
        userEmail: _emailController.text,
        countryCode: _countryController.text,
      );

      if (!mounted) return;

      _showMessage('Fax submitted successfully. Status: ${fax.status}');

      Navigator.pop(context, true);
    } on FaxApiException catch (e) {
      if (!mounted) return;
      _showMessage(e.message);
    } catch (e) {
      if (!mounted) return;
      _showMessage('Unable to send fax.');
    } finally {
      if (mounted) {
        setState(() {
          _sending = false;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Send Fax')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
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
