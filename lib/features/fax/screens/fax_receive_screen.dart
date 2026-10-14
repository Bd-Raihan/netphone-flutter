import 'dart:io';
import 'package:file_picker/file_picker.dart';
import '../widgets/fax_help_panel.dart';
import '../widgets/fax_blue_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/fax_platform_api.dart';

class FaxReceiveScreen extends StatefulWidget {
  const FaxReceiveScreen({super.key});
  @override
  State<FaxReceiveScreen> createState() => _FaxReceiveScreenState();
}

class _FaxReceiveScreenState extends State<FaxReceiveScreen> {
  Map<String, dynamic>? _profile;
  String? _error;
  bool _savingCover = false;
  bool _savingAuto = false;
  Map<String, dynamic> _receiveBilling = {};
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final result = await Future.wait([FaxPlatformApi.request('/receive-profile'), FaxPlatformApi.request('/receive-billing')]);
      final data = result[0];
      _receiveBilling = result[1];
      if (mounted)
        setState(() {
          _profile = data;
          _error = null;
        });
    } catch (error) {
      if (mounted)
        setState(() {
          _error = error.toString();
        });
    }
  }

  Future<void> _automaticPayment(bool enabled) async {
    if (_savingAuto) return;
    var limit = (_receiveBilling['limit_usd'] ?? '0.50').toString();
    if (enabled) {
      final approved = await showDialog<bool>(context: context, builder: (dialog) => AlertDialog(
        title: const Text('Automatic Receive payment'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('For new received faxes, deduct the final fee automatically from my USD wallet, up to this limit per fax. If the fee exceeds my limit or balance, leave it unpaid for me to review. Past faxes are excluded.'),
          TextFormField(initialValue: limit, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Maximum USD per received fax (0.01–100)'), onChanged: (v) => limit = v.trim()),
        ]),
        actions: [TextButton(onPressed: () => Navigator.pop(dialog, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(dialog, true), child: const Text('Agree & Enable'))],
      ));
      if (approved != true || !mounted) return;
    }
    setState(() { _savingAuto = true; });
    try {
      await FaxPlatformApi.request('/receive-billing', method: 'PATCH', body: {'enabled': enabled, 'limit_usd': limit});
      await _load();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally { if (mounted) setState(() { _savingAuto = false; }); }
  }

  Future<void> _downloadCover() async {
    if (_savingCover) return;
    String enteredName = '';

    final name = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(backgroundColor: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF16232F) : Colors.white, surfaceTintColor: Colors.transparent, 
        title: const Text('Receive Cover Page'),
        content: TextField(
          maxLength: 60,
          onChanged: (value) => enteredName = value,
          decoration: const InputDecoration(
            labelText: 'Recipient name (English)',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              FocusScope.of(dialogContext).unfocus();
              Navigator.pop(dialogContext, enteredName.trim());
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );

    if (name == null || !mounted) return;
    setState(() => _savingCover = true);
    try {
      final bytes = await FaxPlatformApi.downloadCover(name);
      if (!mounted) return;
      final saved = await FilePicker.saveFile(
        dialogTitle: 'Save Receive Cover Page',
        fileName: 'NetPhone_Receive_Cover.pdf',
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        bytes: bytes,
      );
      if (saved != null && !Platform.isAndroid && !Platform.isIOS) {
        await File(saved).writeAsBytes(bytes, flush: true);
      }
      if (!mounted) return;

      if (saved != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Cover saved. Send it to the sender and ask them '
              'to use it as the FIRST page.',
            ),
          ),
        );
      }
    } catch (error) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.toString())));
    } finally {
      if (mounted) setState(() => _savingCover = false);
    }
  }

  Future<void> _revokeCovers() async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(backgroundColor: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF16232F) : Colors.white, surfaceTintColor: Colors.transparent, 
        title: const Text('Revoke unused cover pages?'),
        content: const Text(
          'Previously downloaded unused covers will stop routing automatically. Create and share a new cover afterward.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Revoke'),
          ),
        ],
      ),
    );
    if (yes != true || !mounted) return;
    try {
      await FaxPlatformApi.request('/receive-cover/revoke', method: 'POST');
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Unused covers revoked.')));
    } catch (error) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }

  Future<void> _copy(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (mounted)
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Copied.')));
  }

  @override
  Widget build(BuildContext context) => FaxBlueTheme(builder: _buildFax);

  Widget _buildFax(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Receive Fax')),
      body: _profile == null
          ? Center(
              child: _error == null
                  ? const CircularProgressIndicator()
                  : Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(_error!),
                          TextButton(
                            onPressed: _load,
                            child: const Text('Try again'),
                          ),
                        ],
                      ),
                    ),
            )
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                const FaxHelpPanel(),
                Card(child: SwitchListTile(
                  title: const Text('Automatically pay Receive fees'),
                  subtitle: Text(_receiveBilling['enabled'] == true
                    ? 'Limit: ${FaxPlatformApi.usd(_receiveBilling['limit_usd'])} per new fax. Change the limit by turning off and enabling again.'
                    : 'Off: review and pay the fee when opening the fax. Enable to allow wallet deductions within your limit.'),
                  value: _receiveBilling['enabled'] == true,
                  onChanged: _savingAuto ? null : _automaticPayment,
                )),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: _savingCover ? null : _downloadCover,
                  icon: const Icon(Icons.download),
                  label: Text(
                    _savingCover ? 'Creating...' : 'Download Cover Page',
                  ),
                ),
                TextButton(
                  onPressed: _savingCover ? null : _revokeCovers,
                  child: const Text('Revoke Unused Covers'),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Send your cover page to the sender.',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                ListTile(
                  title: const Text('Fax number'),
                  subtitle: SelectableText(_profile!['fax_number'].toString()),
                  trailing: IconButton(
                    icon: const Icon(Icons.copy),
                    onPressed: () => _copy(_profile!['fax_number'].toString()),
                  ),
                ),
                ListTile(
                  title: const Text('Your Receive ID'),
                  subtitle: SelectableText(
                    _profile!['receive_code'].toString(),
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.copy),
                    onPressed: () =>
                        _copy(_profile!['receive_code'].toString()),
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  'Ask the sender to place the downloaded cover FIRST, then the document, in one fax. '
                  'Keep your QR cover within the first 3 pages if the sender service adds its own cover. '
                  'A valid code routes the fax to your private Fax History automatically. '
                  'Missing or invalid codes wait for Admin review.',
                ),
                const SizedBox(height: 16),
                const Text(
                  'To view received faxes, return to the main Fax menu and open Fax History. '
                  'Select a Received Fax, review any fee, then View Document or Download Document.',
                ),
              ],
            ),
    );
  }
}
