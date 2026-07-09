import 'package:erp/features/catalog/presentation/utils/product_change_history_formatters.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('formatProductChangeHistoryDateTime', () {
    test('converts UTC to local device time', () {
      final utc = DateTime.utc(2026, 7, 6, 1, 18);
      final formatted = formatProductChangeHistoryDateTime(utc);
      final local = utc.toLocal();
      final expected =
          '${local.year.toString().padLeft(4, '0')}-'
          '${local.month.toString().padLeft(2, '0')}-'
          '${local.day.toString().padLeft(2, '0')} '
          '${local.hour.toString().padLeft(2, '0')}:'
          '${local.minute.toString().padLeft(2, '0')}';
      expect(formatted, expected);
    });
  });

  group('formatProductChangeHistorySummary', () {
    test('maps CREATED action to Vietnamese label', () {
      expect(
        formatProductChangeHistorySummary(
          summary: 'CREATED',
          changeType: 'CREATED',
        ),
        'Tạo sản phẩm',
      );
    });

    test('maps lowercase created summary', () {
      expect(
        formatProductChangeHistorySummary(
          summary: 'created',
          changeType: 'created',
        ),
        'Tạo sản phẩm',
      );
    });

    test('uses change type label when summary is descriptive text', () {
      expect(
        formatProductChangeHistorySummary(
          summary: 'Tạo từ dữ liệu mẫu',
          changeType: 'CREATED',
        ),
        'Tạo sản phẩm',
      );
    });
  });
}
