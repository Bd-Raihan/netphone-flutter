import 'package:flutter/material.dart';
import '../services/admin_sms_inbox_service.dart';

class AdminSmsInboxScreen extends StatefulWidget {
  const AdminSmsInboxScreen({super.key});

  @override
  State<AdminSmsInboxScreen> createState() => _AdminSmsInboxScreenState();
}

class _AdminSmsInboxScreenState extends State<AdminSmsInboxScreen> {
  List<Map<String, dynamic>> messages = [];
  bool loading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    loadMessages();
  }

  Future<void> loadMessages() async {
    setState(() {
      loading = true;
      error = null;
    });

    try {
      final result = await AdminSmsInboxService.fetchMessages();
      if (!mounted) return;

      setState(() {
        messages = result;
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        error = e.toString();
        loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SMS Inbox'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: loading ? null : loadMessages,
          ),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : error != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text(error!, textAlign: TextAlign.center),
              ),
            )
          : RefreshIndicator(
              onRefresh: loadMessages,
              child: messages.isEmpty
                  ? ListView(
                      children: const [
                        SizedBox(height: 150),
                        Center(child: Text('No SMS received')),
                      ],
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(12),
                      itemCount: messages.length,
                      separatorBuilder: (_, _) => const Divider(height: 16),
                      itemBuilder: (context, index) {
                        final sms = messages[index];

                        return Card(
                          child: ListTile(
                            leading: const Icon(Icons.sms_outlined),
                            title: Text(
                              sms['from_number']?.toString() ?? 'Unknown',
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 6),
                                SelectableText(
                                  sms['message_body']?.toString() ?? '',
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  sms['received_at']?.toString() ?? '',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                            isThreeLine: true,
                          ),
                        );
                      },
                    ),
            ),
    );
  }
}
