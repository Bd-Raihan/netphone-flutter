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
  @override
  void initState() {super.initState(); _load();}

  Future<void> _load() async {
    try {
      final data = await FaxPlatformApi.request('/receive-profile');
      if (mounted) setState(() {_profile = data; _error = null;});
    } catch (error) {
      if (mounted) setState(() {_error = error.toString();});
    }
  }

  Future<void> _copy(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Copied.')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Receive Fax')),
      body: _profile == null
        ? Center(child: _error == null ? const CircularProgressIndicator() :
            Padding(padding: const EdgeInsets.all(24), child: Column(
              mainAxisSize: MainAxisSize.min, children: [Text(_error!),
                TextButton(onPressed: _load, child: const Text('Try again'))])))
        : ListView(padding: const EdgeInsets.all(20), children: [
            const Text('Give the sender both your fax number and Receive ID.',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            ListTile(title: const Text('Fax number'),
              subtitle: SelectableText(_profile!['fax_number'].toString()),
              trailing: IconButton(icon: const Icon(Icons.copy), onPressed: () =>
                _copy(_profile!['fax_number'].toString()))),
            ListTile(title: const Text('Your Receive ID'),
              subtitle: SelectableText(_profile!['receive_code'].toString()),
              trailing: IconButton(icon: const Icon(Icons.copy), onPressed: () =>
                _copy(_profile!['receive_code'].toString()))),
            const SizedBox(height: 18),
            const Text('Ask the sender to write your Receive ID on the first page or cover sheet. '
              'The fax number is shared. NetPhone verifies the intended recipient before adding '
              'the document to your private Fax History.'),
            const SizedBox(height: 16),
            const Text('Any receive fee is shown before you pay and open/download the document.'),
          ]),
    );
  }
}
