import 'package:flutter/material.dart';

import '../models/admin_call_activity_model.dart';
import '../services/admin_call_activity_service.dart';
import '../services/admin_call_activity_pdf_service.dart';
import '../../admin_profit/services/admin_profit_service.dart';
import '../../admin_profit/services/admin_profit_pdf_service.dart';

// ============================================================
// 🇧🇩 ADMIN CALL ACTIVITY / CDR SUMMARY SCREEN
//
// কাজ:
// - Admin user-এর জন্য Call Detail Record দেখানো
// - Registered/App number
// - Origin/Destination country
// - Destination number
// - Date & Time
// - Duration
// - Call Status
//
// এটি শুধুমাত্র read-only report.
// Calling Engine / Billing / Wallet modify করে না.
// ============================================================

class AdminCallActivityScreen extends StatefulWidget {
  const AdminCallActivityScreen({super.key});

  @override
  State<AdminCallActivityScreen> createState() =>
      _AdminCallActivityScreenState();
}

class _AdminCallActivityScreenState extends State<AdminCallActivityScreen> {
  final TextEditingController _searchController = TextEditingController();

  DateTime? _fromDate;
  DateTime? _toDate;
  bool _isLoading = true;
  bool _isDownloadingPdf = false;

  String? _error;

  AdminCallActivityResponse? _data;

  // Registered Users Summary is displayed here, but its existing
  // backend/PDF logic is reused unchanged from Admin Profit.
  Map<String, dynamic> _registeredUserSummary = {};
  List<dynamic> _registeredUsers = const [];

  @override
  void initState() {
    super.initState();

    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();

    super.dispose();
  }

  Future<void> _load() async {
    if (!mounted) {
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final results = await Future.wait<dynamic>([
        AdminCallActivityService.getCallActivity(
          search: _searchController.text,
          fromDate: _fromDate,
          toDate: _toDate,
        ),
        AdminProfitService.getDashboard(),
      ]);

      if (!mounted) {
        return;
      }

      final callActivity = results[0] as AdminCallActivityResponse;
      final profitData = Map<String, dynamic>.from(results[1] as Map);

      setState(() {
        _data = callActivity;
        _registeredUserSummary = Map<String, dynamic>.from(
          profitData['registered_user_summary'] ?? {},
        );
        _registeredUsers =
            (profitData['registered_users'] as List?) ?? const [];
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');

        _isLoading = false;
      });
    }
  }

  Future<void> _clearSearch() async {
    _searchController.clear();

    await _load();
  }

  String _formatDateOnly(DateTime? value) {
    if (value == null) {
      return 'Select date';
    }

    String two(int n) => n.toString().padLeft(2, '0');

    return '${two(value.day)}/${two(value.month)}/${value.year}';
  }

  Future<void> _pickFromDate() async {
    final now = DateTime.now();

    final selected = await showDatePicker(
      context: context,
      initialDate: _fromDate ?? now,
      firstDate: DateTime(2020),
      lastDate: DateTime(now.year + 5),
    );

    if (selected == null || !mounted) {
      return;
    }

    setState(() {
      _fromDate = DateTime(
        selected.year,
        selected.month,
        selected.day,
        0,
        0,
        0,
      );

      if (_toDate != null && _toDate!.isBefore(_fromDate!)) {
        _toDate = null;
      }
    });
  }

  Future<void> _pickToDate() async {
    final now = DateTime.now();

    final selected = await showDatePicker(
      context: context,
      initialDate: _toDate ?? _fromDate ?? now,
      firstDate: _fromDate ?? DateTime(2020),
      lastDate: DateTime(now.year + 5),
    );

    if (selected == null || !mounted) {
      return;
    }

    setState(() {
      _toDate = DateTime(
        selected.year,
        selected.month,
        selected.day,
        23,
        59,
        59,
        999,
      );
    });
  }

  Future<void> _clearDateFilter() async {
    setState(() {
      _fromDate = null;
      _toDate = null;
    });

    await _load();
  }

  Future<void> _downloadPdf() async {
    if (_isDownloadingPdf) {
      return;
    }

    setState(() {
      _isDownloadingPdf = true;
    });

    try {
      await AdminCallActivityPdfService.previewPdf(
        search: _searchController.text,
        fromDate: _fromDate,
        toDate: _toDate,
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isDownloadingPdf = false;
        });
      }
    }
  }

  String _formatDateTime(DateTime? value) {
    if (value == null) {
      return '-';
    }

    final local = value.toLocal();

    String two(int n) => n.toString().padLeft(2, '0');

    return '${two(local.day)}/'
        '${two(local.month)}/'
        '${local.year} '
        '${two(local.hour)}:'
        '${two(local.minute)}';
  }

  String _formatDuration(int seconds) {
    if (seconds <= 0) {
      return '00:00';
    }

    final hours = seconds ~/ 3600;

    final minutes = (seconds % 3600) ~/ 60;

    final secs = seconds % 60;

    String two(int n) => n.toString().padLeft(2, '0');

    if (hours > 0) {
      return '${two(hours)}:'
          '${two(minutes)}:'
          '${two(secs)}';
    }

    return '${two(minutes)}:'
        '${two(secs)}';
  }

  String _formatProviderName(String provider) {
    switch (provider.toLowerCase().trim()) {
      case 'telnyx':
        return 'Telnyx';

      case 'twilio':
        return 'Twilio';

      default:
        if (provider.trim().isEmpty) {
          return 'Unknown';
        }

        final value = provider.trim();

        return value[0].toUpperCase() + value.substring(1);
    }
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase().trim()) {
      case 'charged':
        return Colors.green;

      case 'completed':
        return Colors.teal;

      case 'started':
        return Colors.blue;

      case 'answered':
        return Colors.indigo;

      case 'ended':
        return Colors.deepPurple;

      case 'failed':
        return Colors.red;

      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Call Activity / CDR'),
        actions: [
          IconButton(
            tooltip: 'Download PDF',
            onPressed: _isLoading || _isDownloadingPdf ? null : _downloadPdf,
            icon: _isDownloadingPdf
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.picture_as_pdf_outlined),
          ),
          IconButton(
            tooltip: 'Refresh',
            onPressed: _isLoading ? null : _load,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline,
                size: 48,
                color: Colors.redAccent,
              ),
              const SizedBox(height: 12),
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _load,
                icon: const Icon(Icons.refresh),
                label: const Text('Try Again'),
              ),
            ],
          ),
        ),
      );
    }

    final data = _data;

    if (data == null) {
      return const Center(child: Text('No report data available'));
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildRegisteredUsersSection(),

          const SizedBox(height: 28),

          _buildSearchBox(),

          const SizedBox(height: 22),

          Row(
            children: [
              const Expanded(
                child: Text(
                  'Call Detail Records',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
              Text(
                '${data.total} Records',
                style: const TextStyle(
                  color: Colors.grey,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          if (data.calls.isEmpty)
            _buildEmptyState()
          else
            _buildTable(data.calls),
        ],
      ),
    );
  }

  String _registeredUserDateTime(dynamic value) {
    if (value == null) return '-';

    final parsed = DateTime.tryParse(value.toString());
    if (parsed == null) return value.toString();

    final local = parsed.toLocal();
    String two(int n) => n.toString().padLeft(2, '0');

    return '${local.year}-${two(local.month)}-${two(local.day)} '
        '${two(local.hour)}:${two(local.minute)}';
  }

  Widget _buildRegisteredUsersSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Registered Users Summary',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
            ),
            ElevatedButton.icon(
              onPressed: () =>
                  AdminProfitPdfService.downloadRegisteredUsersDetails(
                    rows: _registeredUsers,
                    summary: _registeredUserSummary,
                  ),
              icon: const Icon(Icons.picture_as_pdf),
              label: const Text('Download PDF'),
            ),
          ],
        ),
        const SizedBox(height: 10),
        _buildRegisteredUserSummaryGrid(),
        const SizedBox(height: 12),
        _buildRegisteredUsersTable(),
      ],
    );
  }

  Widget _buildRegisteredUserSummaryGrid() {
    final item = _registeredUserSummary;

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.65,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      children: [
        _registeredUserCard(
          'Registered Numbers',
          '${item['total_registered_numbers'] ?? 0}',
        ),
        _registeredUserCard(
          'Countries',
          '${item['unique_registration_countries'] ?? 0}',
        ),
        _registeredUserCard('Active', '${item['active_users'] ?? 0}'),
        _registeredUserCard('Inactive', '${item['inactive_users'] ?? 0}'),
        _registeredUserCard('Blocked', '${item['blocked_users'] ?? 0}'),
      ],
    );
  }

  Widget _registeredUserCard(String title, String value) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 0, 57, 95),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(title, style: const TextStyle(color: Colors.white70)),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 19,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRegisteredUsersTable() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: const [
          DataColumn(label: Text('No')),
          DataColumn(label: Text('Registered Number')),
          DataColumn(label: Text('Country')),
          DataColumn(label: Text('Registered Date & Time')),
          DataColumn(label: Text('Last Login')),
          DataColumn(label: Text('Status')),
        ],
        rows: List.generate(_registeredUsers.length, (index) {
          final row = Map<String, dynamic>.from(_registeredUsers[index] as Map);

          return DataRow(
            cells: [
              DataCell(Text('${index + 1}')),
              DataCell(Text('${row['registered_number'] ?? ''}')),
              DataCell(Text('${row['country_name'] ?? 'Unknown'}')),
              DataCell(Text(_registeredUserDateTime(row['registered_at']))),
              DataCell(Text(_registeredUserDateTime(row['last_login_at']))),
              DataCell(Text('${row['activity_status'] ?? 'Inactive'}')),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildSearchBox() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Search',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),

            const SizedBox(height: 10),

            TextField(
              controller: _searchController,
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => _load(),
              decoration: InputDecoration(
                hintText: 'App number, destination number or Call ID',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        onPressed: _clearSearch,
                        icon: const Icon(Icons.clear),
                      )
                    : null,
                border: const OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 10),

            const SizedBox(height: 14),

            const Text(
              'Date Range',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),

            const SizedBox(height: 8),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickFromDate,
                    icon: const Icon(Icons.calendar_today_outlined, size: 18),
                    label: Text(
                      _fromDate == null
                          ? 'From Date'
                          : _formatDateOnly(_fromDate),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickToDate,
                    icon: const Icon(Icons.event_outlined, size: 18),
                    label: Text(
                      _toDate == null ? 'To Date' : _formatDateOnly(_toDate),
                    ),
                  ),
                ),
              ],
            ),

            if (_fromDate != null || _toDate != null) ...[
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: _clearDateFilter,
                  icon: const Icon(Icons.clear, size: 18),
                  label: const Text('Clear Date Filter'),
                ),
              ),
            ],

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _load,
                icon: const Icon(Icons.manage_search),
                label: const Text('Search Records'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Card(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 48, horizontal: 20),
        child: Column(
          children: [
            Icon(Icons.phone_disabled_outlined, size: 48, color: Colors.grey),
            SizedBox(height: 12),
            Text(
              'No call records found',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTable(List<AdminCallActivityItem> calls) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowHeight: 52,
          dataRowMinHeight: 56,
          dataRowMaxHeight: 68,
          columns: const [
            DataColumn(label: Text('No.')),
            DataColumn(label: Text('Origin Country')),
            DataColumn(label: Text('App Number')),
            DataColumn(label: Text('To Country')),
            DataColumn(label: Text('To Number')),
            DataColumn(label: Text('Date & Time')),
            DataColumn(label: Text('Duration')),
            DataColumn(label: Text('Call Provider')),
            DataColumn(label: Text('Provider Number')),
            DataColumn(label: Text('Status')),
          ],
          rows: List.generate(calls.length, (index) {
            final call = calls[index];

            return DataRow(
              cells: [
                DataCell(Text('${index + 1}')),

                DataCell(
                  Text(
                    call.originCountry.isEmpty ? 'Unknown' : call.originCountry,
                  ),
                ),

                DataCell(
                  SelectableText(
                    call.registeredNumber.isEmpty ? '-' : call.registeredNumber,
                  ),
                ),

                DataCell(
                  Text(
                    call.destinationCountry.isEmpty
                        ? 'Unknown'
                        : call.destinationCountry,
                  ),
                ),

                DataCell(
                  SelectableText(
                    call.destinationNumber.isEmpty
                        ? '-'
                        : call.destinationNumber,
                  ),
                ),

                DataCell(Text(_formatDateTime(call.startedAt))),

                DataCell(Text(_formatDuration(call.durationSeconds))),

                DataCell(
                  Text(
                    call.provider.isEmpty
                        ? 'Unknown'
                        : _formatProviderName(call.provider),
                  ),
                ),

                DataCell(
                  SelectableText(
                    call.providerPhoneNumber?.isNotEmpty == true
                        ? call.providerPhoneNumber!
                        : 'Not recorded',
                  ),
                ),

                DataCell(
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: _statusColor(call.status).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      call.status.isEmpty ? 'Unknown' : call.status,
                      style: TextStyle(
                        color: _statusColor(call.status),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            );
          }),
        ),
      ),
    );
  }
}
