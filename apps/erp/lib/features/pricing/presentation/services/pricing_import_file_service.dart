import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:vet45_pricing_application/application.dart';

import 'pricing_import_log_xlsx_builder.dart';

final class PricingImportPickedFile {
  const PricingImportPickedFile({required this.name, required this.bytes});

  final String name;
  final Uint8List bytes;
}

abstract interface class PricingImportFileService {
  Future<PricingImportPickedFile?> pickXlsx();

  Future<bool> saveTemplate(CustomerPriceRuleImportTemplateDto template);

  Future<bool> saveImportLog({
    required String fileName,
    required Uint8List bytes,
  });

  /// FE-only: build import result workbook (không qua application port).
  Uint8List buildImportLogXlsx({
    required List<CustomerPriceRuleImportRowPreviewDto> rows,
  });
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
      dialogTitle: 'Lưu file mẫu nhập giá riêng',
      fileName: template.fileName,
      type: FileType.custom,
      allowedExtensions: const ['xlsx'],
      bytes: template.bytes,
    );
    return kIsWeb || path != null;
  }

  @override
  Future<bool> saveImportLog({
    required String fileName,
    required Uint8List bytes,
  }) async {
    final path = await FilePicker.saveFile(
      dialogTitle: 'Lưu nhật ký nhập giá riêng',
      fileName: fileName,
      type: FileType.custom,
      allowedExtensions: const ['xlsx'],
      bytes: bytes,
    );
    return kIsWeb || path != null;
  }

  @override
  Uint8List buildImportLogXlsx({
    required List<CustomerPriceRuleImportRowPreviewDto> rows,
  }) => PricingImportLogXlsxBuilder.build(rows: rows);
}
