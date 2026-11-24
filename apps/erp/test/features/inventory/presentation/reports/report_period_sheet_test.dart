import 'package:erp/features/inventory/data/reports/reports_repository.dart';
import 'package:erp/features/inventory/logic/reports/report_period.dart';
import 'package:erp/features/inventory/presentation/reports/stock_report_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';

import 'reports_test_support.dart';

void main() {
  late FakeReportsRepository repo;

  setUp(() async {
    await GetIt.I.reset();
    repo = FakeReportsRepository();
    GetIt.I.registerSingleton<ReportsRepository>(repo);
  });

  tearDown(() async {
    await GetIt.I.reset();
  });

  Widget page({ReportPeriod? period}) => reportsApp(
        StockReportPage(
          clock: () => reportsToday,
          initialPeriod: period,
          onOpenProduct: (_, _) {},
          onBack: () {},
        ),
      );

  testWidgets('period_sheet_last_month_applies', (tester) async {
    await tester.pumpWidget(page());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Tháng 11/2026'));
    await tester.pumpAndSettle();
    expect(find.text('Chọn kỳ'), findsOneWidget);
    expect(find.text('Tháng này'), findsOneWidget);
    expect(find.text('Tùy chọn'), findsOneWidget);

    await tester.tap(find.text('Tháng trước'));
    await tester.pumpAndSettle();

    expect(find.text('Chọn kỳ'), findsNothing);
    expect(repo.stockReportPeriods.last, ReportPeriod.lastMonth(reportsToday));
    expect(find.text('Tháng 10/2026'), findsOneWidget);
  });

  testWidgets('period_sheet_invalid_range shows error and does not call repo', (
    tester,
  ) async {
    await tester.pumpWidget(
      page(
        period: ReportPeriod(from: DateTime(2026, 11, 5), to: DateTime(2026, 11, 10)),
      ),
    );
    await tester.pumpAndSettle();
    final callsBefore = repo.stockReportPeriods.length;

    await tester.tap(find.widgetWithText(InkWell, '05/11 – 10/11/2026').first);
    await tester.pumpAndSettle();
    expect(find.text('Chọn kỳ'), findsOneWidget);
    expect(find.text('Từ ngày'), findsOneWidget);
    expect(find.text('Đến ngày'), findsOneWidget);

    // Đổi "Đến ngày" thành 03/11 (trước ngày bắt đầu 05/11).
    await tester.tap(find.text('10/11/2026').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('3').last);
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Áp dụng'));
    await tester.pumpAndSettle();

    expect(find.text('Ngày bắt đầu phải trước ngày kết thúc'), findsOneWidget);
    expect(find.text('Chọn kỳ'), findsOneWidget);
    expect(repo.stockReportPeriods.length, callsBefore);
  });
}
