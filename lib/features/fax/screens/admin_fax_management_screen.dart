import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:open_filex/open_filex.dart';
import '../services/fax_platform_api.dart';

class AdminFaxManagementScreen extends StatefulWidget {
  const AdminFaxManagementScreen({super.key});
  @override
  State<AdminFaxManagementScreen> createState() => _AdminFaxManagementScreenState();
}

class _AdminFaxManagementScreenState extends State<AdminFaxManagementScreen> {
  List<Map<String, dynamic>> _rates = [], _inbox = [];
  bool _loading = true, _charging = false, _busy = false;
  String? _error;

  @override
  void initState() {super.initState(); _load();}

  List<Map<String, dynamic>> _items(dynamic value) => value is List
    ? value.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList() : [];

  Future<void> _load() async {
    try {
      final results = await Future.wait([
        FaxPlatformApi.request('/admin/rates'),
        FaxPlatformApi.request('/admin/inbox'),
      ]);
      if (!mounted) return;
      setState(() {
        _rates = _items(results[0]['rates']); _inbox = _items(results[1]['faxes']);
        _charging = results[0]['billing_enabled'] == true; _error = null;
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

  Future<void> _toggle(bool enabled) async {
    if (_busy) return;
    if (enabled) {
      final approved = await showDialog<bool>(context: context, builder: (context) => AlertDialog(
        title: const Text('Enable fax charging?'),
        content: const Text('Enable after verified rates and the updated app are ready. '
          'Users must confirm the fee before sending. Older app versions will need an update to send faxes.'),
        actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Enable'))]));
      if (approved != true || !mounted) return;
    }
    setState(() {_busy = true;});
    try {
      await FaxPlatformApi.request('/admin/settings', method: 'PATCH', body: {'billing_enabled': enabled});
      await _load();
    } catch (error) {_message(error.toString());}
    finally {if (mounted) setState(() {_busy = false;});}
  }

  Future<void> _editRate([Map<String, dynamic>? rate]) async {
    final country = TextEditingController(text: rate?['country_name']?.toString() ?? '');
    final code = TextEditingController(text: rate?['country_code']?.toString() ?? '');
    final prefix = TextEditingController(text: rate?['phone_prefix']?.toString() ?? '');
    final cost = TextEditingController(text: rate?['provider_cost_usd_per_page']?.toString() ?? '');
    final markup = TextEditingController(text: rate?['markup_percent']?.toString() ?? '40');
    final manual = TextEditingController(text: rate?['manual_sell_usd_per_page']?.toString() ?? '');
    var direction = rate?['direction']?.toString() ?? 'outbound';
    var active = rate?['is_active'] == true, confirmed = rate?['cost_confirmed'] == true, saving = false;
    String? error;
    final key = GlobalKey<FormState>();
    try {
      await showDialog<void>(context: context, barrierDismissible: false, builder: (dialogContext) =>
        StatefulBuilder(builder: (context, update) => AlertDialog(
          title: Text(rate == null ? 'Add Fax Rate' : 'Edit Fax Rate'),
          content: SizedBox(width: 480, child: SingleChildScrollView(child: Form(key: key, child: Column(
            mainAxisSize: MainAxisSize.min, children: [
              _field(country, 'Country / region'), _field(code, 'Country code (e.g. US)'),
              _field(prefix, 'Phone prefix (e.g. 1205)'),
              DropdownButtonFormField<String>(value: direction,
                decoration: const InputDecoration(labelText: 'Direction'),
                items: const [DropdownMenuItem(value: 'outbound', child: Text('Send')),
                  DropdownMenuItem(value: 'inbound', child: Text('Receive'))],
                onChanged: saving ? null : (value) => update(() {direction = value!;})),
              _field(cost, 'Total provider cost / page (USD)', numeric: true),
              const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Text(
                'Include Fax API and allocated SIP transmission cost. Receive pricing follows the receiving number.')),
              _field(markup, 'Markup % (40 = cost × 1.40)', numeric: true),
              _field(manual, 'Manual sell rate / page (optional)', numeric: true, optional: true),
              CheckboxListTile(contentPadding: EdgeInsets.zero, value: confirmed,
                title: const Text('I verified the complete provider cost.'),
                onChanged: saving ? null : (value) => update(() {confirmed = value == true;})),
              SwitchListTile(contentPadding: EdgeInsets.zero, value: active, title: const Text('Active'),
                onChanged: saving ? null : (value) => update(() {active = value;})),
              if (error != null) Text(error!, style: const TextStyle(color: Colors.red)),
            ])))),
          actions: [TextButton(onPressed: saving ? null : () => Navigator.pop(dialogContext), child: const Text('Cancel')),
            FilledButton(onPressed: saving ? null : () async {
              if (!key.currentState!.validate()) return;
              update(() {saving = true; error = null;});
              try {
                await FaxPlatformApi.request('/admin/rates', method: 'POST', body: {
                  if (rate != null) 'id': rate['id'], if (rate != null) 'revision': rate['revision'],
                  'country_name': country.text.trim(), 'country_code': code.text.trim(),
                  'phone_prefix': prefix.text.trim(), 'direction': direction,
                  'provider_cost_usd_per_page': cost.text.trim(),
                  'markup_percent': double.tryParse(markup.text.trim()),
                  'manual_sell_usd_per_page': manual.text.trim().isEmpty ? null : manual.text.trim(),
                  'cost_confirmed': confirmed, 'is_active': active,
                });
                if (dialogContext.mounted) Navigator.pop(dialogContext);
                await _load();
              } catch (e) {
                if (dialogContext.mounted) update(() {saving = false; error = e.toString();});
              }
            }, child: Text(saving ? 'Saving...' : 'Save'))],
        )));
    } finally {
      for (final controller in [country, code, prefix, cost, markup, manual]) {controller.dispose();}
    }
  }

  Widget _field(TextEditingController controller, String label, {bool numeric = false, bool optional = false}) =>
    Padding(padding: const EdgeInsets.only(bottom: 12), child: TextFormField(
      controller: controller,
      keyboardType: numeric ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text,
      decoration: InputDecoration(labelText: label),
      validator: (text) => !optional && (text == null || text.trim().isEmpty) ? 'Required' : null,
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
    final code = TextEditingController(), reference = TextEditingController();
    var verified = false, waive = false, saving = false;
    String? error;
    try {
      await showDialog<void>(context: context, barrierDismissible: false, builder: (dialogContext) =>
        StatefulBuilder(builder: (context, update) => AlertDialog(
          title: const Text('Assign Incoming Fax'),
          content: SizedBox(width: 420, child: SingleChildScrollView(child: Column(
            mainAxisSize: MainAxisSize.min, children: [
              const Text('Open the PDF first. Verify its Receive ID and intended recipient. '
                'The recipient cannot be changed after assignment.'),
              const SizedBox(height: 12),
              TextField(controller: code, decoration: const InputDecoration(labelText: 'Recipient Receive ID')),
              TextField(controller: reference, maxLength: 300,
                decoration: const InputDecoration(labelText: 'Verification reference (without sensitive content)')),
              CheckboxListTile(contentPadding: EdgeInsets.zero, value: verified,
                title: const Text('I checked the document and verified this recipient.'),
                onChanged: saving ? null : (value) => update(() {verified = value == true;})),
              CheckboxListTile(contentPadding: EdgeInsets.zero, value: waive,
                title: const Text('Waive receive fee for this document'),
                onChanged: saving ? null : (value) => update(() {waive = value == true;})),
              if (error != null) Text(error!, style: const TextStyle(color: Colors.red)),
            ]))),
          actions: [TextButton(onPressed: saving ? null : () => Navigator.pop(dialogContext), child: const Text('Cancel')),
            FilledButton(onPressed: saving || !verified ? null : () async {
              update(() {saving = true; error = null;});
              try {
                await FaxPlatformApi.request('/admin/inbox/${fax['id']}/assign', method: 'POST', body: {
                  'receive_code': code.text.trim(), 'verified_reference': reference.text.trim(),
                  'recipient_verified': verified, 'waive_fee': waive,
                });
                if (dialogContext.mounted) Navigator.pop(dialogContext);
                await _load();
              } catch (e) {
                if (dialogContext.mounted) update(() {saving = false; error = e.toString();});
              }
            }, child: Text(saving ? 'Assigning...' : 'Assign'))],
        )));
    } finally {code.dispose(); reference.dispose();}
  }

  String _date(dynamic value) {
    final date = DateTime.tryParse(value?.toString() ?? '');
    return date == null ? '-' : DateFormat('dd MMM yyyy, hh:mm a').format(date.toLocal());
  }

  @override
  Widget build(BuildContext context) => DefaultTabController(length: 2, child: Scaffold(
    appBar: AppBar(title: const Text('Fax Management'), actions: [
      IconButton(onPressed: _load, tooltip: 'Refresh', icon: const Icon(Icons.refresh)),
    ], bottom: const TabBar(tabs: [Tab(text: 'Fax Rates'), Tab(text: 'Private Inbox')])),
    body: _loading ? const Center(child: CircularProgressIndicator()) : Column(children: [
      if (_error != null) Padding(padding: const EdgeInsets.all(12), child: Text(_error!, style: const TextStyle(color: Colors.red))),
      Expanded(child: TabBarView(children: [
        RefreshIndicator(onRefresh: _load, child: ListView(padding: const EdgeInsets.all(16), children: [
          SwitchListTile(title: const Text('Enable fax charging'), value: _charging,
            subtitle: const Text('Activate after rates and the updated app are ready.'), onChanged: _busy ? null : _toggle),
          FilledButton.icon(onPressed: _busy ? null : () => _editRate(), icon: const Icon(Icons.add), label: const Text('Add Fax Rate')),
          const SizedBox(height: 12),
          if (_rates.isEmpty) const Text('Add verified Send and Receive prices. No country costs are assumed.'),
          if (_rates.isNotEmpty) SingleChildScrollView(scrollDirection: Axis.horizontal,
            child: DataTable(columns: const [
              DataColumn(label: Text('Country / Prefix')), DataColumn(label: Text('Direction')),
              DataColumn(label: Text('Cost/page'), numeric: true), DataColumn(label: Text('Sell/page'), numeric: true),
              DataColumn(label: Text('Profit/page'), numeric: true), DataColumn(label: Text('Mode')),
              DataColumn(label: Text('Status')), DataColumn(label: Text('Edit')),
            ], rows: _rates.map((rate) => DataRow(cells: [
              DataCell(Text('${rate['country_name']}\n+${rate['phone_prefix']}')),
              DataCell(Text(rate['direction'] == 'inbound' ? 'Receive' : 'Send')),
              DataCell(Text(FaxPlatformApi.usd(rate['provider_cost_usd_per_page']))),
              DataCell(Text(FaxPlatformApi.usd(rate['sell_usd_per_page']))),
              DataCell(Text(FaxPlatformApi.usd(rate['profit_usd_per_page']))),
              DataCell(Text(rate['manual_sell_usd_per_page'] == null ? '${rate['markup_percent']}% markup' : 'Manual')),
              DataCell(Text(rate['is_active'] == true ? 'Active' : 'Inactive')),
              DataCell(IconButton(icon: const Icon(Icons.edit), onPressed: () => _editRate(rate))),
            ])).toList())),
        ])),
        RefreshIndicator(onRefresh: _load, child: ListView(padding: const EdgeInsets.all(16), children: [
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
                if (fax['user_id'] == null) FilledButton(onPressed: _busy ? null : () => _assign(fax), child: const Text('Assign Recipient')),
              ]),
            ]))),
        ])),
      ])),
    ]),
  ));
}
