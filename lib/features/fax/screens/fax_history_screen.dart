import 'dart:async';

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

class _FaxHistoryScreenState extends State<FaxHistoryScreen>
    with WidgetsBindingObserver {
  bool _loading = true;
  String? _error;
  List<FaxModel> _faxes = [];
  Timer? _refreshTimer;
  bool _requestInProgress = false;
  bool _appResumed = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _appResumed =
        WidgetsBinding.instance.lifecycleState == null ||
        WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed;
    _loadHistory();
    _refreshTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      if (mounted && _appResumed && ModalRoute.of(context)?.isCurrent == true) {
        _loadHistory(background: true);
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _appResumed = state == AppLifecycleState.resumed;
    if (_appResumed && mounted && ModalRoute.of(context)?.isCurrent == true) {
      _loadHistory(background: true);
    }
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _loadHistory({bool background = false}) async {
    if (!mounted || _requestInProgress) return;
    _requestInProgress = true;
    if (!background) {
      setState(() {
        _loading = _faxes.isEmpty;
        _error = null;
      });
    }

    try {
      final result = await FaxApiService.getHistory().timeout(
        const Duration(seconds: 20),
      );

      if (!mounted) return;

      setState(() {
        _faxes = result;
        _error = null;
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
      _requestInProgress = false;
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
      body: Column(
        children: [
          if (_error != null && _faxes.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              color: Colors.orange.withValues(alpha: 0.12),
              child: const Text(
                'Unable to refresh. Showing the last known fax status. '
                'Pull down to try again.',
              ),
            ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => _loadHistory(),
              child: _buildBody(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null && _faxes.isEmpty) {
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
                                  : 'Outgoing Fax',
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
                  if (FaxStatusChip.normalize(fax.status) == 'failed') ...[
                    const SizedBox(height: 10),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        FaxStatusChip.failureMessage(fax.failureReason),
                        style: TextStyle(color: Colors.red.shade700),
                      ),
                    ),
                  ],
                  if (fax.failureReason == 'submission_unconfirmed' &&
                      FaxStatusChip.isPending(fax.status)) ...[
                    const SizedBox(height: 10),
                    const Text(
                      'Submission is not confirmed yet. '
                      'Check the result before sending again.',
                    ),
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
