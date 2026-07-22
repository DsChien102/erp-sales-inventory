import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:vet45_pricing_application/application.dart';

final class PricingImportPickedFile {
  const PricingImportPickedFile({required this.name, required this.bytes});

  final String name;
  final Uint8List bytes;
}

abstract interface class PricingImportFileService {
  Future<PricingImportPickedFile?> pickXlsx();

  Future<bool> saveTemplate(CustomerPriceRuleImportTemplateDto template);
}

final class DevicePricingImportFileService implements PricingImportFileService {
  const DevicePricingImportFileService();

  @override
  Future<PricingImportPickedFile?> pickXlsx() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['xlsx'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return null;
    final file = result.files.first;
    final bytes = file.bytes;
    if (bytes == null) return null;
    return PricingImportPickedFile(name: file.name, bytes: bytes);
  }

  @override
  Future<bool> saveTemplate(
    CustomerPriceRuleImportTemplateDto template,
  ) async {
    final path = await FilePicker.saveFile(
      dialogTitle: 'Lưu file mẫu import giá riêng',
      fileName: template.fileName,
      type: FileType.custom,
      allowedExtensions: const ['xlsx'],
      bytes: template.bytes,
    );
    return kIsWeb || path != null;
  }
}
