import 'dart:typed_data';

final class CustomerPriceRuleImportTemplateDto {
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
