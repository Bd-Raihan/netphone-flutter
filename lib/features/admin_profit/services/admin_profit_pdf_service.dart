import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class AdminProfitPdfService {
  static String _money(dynamic value) {
    final n = double.tryParse(value.toString()) ?? 0;
    return '\$${n.toStringAsFixed(2)}';
  }

  static String _ratePerMinute(dynamic value) {
    final n = double.tryParse(value?.toString() ?? '0') ?? 0;

    return '\$${n.toStringAsFixed(4)}/min';
  }

  static String _percent(dynamic value) {
    final n = double.tryParse(value.toString()) ?? 0;
    return '${n.toStringAsFixed(2)}%';
  }

  static Future<void> downloadTodayProfit(Map data) async {
    await _buildPdf(
      title: 'Today Profit Report',
      headers: ['Item', 'Value'],
      rows: _summaryRows(data),
    );
  }

  static Future<void> downloadLifetimeProfit(Map data) async {
    await _buildPdf(
      title: 'Lifetime Profit Report',
      headers: ['Item', 'Value'],
      rows: _summaryRows(data),
    );
  }

  static Future<void> downloadCountryWiseDetails({
    required List rows,
    List countrySummaryRows = const [],
  }) async {
    await _buildPdf(
      title: 'Country Wise Profit Details Summary',
      headers: [
        'No',
        'Country',
        'Registered Number',
        'Calls',
        'Min',
        'Revenue',
        'Provider Cost',
        'Net Profit',
        'Profit %',
      ],
      rows: rows.map<List<String>>((r) {
        return [
          '${r['serial_no'] ?? ''}',
          '${r['country_name'] ?? 'Unknown'}',
          '${r['registered_number'] ?? ''}',
          '${r['total_calls'] ?? 0}',
          '${r['total_minutes'] ?? 0}',
          _money(r['total_user_paid']),
          _money(r['total_twilio_cost']),
          _money(r['total_profit']),
          _percent(r['profit_percent']),
        ];
      }).toList(),
      countrySummaryRows: countrySummaryRows,
    );
  }

  // Backward compatible method. If old button code exists, it still works.
  static Future<void> downloadCountryWise(List rows) async {
    await _buildPdf(
      title: 'Country Wise Profit Summary',
      headers: [
        'No',
        'Country',
        'Registered Number',
        'Calls',
        'Min',
        'Rate / Min',
        'Revenue',
        'Provider Cost',
        'Net Profit',
        'Profit %',
      ],
      rows: rows.map<List<String>>((r) {
        return [
          '${r['serial_no'] ?? ''}',
          '${r['country_name'] ?? 'Unknown'}',
          '${r['total_calls'] ?? 0}',
          '${r['total_minutes'] ?? 0}',
          _ratePerMinute(r['avg_sell_rate_usd_per_min']),
          _money(r['total_user_paid']),
          _money(r['total_provider_cost']),
          _money(r['total_profit']),
          _percent(r['profit_percent']),
        ];
      }).toList(),
    );
  }

  static List<List<String>> _summaryRows(Map data) {
    return [
      ['Total Calls', '${data['total_calls'] ?? 0}'],
      ['Total Minutes', '${data['total_minutes'] ?? 0}'],
      ['Average Rate / Min', _ratePerMinute(data['avg_sell_rate_usd_per_min'])],
      ['Revenue', _money(data['total_revenue'])],
      ['Provider Cost', _money(data['total_provider_cost'])],
      ['Net Profit', _money(data['total_profit'])],
      ['Profit %', _percent(data['profit_percent'])],
    ];
  }

  static Future<void> _buildPdf({
    required String title,
    required List<String> headers,
    required List<List<String>> rows,
    List countrySummaryRows = const [],
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(20),
        footer: (context) => pw.Align(
          alignment: pw.Alignment.centerRight,
          child: pw.Text(
            'NetPhone Confidential Report - Page ${context.pageNumber}',
            style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey),
          ),
        ),
        build: (context) {
          return [
            pw.Text(
              'NetPhone',
              style: pw.TextStyle(fontSize: 26, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 4),
            pw.Text(
              title,
              style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 6),
            pw.Text(
              'Generated: ${DateTime.now()}',
              style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
            ),
            pw.Divider(),

            pw.SizedBox(height: 10),
            _table(
              headers: headers,
              rows: rows,
              fontSize: headers.length > 8 ? 7 : 9,
            ),
          ];
        },
      ),
    );

    await Printing.layoutPdf(onLayout: (format) async => pdf.save());
  }

  static pw.Widget _table({
    required List<String> headers,
    required List<List<String>> rows,
    double fontSize = 9,
  }) {
    return pw.TableHelper.fromTextArray(
      headers: headers,
      data: rows,
      headerStyle: pw.TextStyle(
        fontWeight: pw.FontWeight.bold,
        color: PdfColors.white,
        fontSize: fontSize,
      ),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.blueGrey800),
      cellStyle: pw.TextStyle(fontSize: fontSize),
      cellAlignment: pw.Alignment.centerLeft,
      border: pw.TableBorder.all(color: PdfColors.grey300),
      rowDecoration: const pw.BoxDecoration(color: PdfColors.white),
    );
  }
}
