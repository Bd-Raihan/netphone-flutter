/// ==========================================================
/// admin_rate_import_screen.dart
///
/// কাজ:
/// - Provider নির্বাচন
/// - Server storage-এর CSV file list দেখা
/// - CSV validate করা
/// - Validation summary দেখানো
/// - CSV import এবং rate-card activation করা
///
/// গুরুত্বপূর্ণ:
/// - এই screen শুধু Admin user-এর Drawer-এ দেখাবে
/// - বর্তমানে local device থেকে CSV upload করে না
/// - Backend storage-এর existing CSV নিয়ন্ত্রণ করে
/// ==========================================================

import 'package:flutter/material.dart';

import '../data/admin_rate_import_api_service.dart';
import '../models/admin_rate_import_models.dart';

class AdminRateImportScreen extends StatefulWidget {
  const AdminRateImportScreen({super.key});

  @override
  State<AdminRateImportScreen> createState() => _AdminRateImportScreenState();
}

class _AdminRateImportScreenState extends State<AdminRateImportScreen> {
  final List<String> _providers = const ['telnyx'];

  final List<String> _plans = const ['payg', 'starter', 'growth', 'enterprise'];

  String _selectedProvider = 'telnyx';
  String _selectedPlan = 'payg';
  String? _selectedFile;

  bool _loadingFiles = false;
  bool _validating = false;
  bool _importing = false;

  List<ProviderRateDeckFile> _files = [];

  RateDeckValidationResult? _validationResult;
  RateDeckImportResult? _importResult;

  @override
  void initState() {
    super.initState();
    _loadFiles();
  }

  Future<void> _loadFiles() async {
    if (_loadingFiles) return;

    setState(() {
      _loadingFiles = true;
      _validationResult = null;
      _importResult = null;
    });

    try {
      final result = await AdminRateImportApiService.listFiles(
        provider: _selectedProvider,
      );

      if (!mounted) return;

      setState(() {
        _files = result.files;

        if (_files.isEmpty) {
          _selectedFile = null;
        } else {
          final selectedStillExists = _files.any(
            (item) => item.file == _selectedFile,
          );

          _selectedFile = selectedStillExists
              ? _selectedFile
              : _files.first.file;
        }
      });
    } catch (error) {
      if (!mounted) return;
      _showError(error);
    } finally {
      if (mounted) {
        setState(() {
          _loadingFiles = false;
        });
      }
    }
  }

  Future<void> _validateSelectedFile() async {
    final file = _selectedFile;

    if (file == null || file.isEmpty) {
      _showMessage('Select a CSV file first.');
      return;
    }

    setState(() {
      _validating = true;
      _validationResult = null;
      _importResult = null;
    });

    try {
      final result = await AdminRateImportApiService.validateRateDeck(
        provider: _selectedProvider,
        file: file,
        sampleLimit: 3,
      );

      if (!mounted) return;

      setState(() {
        _validationResult = result;
      });

      _showMessage('Rate deck validation completed.');
    } catch (error) {
      if (!mounted) return;
      _showError(error);
    } finally {
      if (mounted) {
        setState(() {
          _validating = false;
        });
      }
    }
  }

  Future<void> _confirmImport() async {
    final validation = _validationResult;

    if (validation == null) {
      _showMessage('Validate the CSV file before importing.');
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Import Rate Deck?'),
          content: Text(
            'Provider: $_selectedProvider\n'
            'Plan: $_selectedPlan\n'
            'File: ${validation.sourceFile}\n'
            'Unique prefixes: '
            '${validation.uniquePrefixes}\n\n'
            'A successful import may activate the new '
            'provider rate card.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              child: const Text('Import'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      await _importSelectedFile();
    }
  }

  Future<void> _importSelectedFile() async {
    final file = _selectedFile;

    if (file == null || file.isEmpty) {
      return;
    }

    setState(() {
      _importing = true;
      _importResult = null;
    });

    try {
      final result = await AdminRateImportApiService.importRateDeck(
        provider: _selectedProvider,
        plan: _selectedPlan,
        file: file,
        batchSize: 500,
        allowDuplicateChecksum: false,
      );

      if (!mounted) return;

      setState(() {
        _importResult = result;
      });

      _showMessage(
        result.duplicateImport
            ? 'This rate deck was already imported.'
            : 'Rate deck imported and activated successfully.',
      );
    } catch (error) {
      if (!mounted) return;
      _showError(error);
    } finally {
      if (mounted) {
        setState(() {
          _importing = false;
        });
      }
    }
  }

  void _showError(Object error) {
    _showMessage(error.toString(), isError: true);
  }

  void _showMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: isError ? Colors.red : null,
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final busy = _loadingFiles || _validating || _importing;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Rate Management'),
        actions: [
          IconButton(
            onPressed: busy ? null : _loadFiles,
            tooltip: 'Refresh CSV files',
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadFiles,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildProviderCard(),
            const SizedBox(height: 16),
            _buildFileCard(),
            const SizedBox(height: 16),

            if (_validationResult != null)
              _buildValidationCard(_validationResult!),

            if (_validationResult != null) const SizedBox(height: 16),

            if (_importResult != null) _buildImportResultCard(_importResult!),
          ],
        ),
      ),
    );
  }

  Widget _buildProviderCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Provider Configuration',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            DropdownButtonFormField<String>(
              value: _selectedProvider,
              decoration: const InputDecoration(
                labelText: 'Voice Provider',
                border: OutlineInputBorder(),
              ),
              items: _providers
                  .map(
                    (provider) => DropdownMenuItem(
                      value: provider,
                      child: Text(provider.toUpperCase()),
                    ),
                  )
                  .toList(),
              onChanged: _loadingFiles
                  ? null
                  : (value) {
                      if (value == null) return;

                      setState(() {
                        _selectedProvider = value;
                        _selectedFile = null;
                        _validationResult = null;
                        _importResult = null;
                      });

                      _loadFiles();
                    },
            ),

            const SizedBox(height: 16),

            DropdownButtonFormField<String>(
              value: _selectedPlan,
              decoration: const InputDecoration(
                labelText: 'Provider Plan',
                border: OutlineInputBorder(),
              ),
              items: _plans
                  .map(
                    (plan) => DropdownMenuItem(
                      value: plan,
                      child: Text(plan.toUpperCase()),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value == null) return;

                setState(() {
                  _selectedPlan = value;
                  _importResult = null;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFileCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Provider Rate Deck',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            const Text(
              'These files already exist in the '
              'Backend provider storage folder.',
            ),

            const SizedBox(height: 16),

            if (_loadingFiles)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_files.isEmpty)
              const Text('No CSV rate deck was found.')
            else ...[
              DropdownButtonFormField<String>(
                value: _selectedFile,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'CSV File',
                  border: OutlineInputBorder(),
                ),
                items: _files
                    .map(
                      (item) => DropdownMenuItem(
                        value: item.file,
                        child: Text(
                          '${item.file} '
                          '(${item.readableSize})',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedFile = value;
                    _validationResult = null;
                    _importResult = null;
                  });
                },
              ),

              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _validating || _importing
                          ? null
                          : _validateSelectedFile,
                      icon: _validating
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.fact_check),
                      label: const Text('Validate'),
                    ),
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: FilledButton.icon(
                      onPressed: _validationResult == null || _importing
                          ? null
                          : _confirmImport,
                      icon: _importing
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.cloud_upload),
                      label: const Text('Import'),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildValidationCard(RateDeckValidationResult result) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.verified, color: Colors.green),
                SizedBox(width: 8),
                Text(
                  'Validation Summary',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const Divider(height: 28),

            _summaryRow('Source File', result.sourceFile),
            _summaryRow('Total Data Rows', '${result.dataRowsRead}'),
            _summaryRow('Valid Rows', '${result.validRows}'),
            _summaryRow('Unique Prefixes', '${result.uniquePrefixes}'),
            _summaryRow('Duplicate Rows', '${result.duplicatePrefixRows}'),
            _summaryRow('Skipped Rows', '${result.skippedRows}'),

            if (result.sourceSha256.isNotEmpty)
              _summaryRow(
                'SHA-256',
                '${result.sourceSha256.substring(0, 16)}…',
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildImportResultCard(RateDeckImportResult result) {
    final duplicate = result.duplicateImport;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  duplicate ? Icons.info : Icons.check_circle,
                  color: duplicate ? Colors.orange : Colors.green,
                ),
                const SizedBox(width: 8),
                Text(
                  duplicate ? 'Already Imported' : 'Import Completed',
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(height: 28),

            _summaryRow('Provider', result.providerCode.toUpperCase()),
            _summaryRow('Plan', result.providerPlanCode.toUpperCase()),
            _summaryRow('Source File', result.sourceFile),

            if (result.rateCardCode != null)
              _summaryRow('Rate Card', result.rateCardCode!),

            if (!duplicate)
              _summaryRow('Unique Rates', '${result.uniqueRatesImported}'),
          ],
        ),
      ),
    );
  }

  Widget _summaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(flex: 3, child: Text(value, textAlign: TextAlign.right)),
        ],
      ),
    );
  }
}
