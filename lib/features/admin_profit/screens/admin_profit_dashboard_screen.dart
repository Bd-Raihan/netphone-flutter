import 'package:flutter/material.dart';
import '../services/admin_profit_service.dart';
import '../services/admin_profit_pdf_service.dart';

class AdminProfitDashboardScreen extends StatefulWidget {
  const AdminProfitDashboardScreen({super.key});

  @override
  State<AdminProfitDashboardScreen> createState() =>
      _AdminProfitDashboardScreenState();
}

class _AdminProfitDashboardScreenState
    extends State<AdminProfitDashboardScreen> {
  bool isLoading = true;
  String? error;
  Map<String, dynamic>? data;

  @override
  void initState() {
    super.initState();
    loadDashboard();
  }

  Future<void> loadDashboard() async {
    try {
      setState(() {
        isLoading = true;
        error = null;
      });
      final result = await AdminProfitService.getDashboard();
      if (!mounted) return;
      setState(() {
        data = result;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        error = e.toString();
        isLoading = false;
      });
    }
  }

  double _number(dynamic value) =>
      double.tryParse(value?.toString() ?? '0') ?? 0;

  String money(dynamic value) => '\$${_number(value).toStringAsFixed(4)}';
  String rate(dynamic value) => '\$${_number(value).toStringAsFixed(5)}/min';
  String percent(dynamic value) => '${_number(value).toStringAsFixed(2)}%';

  String dateTime(dynamic value) {
    if (value == null) return '-';
    final parsed = DateTime.tryParse(value.toString());
    if (parsed == null) return value.toString();
    final local = parsed.toLocal();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${local.year}-${two(local.month)}-${two(local.day)} '
        '${two(local.hour)}:${two(local.minute)}';
  }

  @override
  Widget build(BuildContext context) {
    final summary = Map<String, dynamic>.from(data?['summary'] ?? {});
    final today = Map<String, dynamic>.from(data?['today'] ?? {});
    final callDetails = (data?['call_details'] as List?) ?? const [];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Profit Dashboard'),
        actions: [
          IconButton(onPressed: loadDashboard, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : error != null
          ? Center(child: Text(error!))
          : RefreshIndicator(
              onRefresh: loadDashboard,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _titleWithPdf(
                    'Today Call Profit',
                    () => AdminProfitPdfService.downloadProfitSummary(
                      title: 'Today Call Profit Report',
                      summary: today,
                    ),
                  ),
                  _callSummaryGrid(today),
                  const SizedBox(height: 24),
                  _titleWithPdf(
                    'Lifetime Call Profit',
                    () => AdminProfitPdfService.downloadProfitSummary(
                      title: 'Lifetime Call Profit Report',
                      summary: summary,
                    ),
                  ),
                  _callSummaryGrid(summary),
                  const SizedBox(height: 24),
                  _titleWithPdf(
                    'Call Wise Profit Details',
                    () => AdminProfitPdfService.downloadCallWiseProfitDetails(
                      rows: callDetails,
                      summary: summary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _callDetailsTable(callDetails),
                ],
              ),
            ),
    );
  }

  Widget _sectionTitle(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Text(
      text,
      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
    ),
  );

  Widget _titleWithPdf(String title, Future<void> Function() onPdf) => Row(
    children: [
      Expanded(child: _sectionTitle(title)),
      ElevatedButton.icon(
        onPressed: onPdf,
        icon: const Icon(Icons.picture_as_pdf),
        label: const Text('Download PDF'),
      ),
    ],
  );

  Widget _callSummaryGrid(Map<String, dynamic> item) => GridView.count(
    crossAxisCount: 2,
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    childAspectRatio: 1.65,
    crossAxisSpacing: 12,
    mainAxisSpacing: 12,
    children: [
      _card('Total Calls', '${item['total_calls'] ?? 0}'),
      _card('Total Minutes', '${item['total_minutes'] ?? 0} Min'),
      _card('Average PM Rate', rate(item['avg_sell_rate_usd_per_min'])),
      _card('Total Charge', money(item['total_charge'])),
      _card('Provider Cost', money(item['total_provider_cost'])),
      _card('Net Profit', money(item['total_net_profit'])),
      _card('Profit %', percent(item['profit_percent'])),
      _card('Destination Groups', '${item['destination_groups'] ?? 0}'),
    ],
  );

  Widget _card(String title, String value) => Container(
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

  Widget _callDetailsTable(List rows) => SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    child: DataTable(
      columns: const [
        DataColumn(label: Text('No')),
        DataColumn(label: Text('Country')),
        DataColumn(label: Text('Mobile Number')),
        DataColumn(label: Text('Date & Time')),
        DataColumn(label: Text('Min')),
        DataColumn(label: Text('PM Rate')),
        DataColumn(label: Text('Total Charge')),
        DataColumn(label: Text('Provider Cost')),
        DataColumn(label: Text('Net Profit')),
        DataColumn(label: Text('Profit %')),
      ],
      rows: List.generate(rows.length, (index) {
        final row = Map<String, dynamic>.from(rows[index] as Map);
        return DataRow(
          cells: [
            DataCell(Text('${index + 1}')),
            DataCell(Text('${row['country_name'] ?? 'Unknown'}')),
            DataCell(Text('${row['mobile_number'] ?? ''}')),
            DataCell(Text(dateTime(row['called_at']))),
            DataCell(Text('${row['minutes'] ?? 0} Min')),
            DataCell(Text(rate(row['pm_rate']))),
            DataCell(Text(money(row['total_charge']))),
            DataCell(Text(money(row['provider_cost']))),
            DataCell(Text(money(row['net_profit']))),
            DataCell(Text(percent(row['profit_percent']))),
          ],
        );
      }),
    ),
  );
}
