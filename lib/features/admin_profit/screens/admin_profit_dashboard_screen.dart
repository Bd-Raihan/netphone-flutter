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

      setState(() {
        data = result;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        error = e.toString();
        isLoading = false;
      });
    }
  }

  String money(dynamic value) {
    final n = double.tryParse(value.toString()) ?? 0;
    return '\$${n.toStringAsFixed(2)}';
  }

  String percent(dynamic value) {
    final n = double.tryParse(value.toString()) ?? 0;
    return '${n.toStringAsFixed(2)}%';
  }

  @override
  Widget build(BuildContext context) {
    final summary = data?['summary'] ?? {};
    final today = data?['today'] ?? {};
    final countryWise = (data?['country_wise'] as List?) ?? [];
    final userCountryWise = (data?['user_country_wise'] as List?) ?? [];

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
                  const Text(
                    'Today Profit',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.picture_as_pdf),
                      label: const Text('Download PDF'),
                      onPressed: () async {
                        await AdminProfitPdfService.downloadTodayProfit(today);
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                  _summaryGrid(today),

                  const SizedBox(height: 24),
                  const Text(
                    'Lifetime Profit',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.picture_as_pdf),
                      label: const Text('Download PDF'),
                      onPressed: () async {
                        await AdminProfitPdfService.downloadLifetimeProfit(
                          summary,
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                  _summaryGrid(summary),

                  const SizedBox(height: 24),
                  const Text(
                    'Country Wise Profit Details Summary',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.picture_as_pdf),
                      label: const Text('Download PDF'),
                      onPressed: () async {
                        await AdminProfitPdfService.downloadCountryWiseDetails(
                          rows: userCountryWise,
                          countrySummaryRows: countryWise,
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                  _countryDetailsTable(userCountryWise),
                ],
              ),
            ),
    );
  }

  Widget _summaryGrid(Map item) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.65,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      children: [
        _card('Total Calls', '${item['total_calls'] ?? 0}'),
        _card('Total Minutes', '${item['total_minutes'] ?? 0}'),
        _card('Revenue', money(item['total_revenue'])),
        _card('Provider Cost', money(item['total_provider_cost'])),
        _card('Net Profit', money(item['total_profit'])),
        _card('Profit %', percent(item['profit_percent'])),
      ],
    );
  }

  Widget _card(String title, String value) {
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
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _countryDetailsTable(List rows) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: const [
          DataColumn(label: Text('No')),
          DataColumn(label: Text('Country')),
          DataColumn(label: Text('Registered Number')),
          DataColumn(label: Text('Calls')),
          DataColumn(label: Text('Min')),
          DataColumn(label: Text('Revenue')),
          DataColumn(label: Text('Provider Cost')),
          DataColumn(label: Text('Net Profit')),
          DataColumn(label: Text('%')),
        ],
        rows: rows.map<DataRow>((r) {
          return DataRow(
            cells: [
              DataCell(Text('${r['serial_no'] ?? ''}')),
              DataCell(Text('${r['country_name'] ?? 'Unknown'}')),
              DataCell(Text('${r['registered_number'] ?? ''}')),
              DataCell(Text('${r['total_calls'] ?? 0}')),
              DataCell(Text('${r['total_minutes'] ?? 0}')),
              DataCell(Text(money(r['total_user_paid']))),
              DataCell(Text(money(r['total_twilio_cost']))),
              DataCell(Text(money(r['total_profit']))),
              DataCell(Text(percent(r['profit_percent']))),
            ],
          );
        }).toList(),
      ),
    );
  }
}
