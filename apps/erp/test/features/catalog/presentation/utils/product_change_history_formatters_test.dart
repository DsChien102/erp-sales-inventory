import 'package:erp/features/catalog/presentation/utils/product_change_history_formatters.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vet45_catalog_application/application.dart';

void main() {
  group('formatProductChangeHistoryDateTime', () {
    test('converts UTC to fixed ICT (UTC+7), not device local time', () {
      final utc = DateTime.utc(2026, 7, 6, 1, 18);
      final formatted = formatProductChangeHistoryDateTime(utc);
      // 01:18 UTC + 7h = 08:18 ICT, same calendar day.
      expect(formatted, '2026-07-06 08:18');
    });
  });

  group('formatProductChangeHistorySummary', () {
    test('maps CREATED action token in summary to Vietnamese label', () {
      expect(
        formatProductChangeHistorySummary(
          summary: 'CREATED',
          changeType: ProductChangeHistoryAction.created,
        ),
        'Tạo sản phẩm',
      );
    });

    test('maps lowercase created summary', () {
      expect(
        formatProductChangeHistorySummary(
          summary: 'created',
          changeType: ProductChangeHistoryAction.created,
        ),
        'Tạo sản phẩm',
      );
    });

    test('maps UPDATED_PROFILE wire token to Vietnamese', () {
      expect(
        formatProductChangeHistorySummary(
          summary: 'UPDATED_PROFILE',
          changeType: ProductChangeHistoryAction.tryParse('UPDATED_PROFILE'),
        ),
        'Cập nhật hồ sơ sản phẩm',
      );
    });

    test('maps add_product_conversion_unit wire token to Vietnamese', () {
      expect(
        formatProductChangeHistorySummary(
          summary: 'add_product_conversion_unit',
          changeType: null,
        ),
        'Thêm đơn vị quy đổi',
      );
    });

    test('uses change type label when summary is descriptive text', () {
      expect(
        formatProductChangeHistorySummary(
          summary: 'Tạo từ dữ liệu mẫu',
          changeType: ProductChangeHistoryAction.created,
        ),
        'Tạo sản phẩm',
      );
    });
  });

  group('ProductChangeHistoryAction.labelVi', () {
    test('covers every action', () {
      for (final action in ProductChangeHistoryAction.values) {
        expect(action.labelVi, isNotEmpty);
      }
    });
  });
}
