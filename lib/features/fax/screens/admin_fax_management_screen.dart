import '../widgets/fax_blue_theme.dart';
import 'admin_fax_pricing_screen.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:open_filex/open_filex.dart';
import '../services/fax_platform_api.dart';

class AdminFaxManagementScreen extends StatefulWidget {
  final bool inboxOnly;
  const AdminFaxManagementScreen({super.key, this.inboxOnly = false});
  @override
  State<AdminFaxManagementScreen> createState() => _AdminFaxManagementScreenState();
}

class _AdminFaxManagementScreenState extends State<AdminFaxManagementScreen> {
  List<Map<String, dynamic>> _rates = [], _inbox = [];
  bool _loading = true, _busy = false, _adminVerified = false;
  String? _error;
  String? _lastUpload;
  Map<String, dynamic> _actual = {}; 

  @override
  void initState() {super.initState(); _load();}

  List<Map<String, dynamic>> _items(dynamic value) => value is List
    ? value.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList() : [];

  Future<void> _load() async {
    try {
      final profile = await FaxPlatformApi.request('/receive-profile');
      if (!mounted) return;
      if (profile['is_admin'] != true) {
        setState(() { _adminVerified = false; _loading = false; _error = 'Admin access required.'; });
        return;
      }
      _adminVerified = true;
      final results = await Future.wait([
        FaxPlatformApi.request('/admin/rates'),
        FaxPlatformApi.request('/admin/inbox'),
        FaxPlatformApi.request('/admin/actual-billing'),
      ]);
      if (!mounted) return;
      setState(() {
        _rates = _items(results[0]['rates']); _inbox = _items(results[1]['faxes']);
        _actual = results[2]; _error = null;
      });
    } catch (error) {
      if (mounted) setState(() {_error = error.toString();});
    } finally {
      if (mounted) setState(() {_loading = false;});
    }
  }

  void _message(String message) {
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _importCsv(bool deck) async {
    if (_busy) return;
    setState(() { _busy = true; });
    try {
      // CSV MIME labels differ across Android document providers. Validate after selection.
      final picked = await FilePicker.pickFiles(type: FileType.any, withData: true);
      if (picked == null || !mounted) return;
      final file = picked.files.single;
      if (!file.name.toLowerCase().endsWith('.csv')) {
        throw Exception('Choose the extracted .csv file. ZIP, PDF and Excel .xlsx files cannot be imported.');
      }
      if (file.size > 48 * 1024 * 1024) throw Exception('Choose a CSV under 48 MB.');
      final bytes = file.bytes ?? (file.path == null ? null : await File(file.path!).readAsBytes());
      if (bytes == null || bytes.isEmpty) {
        throw Exception('This file is empty (0 B). Download/extract the original CSV again, then select it.');
      }
      if (bytes.length > 48 * 1024 * 1024) throw Exception('Choose a CSV under 48 MB.');
      if (!mounted) return;
      setState(() { _lastUpload = 'Uploading: ${file.name}'; });
      final result = await FaxPlatformApi.importCsv(deck ? '/admin/fax-deck' : '/admin/fax-usage', bytes);
      final message = deck ? 'Rate chart imported: ${result['rows']} routes.'
        : 'Usage imported: ${result['accepted']} records; ${result['unrelated']} unrelated; ${result['rejected']} rejected.';
      if (mounted) setState(() { _lastUpload = '${file.name} — $message'; });
      _message(message);
      await _load();
    } catch (e) {
      if (mounted) setState(() { _lastUpload = 'Upload failed. Select a valid CSV and try again.'; });
      _message(e.toString());
    } finally { if (mounted) setState(() { _busy = false; }); }
  }

  Future<void> _syncUsage() async {
    if (_busy) return;
    setState(() { _busy = true; });
    try {
      await FaxPlatformApi.request('/admin/fax-usage/sync', method: 'POST');
      _message('Telnyx usage sync completed.');
    } catch (e) { _message(e.toString()); }
    finally { await _load(); if (mounted) setState(() { _busy = false; }); }
  }

  Future<void> _estimate() async {
    var seconds = (_actual['estimate_seconds_per_page'] ?? 120).toString();
    final approved = await showDialog<bool>(context: context, builder: (context) => AlertDialog(backgroundColor: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF16232F) : Colors.white, surfaceTintColor: Colors.transparent, 
      title: const Text('Send reserve estimate'),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        const Text('Seconds per page used for the prepaid ceiling. Actual provider costs can exceed this estimate; the operator absorbs the difference. This is not a transmission time limit.'),
        TextFormField(initialValue: seconds, keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Seconds per page: 60–3600'), onChanged: (value) => seconds = value),
      ]),
      actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
        FilledButton(style: FilledButton.styleFrom(backgroundColor: const Color(0xFF168FE5), foregroundColor: Colors.white), onPressed: () => Navigator.pop(context, true), child: const Text('Save'))],
    ));
    if (approved != true || !mounted) return;
    try { await FaxPlatformApi.request('/admin/actual-billing', method: 'PATCH', body: {'estimate_seconds_per_page': int.tryParse(seconds)}); await _load(); }
    catch (e) { _message(e.toString()); }
  }

  Widget _field(String initialValue, ValueChanged<String> onChanged, String label, {bool numeric = false, bool optional = false, String? hint, String? Function(String?)? validate}) =>
    Padding(padding: const EdgeInsets.only(bottom: 12), child: TextFormField(
      key: label.startsWith('Number prefix') ? ValueKey(initialValue) : null,
      initialValue: initialValue,
      onChanged: onChanged,
      keyboardType: numeric ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text,
      decoration: InputDecoration(labelText: label, helperText: hint),
      validator: (text) => !optional && (text == null || text.trim().isEmpty) ? 'Required' : validate?.call(text),
    ));

  Future<void> _view(Map<String, dynamic> fax) async {
    if (_busy) return;
    setState(() {_busy = true;});
    try {
      final file = await FaxPlatformApi.adminDocument(int.parse(fax['id'].toString()));
      if (!mounted) return;
      final opened = await OpenFilex.open(file.path);
      if (opened.type != ResultType.done) _message('No PDF viewer is available.');
    } catch (error) {_message(error.toString());}
    finally {if (mounted) setState(() {_busy = false;});}
  }

  Future<void> _assign(Map<String, dynamic> fax) async {
    var code = '', reference = '';
    var assigned = false;
    var verified = false, saving = false;
    String? error;
    await showDialog<void>(context: context, barrierDismissible: false, builder: (dialogContext) =>
        StatefulBuilder(builder: (context, update) => AlertDialog(backgroundColor: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF16232F) : Colors.white, surfaceTintColor: Colors.transparent, 
          title: const Text('Assign Incoming Fax'),
          content: SizedBox(width: 420, child: SingleChildScrollView(child: Column(
            mainAxisSize: MainAxisSize.min, children: [
              const Text('Open the PDF first. Verify its Receive ID and intended recipient. '
                'The recipient cannot be changed after assignment.'),
              const SizedBox(height: 12),
              TextField(onChanged: (value) => code = value, decoration: const InputDecoration(labelText: 'Recipient Receive ID')),
              TextField(onChanged: (value) => reference = value, maxLength: 300,
                decoration: const InputDecoration(labelText: 'How did you verify the recipient?')),
              CheckboxListTile(contentPadding: EdgeInsets.zero, value: verified,
                title: const Text('I checked the document and verified this recipient.'),
                onChanged: saving ? null : (value) => update(() {verified = value == true;})),
              if (error != null) Text(error!, style: const TextStyle(color: Colors.red)),
            ]))),
          actions: [TextButton(onPressed: saving ? null : () => Navigator.pop(dialogContext), child: const Text('Cancel')),
            FilledButton(style: FilledButton.styleFrom(backgroundColor: const Color(0xFF168FE5), foregroundColor: Colors.white), onPressed: saving || !verified ? null : () async {
              update(() {saving = true; error = null;});
              try {
                await FaxPlatformApi.request('/admin/inbox/${fax['id']}/assign', method: 'POST', body: {
                  'receive_code': code.trim(), 'verified_reference': reference.trim(),
                  'recipient_verified': verified,
                });
                assigned = true;
                if (dialogContext.mounted) {
                  FocusScope.of(dialogContext).unfocus();
                  Navigator.pop(dialogContext);
                }
              } catch (e) {
                if (dialogContext.mounted) update(() {saving = false; error = e.toString();});
              }
            }, child: Text(saving ? 'Assigning...' : 'Assign'))],
        )));
    if (!mounted || !assigned) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Fax assigned successfully.')),
    );
    await _load();
  }

  String _date(dynamic value) {
    final date = DateTime.tryParse(value?.toString() ?? '');
    return date == null ? '-' : DateFormat('dd MMM yyyy, hh:mm a').format(date.toLocal());
  }

  Widget _stepCard(String title, String description, List<Widget> actions) => Card(
    margin: const EdgeInsets.only(bottom: 14),
    child: Padding(padding: const EdgeInsets.all(16), child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        Text(description, style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: 12),
        ...actions,
      ],
    )),
  );

  Widget _uploadButton(String label, VoidCallback action, {bool secondary = false}) {
    final style = FilledButton.styleFrom(
      backgroundColor: secondary ? const Color(0xFFE3F2FD) : const Color(0xFF168FE5),
      foregroundColor: secondary ? const Color(0xFF075A95) : Colors.white,
      minimumSize: const Size(0, 48),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    );
    return FilledButton.icon(style: style, onPressed: _busy ? null : action,
      icon: const Icon(Icons.upload_file, size: 20),
      label: Text(label, textAlign: TextAlign.center));
  }

  @override
  Widget build(BuildContext context) => FaxBlueTheme(builder: _buildFax);

  Widget _buildFax(BuildContext context) => DefaultTabController(length: 1, child: Scaffold(
    appBar: AppBar(title: Text(widget.inboxOnly ? 'Admin Fax Inbox' : 'Fax Rate Management'), actions: [
      IconButton(onPressed: _load, tooltip: 'Refresh', icon: const Icon(Icons.refresh)),
    ], bottom: TabBar(tabs: [Tab(text: widget.inboxOnly ? 'Private Inbox' : 'Fax Rates')])),
    body: _loading ? const Center(child: CircularProgressIndicator()) : !_adminVerified
      ? Center(child: Text(_error ?? 'Admin access required.')) : Column(children: [
      if (_error != null) Padding(padding: const EdgeInsets.all(12), child: Text(_error!, style: const TextStyle(color: Colors.red))),
      Expanded(child: TabBarView(children: [
        if (!widget.inboxOnly) RefreshIndicator(onRefresh: _load, child: ListView(padding: const EdgeInsets.all(16), children: [
          _stepCard('Country rates & manual control',
            'Browse provider rates by country. Set a minimum selling price per page; automatic actual-cost billing continues.', [
              FilledButton.icon(onPressed: _busy ? null : () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminFaxPricingScreen())), icon: const Icon(Icons.price_change), label: const Text('View / Edit country rates')),
            ]),
          _stepCard('Fax rate chart',
            'Upload the Telnyx Global Conversational rate CSV. Extract the ZIP first.', [
              _uploadButton('Upload rate CSV', () => _importCsv(true)),
              const SizedBox(height: 10),
              Text(_actual['deck_version'] == null ? 'Status: Not uploaded' : 'Status: Rate chart ready'),
            ]),
          const Card(child: Padding(padding: EdgeInsets.all(16), child: Text(
            'Fax charging is automatic. Final fees use provider cost + 55%, or your higher page minimum.'))),
          if (_actual['usage_sync_error'] != null || _actual['adapter_verified'] != true)
            const Padding(padding: EdgeInsets.all(12), child: Text(
              'Billing needs attention. New sends may be unavailable. Open Troubleshooting below.',
              style: TextStyle(color: Colors.red))),
          if (_busy) const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: LinearProgressIndicator()),
          if (_lastUpload != null) Padding(padding: const EdgeInsets.only(bottom: 14), child: Text(_lastUpload!)),
          Card(margin: const EdgeInsets.only(bottom: 14), child: ExpansionTile(
            title: const Text('Troubleshooting'),
            subtitle: const Text('Use when automatic sync needs review'),
            childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            children: [
              TextButton(onPressed: _busy ? null : _syncUsage, child: const Text('Retry billing sync')),
              Text('Last sync: ${_actual['last_usage_sync'] == null ? 'Pending' : _date(_actual['last_usage_sync'])}'),
              const Text('Upload Fax API and Calls CSV reports for the same dates. Reports do not replace the rate chart.'),
              const SizedBox(height: 12),
              SizedBox(width: double.infinity, child: _uploadButton('Upload usage CSV', () => _importCsv(false), secondary: true)),
            ],
          )),
          Card(margin: const EdgeInsets.only(bottom: 14), child: ExpansionTile(
            title: const Text('Billing details'),
            childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            children: [
              const Text('Final fee = the higher of (actual Fax API + SIP cost) × 1.55 and your manual per-page minimum. Unused Send prepayment is refunded. The customer is never charged above the approved ceiling. Failed transmissions may incur fees.'),
              const SizedBox(height: 8),
              const Text('Costs above the Send ceiling are absorbed by the operator. The estimate is not a transmission time limit.'),
              TextButton(onPressed: _busy ? null : _estimate, child: const Text('Send prepayment estimate')),
              Text('Previous rate entries retained: ${_rates.length}'),
              if (_actual['usage_sync_error'] != null) Text(_actual['usage_sync_error'].toString(),
                style: TextStyle(color: Theme.of(context).colorScheme.error)),
            ],
          )),
          const Text('Recent fax bills', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
          if (_items(_actual['bills']).isEmpty) const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Text('No new paid fax bills yet.')),
          for (final bill in _items(_actual['bills'])) Card(child: ListTile(
            title: Text("Fax ${bill['fax_id']} · ${bill['direction']} · ${bill['state']}"),
            subtitle: Text("${bill['actual_settled'] == true ? 'Final' : 'Awaiting provider billing'} · ${FaxPlatformApi.usd(bill['amount_usd'])}\nProvider cost: ${bill['provider_cost_usd'] == null ? 'Pending' : FaxPlatformApi.usd(bill['provider_cost_usd'])}\nAPI: ${bill['billing_details']?['api_cost_usd'] ?? '-'} USD · SIP: ${bill['billing_details']?['sip_cost_usd'] ?? '-'} USD\nBilled seconds: ${bill['billing_details']?['billed_seconds'] ?? 'Not reported'}\nRefund: ${bill['refund_usd'] == null ? '-' : FaxPlatformApi.usd(bill['refund_usd'])} · Operator absorbs: ${FaxPlatformApi.usd(bill['shortfall_usd'])}"),
          )),
        ])),
        if (widget.inboxOnly) RefreshIndicator(onRefresh: _load, child: ListView(padding: const EdgeInsets.all(16), children: [
          OutlinedButton.icon(icon: const Icon(Icons.sync), label: const Text('Check received faxes'), onPressed: _busy ? null : () async {
            try {
              await FaxPlatformApi.request('/admin/inbox/scan', method: 'POST');
              _message('Checking incoming faxes. Refresh this inbox shortly.');
            } catch (e) {_message(e.toString());}
          }),
          const SizedBox(height: 12),
          if (_inbox.isEmpty) const Text('No incoming PDFs imported yet.'),
          for (final fax in _inbox) Card(child: Padding(padding: const EdgeInsets.all(14), child: Column(
            crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('From: ${fax['from_number']}', style: const TextStyle(fontWeight: FontWeight.bold)),
              Text('${fax['pages']} pages · ${_date(fax['created_at'])}'),
              Text(fax['user_id'] == null ? 'Awaiting recipient verification' : 'Assigned: ${fax['assigned_phone']}'),
              if (fax['source'] == 'legacy_archive') const Text('Archived copy. Verify the document before assignment.'),
              const SizedBox(height: 10),
              Wrap(spacing: 12, children: [
                OutlinedButton(onPressed: _busy ? null : () => _view(fax), child: const Text('Review PDF')),
                if (fax['user_id'] == null) FilledButton(style: FilledButton.styleFrom(backgroundColor: const Color(0xFF168FE5), foregroundColor: Colors.white), onPressed: _busy ? null : () => _assign(fax), child: const Text('Assign Recipient')),
              ]),
            ]))),
        ])),
      ])),
    ]),
  ));
}
