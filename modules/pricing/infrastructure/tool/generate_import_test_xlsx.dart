import 'dart:io';

import '../lib/src/domain/customer_price_rule_import/customer_price_rule_import_xlsx_codec.dart';
import '../lib/src/domain/customer_price_rule_import/excel_customer_price_rule_import_file_adapter.dart';

void main() {
  final headers = ExcelCustomerPriceRuleImportFileAdapter.headers;
  final rows = <List<String>>[
    ['', 'KH000123', 'product-1', '180000', '2026-07-01', '', 'Giá hợp lệ — vaccine THI-50'],
    ['', 'KH000456', 'product-2', '95000', '2026-07-01', '2026-12-31', 'Giá hợp lệ — ANK-500'],
    ['', 'KH000789', 'product-3', '72000', '', '', 'Thiếu từ ngày — cảnh báo EFFECTIVE_FROM_DEFAULTED'],
    ['', 'KH000321', 'product-1', '-5000', '2026-07-01', '', 'Giá âm — không hợp lệ'],
    ['', 'KH000123', 'product-2', 'abc', '2026-07-01', '', 'Giá không phải số'],
    ['', '', 'product-1', '100000', '2026-07-01', '', 'Thiếu mã khách hàng'],
    ['', 'KH000456', '', '88000', '2026-07-01', '', 'Thiếu mã sản phẩm'],
    ['', 'KH_KHONG_TON_TAI', 'SKU_KHONG_TON_TAI', '50000', '2026-07-01', '', 'Tham chiếu KH/SP không tồn tại'],
    ['', 'KH000456', 'product-2', '50000', '2026-08-01', '', 'Giá dưới sàn ANK-500'],
    ['', 'KH000321', 'product-3', '75000', '2026-07-20', '2027-07-20', 'Giá hợp lệ — BIO-COLI'],
  ];

  final bytes = CustomerPriceRuleImportXlsxCodec.encodeWorkbook(
    dataSheetName: ExcelCustomerPriceRuleImportFileAdapter.dataSheetName,
    instructionsSheetName:
        ExcelCustomerPriceRuleImportFileAdapter.instructionsSheetName,
    headers: headers,
    dataRows: rows,
    instructionsText:
        'Template V1 — test FE import giá riêng. '
        'Headers: rule_id, customer_id, product_reference_id, rule_price, '
        'effective_from, effective_to, note. '
        'Mix valid / missing / negative / bad ref / below floor.',
  );

  final out = File(
    '/run/media/khanhlong/LONGGYM/AGAPI/vet45/apps/erp/test/features/pricing/fixtures/'
    'gia_rieng_import_test_mixed.xlsx',
  );
  out.parent.createSync(recursive: true);
  out.writeAsBytesSync(bytes);
  stdout.writeln('Wrote ${out.path} (${bytes.length} bytes, ${rows.length} data rows)');
}
