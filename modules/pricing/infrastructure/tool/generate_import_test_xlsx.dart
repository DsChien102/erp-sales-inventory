import 'dart:io';

import '../lib/src/domain/customer_price_rule_import/customer_price_rule_import_xlsx_codec.dart';
import '../lib/src/domain/customer_price_rule_import/excel_customer_price_rule_import_file_adapter.dart';

void main(List<String> args) {
  final libreOfficeFixture = args.contains('--libreoffice-fixture');
  final outputArgs = args.where((arg) => !arg.startsWith('--')).toList();
  if (outputArgs.length != 1) {
    throw ArgumentError('Expected exactly one output .xlsx path.');
  }
  final out = File(outputArgs.single);
  final rows = libreOfficeFixture
      ? _libreOfficeRows()
      : _mixedManualTestRows();
  final bytes = CustomerPriceRuleImportXlsxCodec.encodeWorkbook(
    dataSheetName: ExcelCustomerPriceRuleImportFileAdapter.dataSheetName,
    instructionsSheetName:
        ExcelCustomerPriceRuleImportFileAdapter.instructionsSheetName,
    headers: ExcelCustomerPriceRuleImportFileAdapter.headers,
    dataRows: rows,
    instructionsText:
        'Template V1: product_id và product_unit_id là UUID bắt buộc.',
  );
  out.parent.createSync(recursive: true);
  out.writeAsBytesSync(bytes);
  stdout.writeln(
    'Wrote ${out.path} (${bytes.length} bytes, ${rows.length} data rows)',
  );
}

List<List<String>> _libreOfficeRows() => [
  [
    '',
    '00000000-0000-4000-8000-000000000001',
    '00000000-0000-4000-8000-000000000101',
    '00000000-0000-4000-8000-000000000201',
    '100000',
    '2026-07-16',
    '',
    'Base unit',
  ],
  List.filled(8, ''),
  List.filled(8, ''),
  [
    '',
    '00000000-0000-4000-8000-000000000002',
    '00000000-0000-4000-8000-000000000101',
    '00000000-0000-4000-8000-000000000202',
    '950000',
    '2026-07-16',
    '2026-12-31',
    'Conversion unit',
  ],
];

List<List<String>> _mixedManualTestRows() => [
  [
    '',
    '00000000-0000-4000-8000-000000000001',
    '00000000-0000-4000-8000-000000000101',
    '00000000-0000-4000-8000-000000000201',
    '180000',
    '2026-07-01',
    '',
    'Valid base unit',
  ],
  [
    '',
    '00000000-0000-4000-8000-000000000002',
    '00000000-0000-4000-8000-000000000101',
    '00000000-0000-4000-8000-000000000202',
    '950000',
    '2026-07-01',
    '2026-12-31',
    'Valid conversion unit',
  ],
  [
    '',
    '',
    '00000000-0000-4000-8000-000000000101',
    '00000000-0000-4000-8000-000000000201',
    '100000',
    '2026-07-01',
    '',
    'Blank customer',
  ],
  [
    '',
    '00000000-0000-4000-8000-000000000001',
    '',
    '00000000-0000-4000-8000-000000000201',
    '100000',
    '2026-07-01',
    '',
    'Blank product',
  ],
  [
    '',
    '00000000-0000-4000-8000-000000000001',
    '00000000-0000-4000-8000-000000000101',
    '',
    '100000',
    '2026-07-01',
    '',
    'Blank unit',
  ],
  [
    '',
    '00000000-0000-4000-8000-000000000001',
    '00000000-0000-4000-8000-000000000101',
    '00000000-0000-4000-8000-000000000299',
    '100000',
    '2026-07-01',
    '',
    'Unit from another product',
  ],
  [
    '',
    '00000000-0000-4000-8000-000000000001',
    '00000000-0000-4000-8000-000000000101',
    '00000000-0000-4000-8000-000000000201',
    'abc',
    '2026-07-01',
    '',
    'Invalid price',
  ],
  [
    '',
    '00000000-0000-4000-8000-000000000001',
    '00000000-0000-4000-8000-000000000101',
    '00000000-0000-4000-8000-000000000201',
    '100000',
    '',
    '',
    'Blank effective date warning',
  ],
  [
    '',
    '00000000-0000-4000-8000-000000000001',
    '00000000-0000-4000-8000-000000000101',
    '00000000-0000-4000-8000-000000000201',
    '50000',
    '2026-08-01',
    '',
    'Below floor',
  ],
  [
    '',
    '00000000-0000-4000-8000-000000000001',
    '00000000-0000-4000-8000-000000000101',
    '00000000-0000-4000-8000-000000000201',
    '180000',
    '2026-07-01',
    '',
    'Duplicate row',
  ],
];
