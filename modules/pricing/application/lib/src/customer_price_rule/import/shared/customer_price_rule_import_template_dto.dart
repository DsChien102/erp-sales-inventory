import 'dart:typed_data';

final class CustomerPriceRuleImportTemplateDto {
  static const versionV1 = 'customer_price_rules_v1';
  static const fileNameV1 = 'customer_price_rules_v1.xlsx';

  const CustomerPriceRuleImportTemplateDto({
    required this.templateVersion,
    required this.fileName,
    required this.mimeType,
    required this.bytes,
  });

  final String templateVersion;
  final String fileName;
  final String mimeType;
  final Uint8List bytes;
}
