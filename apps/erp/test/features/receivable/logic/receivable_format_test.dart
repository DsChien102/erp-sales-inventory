import 'package:erp/features/receivable/logic/receivable_format.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/receivable_fixtures.dart' as fx;

void main() {
  test('formatVnd có khoảng trắng và ₫', () {
    expect(formatVnd(18000000), '18.000.000 ₫');
    expect(formatVnd(0), '0 ₫');
    expect(formatVnd(1234567890), '1.234.567.890 ₫');
  });

  test('formatVndBare không có đơn vị', () {
    expect(formatVndBare(2000000), '2.000.000');
  });

  group('orderDueLabel', () {
    test('quá hạn lấy số ngày từ server', () {
      final l = orderDueLabel(dueDate: DateTime(2026, 11, 10), overdueDays: 8, today: fx.today);
      expect(l.kind, DueKind.overdue);
      expect(l.days, 8);
      expect(l.text, 'Quá hạn 8 ngày');
    });
    test('đến hạn hôm nay', () {
      final l = orderDueLabel(dueDate: DateTime(2026, 11, 18), overdueDays: 0, today: fx.today);
      expect(l.kind, DueKind.today);
      expect(l.text, 'Đến hạn hôm nay');
    });
    test('hẹn sau', () {
      final l = orderDueLabel(dueDate: DateTime(2026, 11, 25), overdueDays: 0, today: fx.today);
      expect(l.kind, DueKind.upcoming);
      expect(l.text, 'Hẹn 25/11');
    });
    test('không hẹn', () {
      final l = orderDueLabel(dueDate: null, overdueDays: 0, today: fx.today);
      expect(l.kind, DueKind.none);
      expect(l.text, 'Không có hẹn');
    });
  });

  group('customerDueLabel', () {
    test('quá hạn ưu tiên dù có hẹn sau', () {
      expect(
        customerDueLabel(maxOverdueDays: 8, nextDueDate: DateTime(2026, 11, 30), today: fx.today).text,
        'Quá hạn 8 ngày',
      );
    });
    test('hôm nay', () {
      expect(
        customerDueLabel(maxOverdueDays: 0, nextDueDate: DateTime(2026, 11, 18), today: fx.today).text,
        'Đến hạn hôm nay',
      );
    });
    test('không hẹn', () {
      expect(
        customerDueLabel(maxOverdueDays: 0, nextDueDate: null, today: fx.today).text,
        'Không có hẹn',
      );
    });
  });
}
