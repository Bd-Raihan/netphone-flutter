import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../models/admin_call_activity_model.dart';
import 'admin_call_activity_service.dart';

// ============================================================
// 🇧🇩 ADMIN CALL ACTIVITY / CDR PDF SERVICE
//
// কাজ:
// - নির্দিষ্ট Date Range অনুযায়ী Call Activity data load করবে
// - Pagination ব্যবহার করে selected period-এর সব matching record আনবে
// - A4 Landscape professional PDF তৈরি করবে
// - Calling / Billing / Wallet logic পরিবর্তন করে না
// ============================================================

class AdminCallActivityPdfService {
  static const int _pageSize = 200;

  // ============================================================
  // 🇧🇩 DATE FORMAT
  // ============================================================

  static String _two(int value) {
    return value.toString().padLeft(2, '0');
  }

  static String _formatDate(DateTime? value) {
    if (value == null) {
      return '-';
    }

    final local = value.toLocal();

    return '${_two(local.day)}/'
        '${_two(local.month)}/'
        '${local.year}';
  }

  static String _formatDateTime(DateTime? value) {
    if (value == null) {
      return '-';
    }

    final local = value.toLocal();

    return '${_two(local.day)}/'
        '${_two(local.month)}/'
        '${local.year} '
        '${_two(local.hour)}:'
        '${_two(local.minute)}:'
        '${_two(local.second)}';
  }

  static String _formatDuration(int seconds) {
    if (seconds <= 0) {
      return '00:00';
    }

    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final secs = seconds % 60;

    if (hours > 0) {
      return '${_two(hours)}:'
          '${_two(minutes)}:'
          '${_two(secs)}';
    }

    return '${_two(minutes)}:'
        '${_two(secs)}';
  }

  static String _formatProvider(String provider) {
    final value = provider.trim();

    if (value.isEmpty) {
      return 'Unknown';
    }

    switch (value.toLowerCase()) {
      case 'telnyx':
        return 'Telnyx';

      case 'twilio':
        return 'Twilio';

      default:
        return value[0].toUpperCase() + value.substring(1);
    }
  }

  static String _formatStatus(String status) {
    final value = status.trim();

    if (value.isEmpty) {
      return 'Unknown';
    }

    return value[0].toUpperCase() + value.substring(1);
  }

  // ============================================================
  // 🇧🇩 SELECTED DATE RANGE-এর সব CDR LOAD করবে
  //
  // Backend maximum 200 records/page হওয়ায় pagination loop করা হয়।
  // ============================================================

  static Future<List<AdminCallActivityItem>> _loadAllRecords({
    String? search,
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    final allRows = <AdminCallActivityItem>[];

    var offset = 0;

    while (true) {
      final result = await AdminCallActivityService.getCallActivity(
        search: search,
        fromDate: fromDate,
        toDate: toDate,
        limit: _pageSize,
        offset: offset,
      );

      allRows.addAll(result.calls);

      if (result.calls.isEmpty) {
        break;
      }

      if (allRows.length >= result.total) {
        break;
      }

      offset += result.calls.length;

      // Safety guard
      if (offset > 100000) {
        break;
      }
    }

    return allRows;
  }

  // ============================================================
  // 🇧🇩 PDF BUILD
  // ============================================================

  static Future<Uint8List> buildPdf({
    String? search,
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    final records = await _loadAllRecords(
      search: search,
      fromDate: fromDate,
      toDate: toDate,
    );

    if (records.isEmpty) {
      throw Exception('No call records found for the selected period.');
    }

    final document = pw.Document(
      title: 'NetPhone Call Activity CDR Report',
      author: 'NetPhone',
      creator: 'NetPhone Admin Panel',
    );

    final generatedAt = DateTime.now();

    document.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.fromLTRB(18, 20, 18, 20),

        header: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'NetPhone',
                        style: pw.TextStyle(
                          fontSize: 18,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.SizedBox(height: 2),
                      pw.Text(
                        'Call Activity / CDR Report',
                        style: pw.TextStyle(
                          fontSize: 13,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ],
                  ),

                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(
                        'Generated: '
                        '${_formatDateTime(generatedAt)}',
                        style: const pw.TextStyle(fontSize: 8),
                      ),
                      pw.SizedBox(height: 2),
                      pw.Text(
                        'Page ${context.pageNumber} '
                        'of ${context.pagesCount}',
                        style: const pw.TextStyle(fontSize: 8),
                      ),
                    ],
                  ),
                ],
              ),

              pw.SizedBox(height: 6),

              pw.Divider(thickness: 0.7),
            ],
          );
        },

        footer: (context) {
          return pw.Column(
            children: [
              pw.Divider(thickness: 0.5),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'NetPhone - Confidential Admin Report',
                    style: const pw.TextStyle(fontSize: 7),
                  ),
                  pw.Text(
                    'Page ${context.pageNumber}',
                    style: const pw.TextStyle(fontSize: 7),
                  ),
                ],
              ),
            ],
          );
        },

        build: (context) {
          final dateRangeText = fromDate != null || toDate != null
              ? '${fromDate != null ? _formatDate(fromDate) : 'Beginning'}'
                    ' - '
                    '${toDate != null ? _formatDate(toDate) : 'Present'}'
              : 'All available records';

          return [
            pw.SizedBox(height: 8),

            // ==================================================
            // 🇧🇩 REPORT FILTER INFORMATION
            // ==================================================
            pw.Container(
              padding: const pw.EdgeInsets.all(8),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(width: 0.5),
                borderRadius: pw.BorderRadius.circular(4),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'Date Range: $dateRangeText',
                    style: pw.TextStyle(
                      fontSize: 9,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.Text(
                    'Total Records: ${records.length}',
                    style: pw.TextStyle(
                      fontSize: 9,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            if (search != null && search.trim().isNotEmpty) ...[
              pw.SizedBox(height: 4),
              pw.Text(
                'Search Filter: ${search.trim()}',
                style: const pw.TextStyle(fontSize: 8),
              ),
            ],

            pw.SizedBox(height: 10),

            // ==================================================
            // 🇧🇩 CDR TABLE
            // ==================================================
            pw.TableHelper.fromTextArray(
              headers: const [
                'No.',
                'Origin Country',
                'App Number',
                'To Country',
                'To Number',
                'Date & Time',
                'Duration',
                'Provider',
                'Provider Number',
                'Status',
              ],

              data: List.generate(records.length, (index) {
                final call = records[index];

                return [
                  '${index + 1}',

                  call.originCountry.trim().isEmpty
                      ? 'Unknown'
                      : call.originCountry,

                  call.registeredNumber.trim().isEmpty
                      ? '-'
                      : call.registeredNumber,

                  call.destinationCountry.trim().isEmpty
                      ? 'Unknown'
                      : call.destinationCountry,

                  call.destinationNumber.trim().isEmpty
                      ? '-'
                      : call.destinationNumber,

                  _formatDateTime(call.startedAt),

                  _formatDuration(call.durationSeconds),

                  _formatProvider(call.provider),

                  call.providerPhoneNumber?.trim().isNotEmpty == true
                      ? call.providerPhoneNumber!.trim()
                      : 'Not recorded',

                  _formatStatus(call.status),
                ];
              }),

              headerStyle: pw.TextStyle(
                fontSize: 7,
                fontWeight: pw.FontWeight.bold,
              ),

              cellStyle: const pw.TextStyle(fontSize: 6.5),

              headerDecoration: const pw.BoxDecoration(
                color: PdfColors.grey300,
              ),

              cellAlignment: pw.Alignment.centerLeft,

              headerAlignment: pw.Alignment.centerLeft,

              border: pw.TableBorder.all(width: 0.35, color: PdfColors.grey600),

              cellPadding: const pw.EdgeInsets.symmetric(
                horizontal: 3,
                vertical: 4,
              ),

              columnWidths: {
                0: const pw.FixedColumnWidth(22),
                1: const pw.FixedColumnWidth(68),
                2: const pw.FixedColumnWidth(88),
                3: const pw.FixedColumnWidth(70),
                4: const pw.FixedColumnWidth(88),
                5: const pw.FixedColumnWidth(84),
                6: const pw.FixedColumnWidth(45),
                7: const pw.FixedColumnWidth(48),
                8: const pw.FixedColumnWidth(85),
                9: const pw.FixedColumnWidth(50),
              },
            ),

            pw.SizedBox(height: 8),

            pw.Text(
              'Note: Provider Number may show "Not recorded" '
              'for historical calls created before provider-number '
              'snapshot logging was enabled.',
              style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey700),
            ),
          ];
        },
      ),
    );

    return document.save();
  }

  // ============================================================
  // 🇧🇩 PDF PREVIEW / PRINT / SAVE
  // ============================================================

  static Future<void> previewPdf({
    String? search,
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    final bytes = await buildPdf(
      search: search,
      fromDate: fromDate,
      toDate: toDate,
    );

    await Printing.layoutPdf(
      name: _buildFileName(fromDate: fromDate, toDate: toDate),
      onLayout: (_) async => bytes,
    );
  }

  static String _buildFileName({DateTime? fromDate, DateTime? toDate}) {
    String compact(DateTime value) {
      return '${value.year}'
          '${_two(value.month)}'
          '${_two(value.day)}';
    }

    if (fromDate != null && toDate != null) {
      return 'NetPhone_CDR_'
          '${compact(fromDate)}_to_'
          '${compact(toDate)}.pdf';
    }

    if (fromDate != null) {
      return 'NetPhone_CDR_From_'
          '${compact(fromDate)}.pdf';
    }

    if (toDate != null) {
      return 'NetPhone_CDR_To_'
          '${compact(toDate)}.pdf';
    }

    return 'NetPhone_CDR_Report.pdf';
  }
}
