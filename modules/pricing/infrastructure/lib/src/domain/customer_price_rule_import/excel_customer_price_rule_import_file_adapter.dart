import 'dart:typed_data';

import 'package:vet45_pricing_application/application.dart';

import 'customer_price_rule_import_xlsx_codec.dart';

final class ExcelCustomerPriceRuleImportFileAdapter
    implements ICustomerPriceRuleImportFilePort {
  const ExcelCustomerPriceRuleImportFileAdapter();

  static const templateVersion = CustomerPriceRuleImportTemplateDto.versionV1;
  static const fileName = CustomerPriceRuleImportTemplateDto.fileNameV1;
  static const mimeType =
      'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
  static const dataSheetName = 'customer_price_rules';
  static const instructionsSheetName = 'instructions';
  static const maxDataRows = 2000;

  static const List<String> headers = [
    'rule_id',
    'customer_id',
    'product_reference_id',
    'rule_price',
    'effective_from',
    'effective_to',
    'note',
  ];

  @override
  CustomerPriceRuleImportTemplateDto createTemplateV1() {
    final bytes = CustomerPriceRuleImportXlsxCodec.encodeWorkbook(
      dataSheetName: dataSheetName,
      instructionsSheetName: instructionsSheetName,
      headers: headers,
      dataRows: const [],
    );
    return CustomerPriceRuleImportTemplateDto(
      templateVersion: templateVersion,
      fileName: fileName,
      mimeType: mimeType,
      bytes: bytes,
    );
  }

  @override
  CustomerPriceRuleImportParseResult parse({
    required String templateVersion,
    required String originalFileName,
    required Uint8List bytes,
  }) {
    if (templateVersion.trim() !=
        ExcelCustomerPriceRuleImportFileAdapter.templateVersion) {
      return CustomerPriceRuleImportParseResult.failed([
        'TEMPLATE_VERSION_UNSUPPORTED',
      ]);
    }
    final lowerName = originalFileName.toLowerCase().trim();
    if (!lowerName.endsWith('.xlsx')) {
      return CustomerPriceRuleImportParseResult.failed([
        'UNSUPPORTED_FILE_TYPE',
      ]);
    }
    if (bytes.isEmpty) {
      return CustomerPriceRuleImportParseResult.failed(['EMPTY_FILE']);
    }

    late final ({
      int headerRowNumber,
      List<String> headers,
      List<CustomerPriceRuleImportXlsxRow> rows,
    })
    decoded;
    try {
      decoded = CustomerPriceRuleImportXlsxCodec.decodeWorkbook(
        bytes,
        dataSheetName,
        instructionsSheetName: instructionsSheetName,
      );
    } on CustomerPriceRuleImportXlsxException catch (error) {
      return CustomerPriceRuleImportParseResult.failed([
        switch (error.failure) {
          CustomerPriceRuleImportXlsxFailure.templateSheetInvalid =>
            'TEMPLATE_SHEET_INVALID',
          CustomerPriceRuleImportXlsxFailure.formulaNotSupported =>
            'FORMULA_NOT_SUPPORTED',
          CustomerPriceRuleImportXlsxFailure.archiveLimitExceeded =>
            'ARCHIVE_LIMIT_EXCEEDED',
          CustomerPriceRuleImportXlsxFailure.unsupportedFile =>
            'UNSUPPORTED_FILE_TYPE',
        },
      ]);
    } on Object {
      return CustomerPriceRuleImportParseResult.failed([
        'UNSUPPORTED_FILE_TYPE',
      ]);
    }

    if (decoded.headerRowNumber != 1 || !_headersMatch(decoded.headers)) {
      return CustomerPriceRuleImportParseResult.failed([
        'TEMPLATE_HEADER_INVALID',
      ]);
    }

    final rows = <CustomerPriceRuleImportParsedRow>[];
    for (final decodedRow in decoded.rows) {
      final values = decodedRow.values;
      if (values.every((value) => value == null || value.trim().isEmpty)) {
        continue;
      }
      rows.add(
        CustomerPriceRuleImportParsedRow(
          rowNumber: decodedRow.rowNumber,
          ruleId: _nullableTrimmed(_valueAt(values, 0)),
          customerId: _nullableTrimmed(_valueAt(values, 1)),
          productReferenceId: _nullableTrimmed(_valueAt(values, 2)),
          price: _nullableTrimmed(_valueAt(values, 3)),
          effectiveFrom: _nullableTrimmed(_valueAt(values, 4)),
          effectiveTo: _nullableTrimmed(_valueAt(values, 5)),
          note: _valueAt(values, 6),
        ),
      );
      if (rows.length > maxDataRows) {
        return CustomerPriceRuleImportParseResult.failed([
          'ROW_LIMIT_EXCEEDED',
        ]);
      }
    }

    if (rows.isEmpty) {
      return CustomerPriceRuleImportParseResult.failed(['EMPTY_FILE']);
    }

    return CustomerPriceRuleImportParseResult.parsed(rows);
  }

  bool _headersMatch(List<String> actualHeaders) {
    if (actualHeaders.length != headers.length) {
      return false;
    }
    for (var index = 0; index < headers.length; index++) {
      if (actualHeaders[index] != headers[index]) {
        return false;
      }
    }
    return true;
  }

  String? _valueAt(List<String?> values, int index) =>
      index < values.length ? values[index] : null;

  String? _nullableTrimmed(String? value) {
    if (value == null) {
      return null;
    }
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
}
