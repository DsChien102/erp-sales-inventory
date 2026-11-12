import 'package:erp/features/inventory/logic/reports/report_period.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final today = DateTime(2026, 11, 13);

  test('period_rules_this_month', () {
    final p = ReportPeriod.thisMonth(today);
    expect(p.from, DateTime(2026, 11, 1));
    expect(p.to, DateTime(2026, 11, 13));
    expect(reportPeriodLabel(p), 'Tháng 11/2026');
    expect(kindOf(p, today), ReportPeriodKind.thisMonth);
    expect(p.includesToday(today), isTrue);
  });

  test('period_rules_last_month', () {
    final p = ReportPeriod.lastMonth(today);
    expect(p.from, DateTime(2026, 10, 1));
    expect(p.to, DateTime(2026, 10, 31));
    expect(reportPeriodLabel(p), 'Tháng 10/2026');
    expect(kindOf(p, today), ReportPeriodKind.lastMonth);
    expect(p.includesToday(today), isFalse);
  });

  test('period_rules_last_month_across_year', () {
    final p = ReportPeriod.lastMonth(DateTime(2027, 1, 5));
    expect(p.from, DateTime(2026, 12, 1));
    expect(p.to, DateTime(2026, 12, 31));
  });

  test('period_rules_custom_label', () {
    final p = ReportPeriod(from: DateTime(2026, 11, 5), to: DateTime(2026, 11, 10));
    expect(reportPeriodLabel(p), '05/11 – 10/11/2026');
    expect(reportPeriodRange(p), '05/11 – 10/11/2026');
    expect(kindOf(p, today), ReportPeriodKind.custom);
  });

  test('period_rules_of_month_caps_today', () {
    expect(
      ReportPeriod.ofMonth(DateTime(2026, 10, 1), today),
      ReportPeriod(from: DateTime(2026, 10, 1), to: DateTime(2026, 10, 31)),
    );
    expect(
      ReportPeriod.ofMonth(DateTime(2026, 11, 1), today),
      ReportPeriod(from: DateTime(2026, 11, 1), to: DateTime(2026, 11, 13)),
    );
  });

  test('period_query_roundtrip_and_fallback', () {
    final p = ReportPeriod.fromQuery('2026-10-01', '2026-10-31', today);
    expect(p.toQuery(), {'from': '2026-10-01', 'to': '2026-10-31'});
    expect(ReportPeriod.fromQuery(null, null, today), ReportPeriod.thisMonth(today));
    expect(
      ReportPeriod.fromQuery('2026-11-10', '2026-11-01', today),
      ReportPeriod.thisMonth(today),
    );
  });

  test('custom_range_error_missing', () {
    expect(customRangeError(null, DateTime(2026, 11, 1)), 'Nhập ngày theo dạng dd/mm/yyyy');
    expect(customRangeError(DateTime(2026, 11, 1), null), 'Nhập ngày theo dạng dd/mm/yyyy');
  });

  test('custom_range_error_order', () {
    expect(
      customRangeError(DateTime(2026, 11, 10), DateTime(2026, 11, 1)),
      'Ngày bắt đầu phải trước ngày kết thúc',
    );
    expect(customRangeError(DateTime(2026, 11, 1), DateTime(2026, 11, 1)), isNull);
  });
}
