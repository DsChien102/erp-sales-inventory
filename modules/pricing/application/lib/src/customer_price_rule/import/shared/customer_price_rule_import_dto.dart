import 'customer_price_rule_import_enums.dart';

final class CustomerPriceRuleImportDto {
  const CustomerPriceRuleImportDto({
    required this.id,
    required this.templateVersion,
    required this.originalFileName,
    required this.importMode,
    required this.status,
    required this.version,
    required this.totalRows,
    required this.validRows,
    required this.warningRows,
    required this.errorRows,
    required this.importedRows,
    required this.skippedRows,
    required this.failedRows,
    required this.fileErrorCodes,
    required this.createdAt,
    this.confirmedAt,
    this.canceledAt,
  });

  final String id;
  final String templateVersion;
  final String originalFileName;
  final CustomerPriceRuleImportMode importMode;
  final CustomerPriceRuleImportStatus status;
  final int version;
  final int totalRows;
  final int validRows;
  final int warningRows;
  final int errorRows;
  final int importedRows;
  final int skippedRows;
  final int failedRows;
  final List<String> fileErrorCodes;
  final DateTime createdAt;
  final DateTime? confirmedAt;
  final DateTime? canceledAt;
}
