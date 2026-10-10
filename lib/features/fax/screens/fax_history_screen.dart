import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/fax_model.dart';
import '../services/fax_api_service.dart';
import '../widgets/fax_status_chip.dart';
import 'fax_document_view_screen.dart';

class FaxHistoryScreen extends StatefulWidget {
  const FaxHistoryScreen({super.key});

  @override
  State<FaxHistoryScreen> createState() => _FaxHistoryScreenState();
}

class _FaxHistoryScreenState extends State<FaxHistoryScreen> {
  bool _loading = true;
  String? _error;
  List<FaxModel> _faxes = [];

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final result = await FaxApiService.getHistory();

      if (!mounted) return;

      setState(() {
        _faxes = result;
      });
    } on FaxApiException catch (e) {
      if (!mounted) return;

      setState(() {
        _error = e.message;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _error = 'Unable to load fax history.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '-';

    return DateFormat('dd MMM yyyy, hh:mm a').format(date.toLocal());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Fax History')),
      body: RefreshIndicator(onRefresh: _loadHistory, child: _buildBody()),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          const SizedBox(height: 140),
          const Icon(Icons.error_outline, size: 50),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(_error!, textAlign: TextAlign.center),
          ),
        ],
      );
    }

    if (_faxes.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [
          SizedBox(height: 140),
          Icon(Icons.history, size: 55, color: Colors.grey),
          SizedBox(height: 12),
          Center(child: Text('No fax history yet.')),
        ],
      );
    }

    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      itemCount: _faxes.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final fax = _faxes[index];

        final number = fax.direction.toLowerCase() == 'inbound'
            ? fax.fromNumber
            : fax.toNumber;

        return Card(
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => FaxDocumentViewScreen(fax: fax),
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        child: Icon(
                          fax.direction.toLowerCase() == 'inbound'
                              ? Icons.call_received
                              : Icons.call_made,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              number ?? 'Unknown number',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              fax.direction.toLowerCase() == 'inbound'
                                  ? 'Received Fax'
                                  : 'Sent Fax',
                              style: const TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                      FaxStatusChip(status: fax.status),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _formatDate(fax.createdAt),
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  if (fax.pages != null) ...[
                    const SizedBox(height: 5),
                    Text('${fax.pages} page${fax.pages == 1 ? '' : 's'}'),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
