import 'dart:async';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';

import '../models/fax_model.dart';
import '../services/fax_api_service.dart';
import '../services/fax_platform_api.dart';
import '../widgets/fax_status_chip.dart';

class FaxDocumentViewScreen extends StatefulWidget {
  final FaxModel fax;

  const FaxDocumentViewScreen({super.key, required this.fax});

  @override
  State<FaxDocumentViewScreen> createState() => _FaxDocumentViewScreenState();
}

class _FaxDocumentViewScreenState extends State<FaxDocumentViewScreen> {
  late FaxModel _fax;
  bool _opening = false;
  bool _saving = false;
  bool _refreshing = false;
  Map<String, dynamic>? _receiveBill;

  bool get _documentBusy => _opening || _saving;

  @override
  void initState() {
    super.initState();
    _fax = widget.fax;
    _refreshStatus();
  }

  Future<void> _refreshStatus({bool showError = false}) async {
    if (_refreshing || !mounted) return;

    setState(() => _refreshing = true);

    try {
      final history = await FaxApiService.getHistory().timeout(
        const Duration(seconds: 20),
      );
      if (!mounted) return;

      FaxModel? updatedFax;
      for (final fax in history) {
        if (fax.id == _fax.id) {
          updatedFax = fax;
          break;
        }
      }

      Map<String, dynamic>? bill;
      if (_fax.direction.toLowerCase() == 'inbound') {
        bill = await FaxPlatformApi.request('/billing/${_fax.id}');
        if (!mounted) return;
      }
      setState(() => _receiveBill = bill);
      final matchingFax = updatedFax;
      if (matchingFax != null) {
        setState(() => _fax = matchingFax);
      } else if (showError) {
        _showMessage('Fax details were not found. Please refresh Fax History.');
      }
    } on FaxApiException catch (e) {
      if (showError) _showMessage(e.message);
    } on TimeoutException catch (_) {
      if (showError) _showMessage('Status update timed out. Please try again.');
    } catch (_) {
      if (showError) {
        _showMessage('Unable to update fax status. Please try again.');
      }
    } finally {
      if (mounted) setState(() => _refreshing = false);
    }
  }

  Future<bool> _confirmReceiveFee() async {
    if (_fax.direction.toLowerCase() != 'inbound') return true;
    final bill = await FaxPlatformApi.request('/billing/${_fax.id}');
    if (!mounted) return false;
    if (bill['billing_pending'] == true) {
      _showMessage('Your fax is received. Provider billing is pending; try opening it again later.');
      return false;
    }
    if (bill['payment_required'] != true) return true;
    setState(() => _receiveBill = bill);
    _showMessage('Receive fee unpaid. Recharge for automatic payment, or use the Pay Receive Fee button.');
    return false;
  }

  Future<void> _payReceiveFee() async {
    if (_documentBusy) return;
    setState(() => _opening = true);
    try {
      final bill = await FaxPlatformApi.request('/billing/${_fax.id}');
      if (bill['payment_required'] == true && bill['billing_pending'] != true) {
        await FaxPlatformApi.request('/billing/${_fax.id}/pay', method: 'POST', body: {
          'expected_amount_microusd': bill['amount_microusd'],
        });
      }
      await _refreshStatus(showError: true);
    } on FaxApiException catch (e) {
      _showMessage(e.message);
    } catch (_) {
      _showMessage('Payment could not be confirmed. Refresh before trying again.');
    } finally {
      if (mounted) setState(() => _opening = false);
    }
  }

  Future<void> _openDocument() async {
    if (_documentBusy) return;

    setState(() => _opening = true);

    try {
      if (!await _confirmReceiveFee()) return;
      final File file = await FaxApiService.downloadDocument(
        faxId: _fax.id,
      ).timeout(const Duration(seconds: 45));
      if (!mounted) return;

      final result = await OpenFilex.open(file.path);
      if (result.type != ResultType.done) {
        _showMessage('Unable to open the document. Check your document viewer.');
      }
    } on FaxApiException catch (e) {
      _showMessage(e.message);
    } on TimeoutException catch (_) {
      _showMessage('Document download timed out. Please try again.');
    } catch (_) {
      _showMessage('Unable to open fax document.');
    } finally {
      if (mounted) setState(() => _opening = false);
    }
  }

  Future<void> _downloadDocument() async {
    if (_documentBusy) return;

    setState(() => _saving = true);

    try {
      // The existing API checks the logged-in user's document ownership.
      if (!await _confirmReceiveFee()) return;
      final File file = await FaxApiService.downloadDocument(
        faxId: _fax.id,
        forceDownload: true,
      ).timeout(const Duration(seconds: 45));
      final bytes = await file.readAsBytes();
      if (!mounted) return;

      if (bytes.isEmpty) {
        _showMessage('The fax document is empty. Please try again.');
        return;
      }

      final extension = file.path.toLowerCase().endsWith('.png')
          ? 'png'
          : file.path.toLowerCase().endsWith('.jpg')
          ? 'jpg'
          : 'pdf';

      // file_picker 11 saves the supplied bytes through the native picker.
      // A cancelled dialog returns null and does not count as a saved file.
      final savedFile = await FilePicker.saveFile(
        dialogTitle: 'Save fax document',
        fileName: 'NetPhone_Fax_${_fax.id}.$extension',
        type: FileType.custom,
        allowedExtensions: [extension],
        bytes: bytes,
      );

      if (savedFile != null) {
        _showMessage('Document saved.', backgroundColor: Colors.green.shade700);
      }
    } on FaxApiException catch (e) {
      _showMessage(e.message);
    } on TimeoutException catch (_) {
      _showMessage('Document download timed out. Please try again.');
    } catch (_) {
      _showMessage('Unable to save fax document. Please try again.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _showMessage(String message, {Color? backgroundColor}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: backgroundColor),
    );
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

  Widget _progressIcon() {
    return const SizedBox(
      height: 20,
      width: 20,
      child: CircularProgressIndicator(strokeWidth: 2),
    );
  }

  @override
  Widget build(BuildContext context) {
    final fax = _fax;
    final reason = fax.failureReason?.trim();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Fax Details'),
        actions: [
          IconButton(
            tooltip: 'Refresh fax status',
            onPressed: _refreshing
                ? null
                : () => _refreshStatus(showError: true),
            icon: _refreshing ? _progressIcon() : const Icon(Icons.refresh),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => _refreshStatus(showError: true),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(18),
          children: [
            Center(child: FaxStatusChip(status: fax.status)),
            const SizedBox(height: 28),
            _row('Direction', fax.direction.isEmpty ? '-' : fax.direction),
            _row('From', fax.fromNumber ?? '-'),
            _row('To', fax.toNumber ?? '-'),
            _row('Sender', fax.senderName ?? '-'),
            _row('Pages', fax.pages?.toString() ?? '-'),
            if (reason != null && reason.isNotEmpty)
              _row(
                reason == 'submission_unconfirmed' ? 'Status' : 'Reason',
                reason == 'submission_unconfirmed'
                    ? 'Submission not confirmed. Refresh the status before trying again.'
                    : reason,
              ),
            if (_receiveBill?['payment_required'] == true && _receiveBill?['billing_pending'] != true)
              Padding(padding: const EdgeInsets.only(bottom: 12), child: FilledButton(
                onPressed: _documentBusy ? null : _payReceiveFee,
                child: Text('Pay Receive Fee ${FaxPlatformApi.usd(_receiveBill?['amount_usd'])}'),
              )),
            const SizedBox(height: 16),
            SizedBox(
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _documentBusy ? null : _openDocument,
                icon: _opening
                    ? _progressIcon()
                    : const Icon(Icons.description_outlined),
                label: Text(_opening ? 'Opening...' : 'View Document'),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 52,
              child: OutlinedButton.icon(
                onPressed: _documentBusy ? null : _downloadDocument,
                icon: _saving
                    ? _progressIcon()
                    : const Icon(Icons.download_outlined),
                label: Text(_saving ? 'Downloading...' : 'Download Document'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
