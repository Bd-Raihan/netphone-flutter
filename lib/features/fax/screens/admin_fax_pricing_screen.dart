import 'package:flutter/material.dart';
import '../services/fax_platform_api.dart';
import '../widgets/fax_blue_theme.dart';

class AdminFaxPricingScreen extends StatefulWidget {
  const AdminFaxPricingScreen({super.key});
  @override
  State<AdminFaxPricingScreen> createState() => _AdminFaxPricingScreenState();
}
class _AdminFaxPricingScreenState extends State<AdminFaxPricingScreen> {
  final _search = TextEditingController();
  List<Map<String, dynamic>> _rules = [], _routes = [];
  bool _busy = false, _more = false;
  int _offset = 0;
  String? _error;
  String _api = '';
  List<Map<String, dynamic>> _items(dynamic v) => v is List ? v.whereType<Map>().map((x) => Map<String, dynamic>.from(x)).toList() : [];
  @override
  void initState() { super.initState(); _load(); }
  @override
  void dispose() { _search.dispose(); super.dispose(); }
  Future<void> _load({bool next = false}) async {
    if (_busy) return;
    setState(() { _busy = true; _error = null; });
    final offset = next ? _offset + 50 : 0;
    try {
      final result = await Future.wait([
        FaxPlatformApi.request('/admin/price-controls'),
        FaxPlatformApi.request('/admin/rate-browser?search=${Uri.encodeQueryComponent(_search.text.trim())}&offset=$offset'),
      ]);
      if (!mounted) return;
      setState(() {
        _rules = _items(result[0]['rules']);
        final rows = _items(result[1]['routes']);
        _routes = next ? [..._routes, ...rows] : rows;
        _offset = offset; _more = result[1]['more'] == true;
        _api = FaxPlatformApi.usd(result[1]['api_page_usd']);
      });
    } catch (e) { if (mounted) setState(() { _error = e.toString(); }); }
    finally { if (mounted) setState(() { _busy = false; }); }
  }
  Future<void> _edit([Map<String, dynamic>? rule]) async {
    var iso = rule?['country_code']?.toString() ?? 'US';
    var name = rule?['country_name']?.toString() ?? 'United States';
    var prefix = rule?['phone_prefix']?.toString() ?? '1';
    var price = rule?['minimum_page_usd']?.toString() ?? '0';
    var direction = rule?['direction']?.toString() ?? 'outbound';
    var active = rule?['active'] == true || rule == null;
    final form = GlobalKey<FormState>();
    bool saving = false, saved = false;
    String? error;
    await showDialog<void>(context: context, barrierDismissible: false, builder: (dialog) => StatefulBuilder(builder: (context, update) => AlertDialog(
      title: Text(rule == null ? 'Add manual page minimum' : 'Edit manual page minimum'),
      content: SizedBox(width: 440, child: SingleChildScrollView(child: Form(key: form, child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Text('Final price uses the higher of your page minimum and actual provider cost + 55%. Turning this rule off restores automatic pricing. Send approval limits still apply.'),
        TextFormField(initialValue: name, enabled: !saving, decoration: const InputDecoration(labelText: 'Country / region'), onChanged: (v) => name = v,
          validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null),
        TextFormField(initialValue: iso, enabled: !saving, decoration: const InputDecoration(labelText: 'Country ISO (US, BD, KW)'), onChanged: (v) => iso = v.toUpperCase().trim(),
          validator: (v) => RegExp(r'^[A-Za-z]{2}$').hasMatch(v?.trim() ?? '') ? null : 'Two letters required'),
        TextFormField(initialValue: prefix, enabled: !saving && rule == null, decoration: const InputDecoration(labelText: 'Number prefix (1, 880, 965)', helperText: 'Send: destination prefix. Receive: your shared fax number prefix.'), keyboardType: TextInputType.phone, onChanged: (v) => prefix = v.trim().replaceFirst('+', ''),
          validator: (v) => RegExp(r'^\+?[1-9]\d{0,14}$').hasMatch(v?.trim() ?? '') ? null : 'Digits required'),
        DropdownButtonFormField<String>(value: direction, decoration: const InputDecoration(labelText: 'Direction'), items: const [DropdownMenuItem(value: 'outbound', child: Text('Send')), DropdownMenuItem(value: 'inbound', child: Text('Receive'))], onChanged: saving || rule != null ? null : (v) => direction = v!),
        TextFormField(initialValue: price, enabled: !saving, decoration: const InputDecoration(labelText: 'Minimum USD per delivered page', helperText: '0 = automatic price; up to 6 decimals'), keyboardType: const TextInputType.numberWithOptions(decimal: true), onChanged: (v) => price = v.trim(),
          validator: (v) => RegExp(r'^\d{1,3}(\.\d{1,6})?$').hasMatch(v?.trim() ?? '') && (double.tryParse(v!.trim()) ?? 101) <= 100 ? null : 'Enter \$0–\$100'),
        SwitchListTile(contentPadding: EdgeInsets.zero, title: const Text('Use this manual minimum'), value: active, onChanged: saving ? null : (v) => update(() { active = v; })),
        if (error != null) Text(error!, style: const TextStyle(color: Colors.red)),
      ])))),
      actions: [TextButton(onPressed: saving ? null : () => Navigator.pop(dialog), child: const Text('Cancel')),
        FilledButton(onPressed: saving ? null : () async {
          if (form.currentState?.validate() != true) return;
          update(() { saving = true; error = null; });
          try {
            await FaxPlatformApi.request('/admin/price-controls', method: 'POST', body: {'country_code': iso, 'country_name': name.trim(), 'phone_prefix': prefix, 'direction': direction, 'minimum_page_usd': price, 'active': active});
            saved = true; if (dialog.mounted) Navigator.pop(dialog);
          } catch (e) { if (dialog.mounted) update(() { saving = false; error = e.toString(); }); }
        }, child: Text(saving ? 'Saving...' : 'Save'))],
    )));
    if (saved && mounted) await _load();
  }
  @override
  Widget build(BuildContext context) => FaxBlueTheme(builder: (context) => Scaffold(
    appBar: AppBar(title: const Text('Fax Country Rates')),
    body: RefreshIndicator(onRefresh: _load, child: ListView(padding: const EdgeInsets.all(16), children: [
      const Text('Automatic: (actual Fax API + SIP cost) × 1.55. SIP is billed by time; final price per page varies with duration. Manual settings apply to new faxes only.'),
      const SizedBox(height: 12),
      FilledButton.icon(onPressed: _busy ? null : () => _edit(), icon: const Icon(Icons.add), label: const Text('Add manual page minimum')),
      for (final r in _rules) Card(child: ListTile(
        title: Text("${r['country_name']} (${r['country_code']}) · ${r['direction'] == 'inbound' ? 'Receive' : 'Send'}"),
        subtitle: Text("+${r['phone_prefix']} · ${FaxPlatformApi.usd(r['minimum_page_usd'])}/page · ${r['active'] == true ? 'Manual minimum active' : 'Automatic'}"),
        trailing: IconButton(onPressed: _busy ? null : () => _edit(r), icon: const Icon(Icons.edit)),
      )),
      const Divider(height: 28),
      TextField(controller: _search, decoration: const InputDecoration(labelText: 'Search provider country / ISO / prefix', hintText: 'United States, US, 880', prefixIcon: Icon(Icons.search)), onSubmitted: (_) => _load()),
      const SizedBox(height: 8),
      OutlinedButton(onPressed: _busy ? null : () => _load(), child: const Text('Search rates')),
      Text('Provider Fax API: $_api/page. SIP charges below are additional provider costs (before 55%). Origin restrictions and billing intervals affect the selected route.'),
      if (_busy) const LinearProgressIndicator(),
      if (_error != null) Text(_error!, style: const TextStyle(color: Colors.red)),
      for (final r in _routes) Card(child: ListTile(
        title: Text("${r['country']} (${r['iso']}) · +${r['prefix']}"),
        subtitle: Text("SIP: ${FaxPlatformApi.usd(r['sip_minute_usd'])}/minute · with 55%: ${FaxPlatformApi.usd(r['sell_sip_minute_usd'])}/minute\n${FaxPlatformApi.usd(r['per_call_usd'])}/attempt\nFirst ${r['first']}s / next ${r['next']}s · Origin: ${r['origin'] == '' ? 'Any' : r['origin']} · ${r['exact'] == true ? 'Exact destination' : 'Prefix route'}"),
      )),
      if (_more) OutlinedButton(onPressed: _busy ? null : () => _load(next: true), child: const Text('Load next 50')),
    ])),
  ));
}
