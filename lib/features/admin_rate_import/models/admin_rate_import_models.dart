/// ==========================================================
/// admin_rate_import_models.dart
///
/// কাজ:
/// - Backend Rate Import API response model করা
/// - CSV file information রাখা
/// - Validation summary রাখা
/// - Import result রাখা
/// ==========================================================

class ProviderRateDeckFile {
  final String file;
  final int sizeBytes;
  final DateTime? modifiedAt;

  const ProviderRateDeckFile({
    required this.file,
    required this.sizeBytes,
    required this.modifiedAt,
  });

  factory ProviderRateDeckFile.fromJson(Map<String, dynamic> json) {
    return ProviderRateDeckFile(
      file: json['file']?.toString() ?? '',
      sizeBytes: _toInt(json['size_bytes']),
      modifiedAt: DateTime.tryParse(json['modified_at']?.toString() ?? ''),
    );
  }

  String get readableSize {
    if (sizeBytes >= 1024 * 1024) {
      return '${(sizeBytes / (1024 * 1024)).toStringAsFixed(2)} MB';
    }

    if (sizeBytes >= 1024) {
      return '${(sizeBytes / 1024).toStringAsFixed(2)} KB';
    }

    return '$sizeBytes bytes';
  }
}

class RateDeckFileListResult {
  final String provider;
  final String storageFolder;
  final List<ProviderRateDeckFile> files;

  const RateDeckFileListResult({
    required this.provider,
    required this.storageFolder,
    required this.files,
  });

  factory RateDeckFileListResult.fromJson(Map<String, dynamic> json) {
    final rawFiles = json['files'];

    return RateDeckFileListResult(
      provider: json['provider']?.toString() ?? '',
      storageFolder: json['storage_folder']?.toString() ?? '',
      files: rawFiles is List
          ? rawFiles
                .whereType<Map>()
                .map(
                  (item) => ProviderRateDeckFile.fromJson(
                    Map<String, dynamic>.from(item),
                  ),
                )
                .toList()
          : const [],
    );
  }
}

class RateDeckValidationResult {
  final bool dryRun;
  final String providerCode;
  final String sourceFile;
  final String sourceSha256;

  final int totalLinesRead;
  final int dataRowsRead;
  final int validRows;
  final int skippedRows;
  final int uniquePrefixes;
  final int duplicatePrefixRows;

  final Map<String, int> skippedByReason;

  const RateDeckValidationResult({
    required this.dryRun,
    required this.providerCode,
    required this.sourceFile,
    required this.sourceSha256,
    required this.totalLinesRead,
    required this.dataRowsRead,
    required this.validRows,
    required this.skippedRows,
    required this.uniquePrefixes,
    required this.duplicatePrefixRows,
    required this.skippedByReason,
  });

  factory RateDeckValidationResult.fromJson(Map<String, dynamic> json) {
    final skipped = <String, int>{};

    final rawSkipped = json['skipped_by_reason'];

    if (rawSkipped is Map) {
      for (final entry in rawSkipped.entries) {
        skipped[entry.key.toString()] = _toInt(entry.value);
      }
    }

    return RateDeckValidationResult(
      dryRun: json['dry_run'] == true,
      providerCode: json['provider_code']?.toString() ?? '',
      sourceFile: json['source_file']?.toString() ?? '',
      sourceSha256: json['source_sha256']?.toString() ?? '',
      totalLinesRead: _toInt(json['total_lines_read']),
      dataRowsRead: _toInt(json['data_rows_read']),
      validRows: _toInt(json['valid_rows']),
      skippedRows: _toInt(json['skipped_rows'] ?? json['rows_skipped']),
      uniquePrefixes: _toInt(json['unique_prefixes']),
      duplicatePrefixRows: _toInt(json['duplicate_prefix_rows']),
      skippedByReason: skipped,
    );
  }
}

class RateDeckImportResult {
  final bool duplicateImport;
  final String providerCode;
  final String providerPlanCode;
  final String sourceFile;

  final int? rateCardId;
  final String? rateCardCode;
  final int uniqueRatesImported;
  final int rowsSkipped;

  const RateDeckImportResult({
    required this.duplicateImport,
    required this.providerCode,
    required this.providerPlanCode,
    required this.sourceFile,
    required this.rateCardId,
    required this.rateCardCode,
    required this.uniqueRatesImported,
    required this.rowsSkipped,
  });

  factory RateDeckImportResult.fromJson(Map<String, dynamic> json) {
    return RateDeckImportResult(
      duplicateImport: json['duplicate_import'] == true,
      providerCode: json['provider_code']?.toString() ?? '',
      providerPlanCode: json['provider_plan_code']?.toString() ?? '',
      sourceFile: json['source_file']?.toString() ?? '',
      rateCardId: json['rate_card_id'] == null
          ? null
          : _toInt(json['rate_card_id']),
      rateCardCode: json['rate_card_code']?.toString(),
      uniqueRatesImported: _toInt(json['unique_rates_imported']),
      rowsSkipped: _toInt(json['rows_skipped']),
    );
  }
}

int _toInt(dynamic value) {
  if (value is int) {
    return value;
  }

  if (value is num) {
    return value.toInt();
  }

  return int.tryParse(value?.toString() ?? '') ?? 0;
}
