import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class AdminProfitPdfService {
  static double _n(dynamic value) =>
      double.tryParse(value?.toString() ?? '0') ?? 0;
  static String _money(dynamic value) => '\$${_n(value).toStringAsFixed(4)}';
  static String _rate(dynamic value) => '\$${_n(value).toStringAsFixed(5)}/min';
  static String _percent(dynamic value) => '${_n(value).toStringAsFixed(2)}%';

  static String _dateTime(dynamic value) {
    if (value == null) return '-';
    final parsed = DateTime.tryParse(value.toString());
    if (parsed == null) return value.toString();
    final local = parsed.toLocal();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${local.year}-${two(local.month)}-${two(local.day)} '
        '${two(local.hour)}:${two(local.minute)}';
  }

  static Future<void> downloadProfitSummary({
    required String title,
    required Map summary,
  }) async {
    await _buildPdf(
      title: title,
      headers: const ['Item', 'Value'],
      rows: [
        ['Total Calls', '${summary['total_calls'] ?? 0}'],
        ['Total Minutes', '${summary['total_minutes'] ?? 0} Min'],
        ['Average PM Rate', _rate(summary['avg_sell_rate_usd_per_min'])],
        ['Total Charge', _money(summary['total_charge'])],
        ['Provider Cost', _money(summary['total_provider_cost'])],
        ['Net Profit', _money(summary['total_net_profit'])],
        ['Profit %', _percent(summary['profit_percent'])],
        ['Destination Countries', '${summary['destination_groups'] ?? 0}'],
      ],
      landscape: false,
    );
  }

  static Future<void> downloadCallWiseProfitDetails({
    required List rows,
    required Map summary,
  }) async {
    final tableRows = List.generate(rows.length, (index) {
      final row = Map<String, dynamic>.from(rows[index] as Map);
      return <String>[
        '${index + 1}',
        '${row['country_name'] ?? 'Unknown'}',
        '${row['mobile_number'] ?? ''}',
        _dateTime(row['called_at']),
        '${row['minutes'] ?? 0} Min',
        _rate(row['pm_rate']),
        _money(row['total_charge']),
        _money(row['provider_cost']),
        _money(row['net_profit']),
        _percent(row['profit_percent']),
      ];
    });

    tableRows.add([
      '',
      'TOTAL',
      '',
      '',
      '${summary['total_minutes'] ?? 0} Min',
      _rate(summary['avg_sell_rate_usd_per_min']),
      _money(summary['total_charge']),
      _money(summary['total_provider_cost']),
      _money(summary['total_net_profit']),
      _percent(summary['profit_percent']),
    ]);

    await _buildPdf(
      title: 'Call Wise Profit Details',
      headers: const [
        'No',
        'Country',
        'Mobile Number',
        'Date & Time',
        'Min',
        'PM Rate',
        'Total Charge',
        'Provider Cost',
        'Net Profit',
        'Profit %',
      ],
      rows: tableRows,
      landscape: true,
    );
  }

  static Future<void> downloadRegisteredUsersDetails({
    required List rows,
    required Map summary,
  }) async {
    final tableRows = List.generate(rows.length, (index) {
      final row = Map<String, dynamic>.from(rows[index] as Map);
      return <String>[
        '${index + 1}',
        '${row['registered_number'] ?? ''}',
        '${row['country_name'] ?? 'Unknown'}',
        _dateTime(row['registered_at']),
        _dateTime(row['last_login_at']),
        '${row['activity_status'] ?? 'Inactive'}',
      ];
    });

    await _buildPdf(
      title: 'Registered Users Details',
      summaryLines: [
        'Registered Numbers: ${summary['total_registered_numbers'] ?? 0}',
        'Countries: ${summary['unique_registration_countries'] ?? 0}',
        'Active: ${summary['active_users'] ?? 0}',
        'Inactive: ${summary['inactive_users'] ?? 0}',
        'Blocked: ${summary['blocked_users'] ?? 0}',
      ],
      headers: const [
        'No',
        'Registered Number',
        'Country',
        'Registered Date & Time',
        'Last Login',
        'Status',
      ],
      rows: tableRows,
      landscape: true,
    );
  }

  static Future<void> _buildPdf({
    required String title,
    required List<String> headers,
    required List<List<String>> rows,
    List<String> summaryLines = const [],
    bool landscape = false,
  }) async {
    final pdf = pw.Document();
    final pageFormat = landscape
        ? PdfPageFormat.a4.landscape
        : PdfPageFormat.a4;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: pageFormat,
        margin: const pw.EdgeInsets.fromLTRB(12, 12, 12, 16),
        footer: (context) => pw.Align(
          alignment: pw.Alignment.centerRight,
          child: pw.Text(
            'NetPhone Confidential Report - Page ${context.pageNumber}',
            style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey),
          ),
        ),
        build: (context) => [
          pw.Text(
            'NetPhone',
            style: pw.TextStyle(fontSize: 25, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            title,
            style: pw.TextStyle(fontSize: 17, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            'Generated: ${DateTime.now()}',
            style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
          ),
          if (summaryLines.isNotEmpty) ...[
            pw.SizedBox(height: 8),
            pw.Wrap(
              spacing: 12,
              runSpacing: 4,
              children: summaryLines
                  .map(
                    (line) => pw.Text(
                      line,
                      style: pw.TextStyle(
                        fontSize: 9,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
          pw.Divider(),
          pw.SizedBox(height: 8),
          pw.TableHelper.fromTextArray(
            headers: headers,
            data: rows,
            headerHeight: 22,
            cellPadding: const pw.EdgeInsets.symmetric(
              horizontal: 3,
              vertical: 2.5,
            ),
            headerDecoration: const pw.BoxDecoration(
              color: PdfColors.blueGrey800,
            ),
            cellStyle: pw.TextStyle(fontSize: headers.length > 8 ? 6.5 : 8),
            cellAlignment: pw.Alignment.centerLeft,
            border: pw.TableBorder.all(color: PdfColors.grey300),
          ),
        ],
      ),
    );

    await Printing.layoutPdf(onLayout: (_) async => pdf.save());
  }
}
