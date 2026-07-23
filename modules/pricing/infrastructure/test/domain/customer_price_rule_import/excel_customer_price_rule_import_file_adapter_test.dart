import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:test/test.dart';

import '../../../lib/src/domain/customer_price_rule_import/customer_price_rule_import_xlsx_codec.dart';
import '../../../lib/src/domain/customer_price_rule_import/excel_customer_price_rule_import_file_adapter.dart';

void main() {
  const adapter = ExcelCustomerPriceRuleImportFileAdapter();

  group('template generation', () {
    test('round-trips valid V1 workbook', () {
      final template = adapter.createTemplateV1();

      expect(template.templateVersion, 'customer_price_rules_v1');
      expect(template.fileName, 'customer_price_rules_v1.xlsx');
      expect(template.mimeType, contains('spreadsheetml'));

      final parseResult = adapter.parse(
        templateVersion: template.templateVersion,
        originalFileName: template.fileName,
        bytes: template.bytes,
      );

      expect(parseResult.isParsed, isFalse);
      expect(parseResult.fileErrorCodes, ['EMPTY_FILE']);
    });

    test('V1 template uses explicit product and unit headers', () {
      expect(ExcelCustomerPriceRuleImportFileAdapter.headers, const [
        'rule_id',
        'customer_id',
        'product_id',
        'product_unit_id',
        'rule_price',
        'effective_from',
        'effective_to',
        'note',
      ]);
    });

    test('rejects the previous V1 product_reference_id header', () {
      final result = adapter.parse(
        templateVersion:
            ExcelCustomerPriceRuleImportFileAdapter.templateVersion,
        originalFileName: 'customer_price_rules_v1.xlsx',
        bytes: _workbookBytes(
          [_row(price: '100000')],
          headers: const [
            'rule_id',
            'customer_id',
            'product_reference_id',
            'rule_price',
            'effective_from',
            'effective_to',
            'note',
          ],
        ),
      );

      expect(result.fileErrorCodes, ['TEMPLATE_HEADER_INVALID']);
    });

    test('maps explicit product and unit UUIDs', () {
      final result = adapter.parse(
        templateVersion:
            ExcelCustomerPriceRuleImportFileAdapter.templateVersion,
        originalFileName: 'customer_price_rules_v1.xlsx',
        bytes: _workbookBytes([
          _row(
            customerId: '00000000-0000-4000-8000-000000000001',
            productId: '00000000-0000-4000-8000-000000000101',
            productUnitId: '00000000-0000-4000-8000-000000000201',
            price: '100000',
          ),
        ]),
      );

      expect(
        result.rows.single.productId,
        '00000000-0000-4000-8000-000000000101',
      );
      expect(
        result.rows.single.productUnitId,
        '00000000-0000-4000-8000-000000000201',
      );
    });
  });

  group('parse failures', () {
    test('rejects unsupported template version', () {
      final result = adapter.parse(
        templateVersion: 'customer_price_rules_v2',
        originalFileName: 'customer_price_rules_v1.xlsx',
        bytes: _workbookBytes([]),
      );

      expect(result.fileErrorCodes, ['TEMPLATE_VERSION_UNSUPPORTED']);
    });

    test('rejects non-xlsx extension', () {
      final result = adapter.parse(
        templateVersion:
            ExcelCustomerPriceRuleImportFileAdapter.templateVersion,
        originalFileName: 'rules.xls',
        bytes: _workbookBytes([
          _row(
            customerId: '00000000-0000-4000-8000-000000000001',
            productId: '00000000-0000-4000-8000-000000000101',
            productUnitId: '00000000-0000-4000-8000-000000000201',
            price: '90000',
          ),
        ]),
      );

      expect(result.fileErrorCodes, ['UNSUPPORTED_FILE_TYPE']);
    });

    test('rejects malformed zip payload', () {
      final result = adapter.parse(
        templateVersion:
            ExcelCustomerPriceRuleImportFileAdapter.templateVersion,
        originalFileName: 'customer_price_rules_v1.xlsx',
        bytes: Uint8List.fromList([1, 2, 3, 4]),
      );

      expect(result.fileErrorCodes, ['UNSUPPORTED_FILE_TYPE']);
    });

    test('rejects missing data sheet', () {
      final bytes = CustomerPriceRuleImportXlsxCodec.encodeWorkbook(
        dataSheetName: 'wrong_sheet',
        instructionsSheetName: 'instructions',
        headers: ExcelCustomerPriceRuleImportFileAdapter.headers,
        dataRows: const [],
      );

      final result = adapter.parse(
        templateVersion:
            ExcelCustomerPriceRuleImportFileAdapter.templateVersion,
        originalFileName: 'customer_price_rules_v1.xlsx',
        bytes: bytes,
      );

      expect(result.fileErrorCodes, ['TEMPLATE_SHEET_INVALID']);
    });

    test('rejects invalid headers', () {
      final result = adapter.parse(
        templateVersion:
            ExcelCustomerPriceRuleImportFileAdapter.templateVersion,
        originalFileName: 'customer_price_rules_v1.xlsx',
        bytes: _workbookBytes(
          [_row(price: '100')],
          headers: const ['customer_id', 'product_reference_id'],
        ),
      );

      expect(result.fileErrorCodes, ['TEMPLATE_HEADER_INVALID']);
    });

    test('rejects an extra header column', () {
      final result = adapter.parse(
        templateVersion:
            ExcelCustomerPriceRuleImportFileAdapter.templateVersion,
        originalFileName: 'customer_price_rules_v1.xlsx',
        bytes: _workbookBytes(
          [_row(price: '100')],
          headers: [
            ...ExcelCustomerPriceRuleImportFileAdapter.headers,
            'unexpected',
          ],
        ),
      );

      expect(result.fileErrorCodes, ['TEMPLATE_HEADER_INVALID']);
    });

    test('rejects formulas even when the cell has a cached value', () {
      final bytes = _replaceZipText(
        _workbookBytes([
          _row(
            customerId: '00000000-0000-4000-8000-000000000001',
            productId: '00000000-0000-4000-8000-000000000101',
            productUnitId: '00000000-0000-4000-8000-000000000201',
            price: '90000',
          ),
        ]),
        'xl/worksheets/sheet1.xml',
        (xml) => xml.replaceFirstMapped(
          RegExp(r'(<c r="E2"[^>]*>)(<v>)'),
          (match) => '${match.group(1)}<f>45000+45000</f>${match.group(2)}',
        ),
      );

      final result = adapter.parse(
        templateVersion:
            ExcelCustomerPriceRuleImportFileAdapter.templateVersion,
        originalFileName: 'customer_price_rules_v1.xlsx',
        bytes: bytes,
      );

      expect(result.fileErrorCodes, ['FORMULA_NOT_SUPPORTED']);
    });

    test('rejects archives above the entry-count limit', () {
      final archive = Archive();
      for (
        var index = 0;
        index <= CustomerPriceRuleImportXlsxCodec.maxArchiveEntries;
        index++
      ) {
        archive.addFile(ArchiveFile('entry-$index.xml', 1, [index & 0xff]));
      }

      final result = adapter.parse(
        templateVersion:
            ExcelCustomerPriceRuleImportFileAdapter.templateVersion,
        originalFileName: 'customer_price_rules_v1.xlsx',
        bytes: Uint8List.fromList(ZipEncoder().encode(archive)),
      );

      expect(result.fileErrorCodes, ['ARCHIVE_LIMIT_EXCEEDED']);
    });

    test('rejects archives above the uncompressed-size limit', () {
      final oversizedContent = Uint8List(
        CustomerPriceRuleImportXlsxCodec.maxUncompressedBytes + 1,
      );
      final archive = Archive()
        ..addFile(
          ArchiveFile(
            'xl/worksheets/sheet1.xml',
            oversizedContent.length,
            oversizedContent,
          ),
        );

      final result = adapter.parse(
        templateVersion:
            ExcelCustomerPriceRuleImportFileAdapter.templateVersion,
        originalFileName: 'customer_price_rules_v1.xlsx',
        bytes: Uint8List.fromList(ZipEncoder().encode(archive)),
      );

      expect(result.fileErrorCodes, ['ARCHIVE_LIMIT_EXCEEDED']);
    });

    test('rejects empty data rows', () {
      final result = adapter.parse(
        templateVersion:
            ExcelCustomerPriceRuleImportFileAdapter.templateVersion,
        originalFileName: 'customer_price_rules_v1.xlsx',
        bytes: _workbookBytes(const []),
      );

      expect(result.fileErrorCodes, ['EMPTY_FILE']);
    });
  });

  group('parse successes', () {
    test('ignores blank physical rows and preserves excel row numbers', () {
      final result = adapter.parse(
        templateVersion:
            ExcelCustomerPriceRuleImportFileAdapter.templateVersion,
        originalFileName: 'customer_price_rules_v1.xlsx',
        bytes: _workbookBytes([
          _row(),
          _row(),
          _row(
            customerId: '00000000-0000-4000-8000-000000000001',
            productId: '00000000-0000-4000-8000-000000000101',
            productUnitId: '00000000-0000-4000-8000-000000000201',
            price: '90,000',
            effectiveFrom: '2026-07-16',
            note: '  hello  ',
          ),
        ]),
      );

      expect(result.isParsed, isTrue);
      expect(result.rows, hasLength(1));
      expect(result.rows.single.rowNumber, 4);
      expect(result.rows.single.price, '90,000');
      expect(result.rows.single.note, '  hello  ');
    });

    test('accepts text date cells as yyyy-MM-dd', () {
      final result = adapter.parse(
        templateVersion:
            ExcelCustomerPriceRuleImportFileAdapter.templateVersion,
        originalFileName: 'customer_price_rules_v1.xlsx',
        bytes: _workbookBytes([
          _row(
            customerId: '00000000-0000-4000-8000-000000000001',
            productId: '00000000-0000-4000-8000-000000000101',
            productUnitId: '00000000-0000-4000-8000-000000000201',
            price: '90000',
            effectiveFrom: '2026-07-16',
          ),
        ]),
      );

      expect(result.rows.single.effectiveFrom, '2026-07-16');
    });

    test('parses sparse rows and native dates from LibreOffice fixture', () {
      final fixture = _fixtureFile('customer_price_rules_v1_libreoffice.xlsx');

      final result = adapter.parse(
        templateVersion:
            ExcelCustomerPriceRuleImportFileAdapter.templateVersion,
        originalFileName: fixture.uri.pathSegments.last,
        bytes: fixture.readAsBytesSync(),
      );

      expect(result.isParsed, isTrue);
      expect(result.rows, hasLength(2));
      expect(result.rows.map((row) => row.rowNumber), [2, 5]);
      expect(result.rows.first.effectiveFrom, '2026-07-16');
      expect(result.rows.last.effectiveTo, '2026-12-31');
    });

    test('reads inline and rich text cells', () {
      var bytes = _workbookBytes([
        _row(
          customerId: '00000000-0000-4000-8000-000000000001',
          productId: '00000000-0000-4000-8000-000000000101',
            productUnitId: '00000000-0000-4000-8000-000000000201',
          price: '90000',
          note: 'placeholder',
        ),
      ]);
      bytes = _replaceZipText(
        bytes,
        'xl/worksheets/sheet1.xml',
        (xml) => xml.replaceFirst(
          RegExp(r'<c r="H2"[^>]*><v>[^<]*</v></c>'),
          '<c r="H2" t="inlineStr"><is><r><t>rich </t></r><r><t>note</t></r></is></c>',
        ),
      );

      final result = adapter.parse(
        templateVersion:
            ExcelCustomerPriceRuleImportFileAdapter.templateVersion,
        originalFileName: 'customer_price_rules_v1.xlsx',
        bytes: bytes,
      );

      expect(result.rows.single.note, 'rich note');
    });

    test('rejects row limit above 2000', () {
      final rows = List<_RowData>.generate(
        2001,
        (_) => _row(
          customerId: '00000000-0000-4000-8000-000000000001',
          productId: '00000000-0000-4000-8000-000000000101',
            productUnitId: '00000000-0000-4000-8000-000000000201',
          price: '90000',
        ),
      );

      final result = adapter.parse(
        templateVersion:
            ExcelCustomerPriceRuleImportFileAdapter.templateVersion,
        originalFileName: 'customer_price_rules_v1.xlsx',
        bytes: _workbookBytes(rows),
      );

      expect(result.fileErrorCodes, ['ROW_LIMIT_EXCEEDED']);
    });

    test('accepts exactly 2000 non-empty rows', () {
      final rows = List<_RowData>.generate(
        2000,
        (_) => _row(
          customerId: '00000000-0000-4000-8000-000000000001',
          productId: '00000000-0000-4000-8000-000000000101',
            productUnitId: '00000000-0000-4000-8000-000000000201',
          price: '90000',
        ),
      );

      final result = adapter.parse(
        templateVersion:
            ExcelCustomerPriceRuleImportFileAdapter.templateVersion,
        originalFileName: 'customer_price_rules_v1.xlsx',
        bytes: _workbookBytes(rows),
      );

      expect(result.isParsed, isTrue);
      expect(result.rows, hasLength(2000));
    });
  });
}

File _fixtureFile(String name) {
  final packageRelative = File('test/fixtures/$name');
  if (packageRelative.existsSync()) {
    return packageRelative;
  }
  return File('modules/pricing/infrastructure/test/fixtures/$name');
}

Uint8List _replaceZipText(
  Uint8List bytes,
  String entryName,
  String Function(String xml) replace,
) {
  final source = ZipDecoder().decodeBytes(bytes);
  final output = Archive();
  for (final file in source.files) {
    final content = List<int>.from(file.content as List<int>);
    output.addFile(
      ArchiveFile(
        file.name,
        content.length,
        file.name == entryName
            ? utf8.encode(replace(utf8.decode(content)))
            : content,
      ),
    );
  }
  return Uint8List.fromList(ZipEncoder().encode(output));
}

class _RowData {
  const _RowData({
    this.ruleId = '',
    this.customerId = '',
    this.productId = '',
    this.productUnitId = '',
    this.price = '',
    this.effectiveFrom = '',
    this.effectiveTo = '',
    this.note = '',
  });

  final String ruleId;
  final String customerId;
  final String productId;
  final String productUnitId;
  final String price;
  final String effectiveFrom;
  final String effectiveTo;
  final String note;
}

_RowData _row({
  String ruleId = '',
  String customerId = '',
  String productId = '',
  String productUnitId = '',
  String price = '',
  String effectiveFrom = '',
  String effectiveTo = '',
  String note = '',
}) => _RowData(
  ruleId: ruleId,
  customerId: customerId,
  productId: productId,
  productUnitId: productUnitId,
  price: price,
  effectiveFrom: effectiveFrom,
  effectiveTo: effectiveTo,
  note: note,
);

Uint8List _workbookBytes(List<_RowData> rows, {List<String>? headers}) {
  final headerRow = headers ?? ExcelCustomerPriceRuleImportFileAdapter.headers;
  return CustomerPriceRuleImportXlsxCodec.encodeWorkbook(
    dataSheetName: ExcelCustomerPriceRuleImportFileAdapter.dataSheetName,
    instructionsSheetName:
        ExcelCustomerPriceRuleImportFileAdapter.instructionsSheetName,
    headers: headerRow,
    dataRows: rows
        .map(
          (row) => [
            row.ruleId,
            row.customerId,
            row.productId,
            row.productUnitId,
            row.price,
            row.effectiveFrom,
            row.effectiveTo,
            row.note,
          ],
        )
        .toList(growable: false),
  );
}
