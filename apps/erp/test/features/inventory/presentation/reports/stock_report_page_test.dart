import 'package:erp/features/inventory/data/reports/reports_models.dart';
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

  Widget page({
    Size size = const Size(390, 844),
    void Function(StockReportRow, ReportPeriod)? onOpen,
    ReportPeriod? period,
  }) {
    return reportsApp(
      StockReportPage(
        clock: () => reportsToday,
        initialPeriod: period,
        onOpenProduct: onOpen ?? (_, _) {},
        onBack: () {},
      ),
      size: size,
    );
  }

  group('StockReportPage', () {
    testWidgets('report_ready_390', (tester) async {
      await tester.pumpWidget(page());
      await tester.pumpAndSettle();

      expect(find.text('Báo cáo nhập – xuất – tồn'), findsOneWidget);
      expect(find.text('Tháng 11/2026'), findsOneWidget);
      expect(find.textContaining('Số liệu đến 13/11/2026 · 10:20'), findsOneWidget);
      expect(find.text('Vắc xin Dại'), findsOneWidget);
      expect(find.text('Đầu 122 · Nhập 10 · Xuất 12'), findsOneWidget);
      expect(find.text('120 hộp'), findsOneWidget);
      expect(
        find.textContaining('Tổng giá trị cuối kỳ', findRichText: true),
        findsOneWidget,
      );
      expect(find.textContaining('18.026.000đ', findRichText: true), findsOneWidget);
      expect(
        find.text('Không cộng các số lượng khác đơn vị thành một tổng giả.'),
        findsOneWidget,
      );
    });

    testWidgets('report_ready_1280 shows 7 columns when period includes today', (
      tester,
    ) async {
      await tester.pumpWidget(page(size: const Size(1280, 800)));
      await tester.pumpAndSettle();

      for (final h in [
        'SẢN PHẨM',
        'ĐẦU KỲ',
        'NHẬP',
        'XUẤT',
        'CUỐI KỲ',
        'KHẢ DỤNG',
        'GIÁ TRỊ CUỐI KỲ',
      ]) {
        expect(find.text(h), findsOneWidget, reason: h);
      }
      expect(find.text('VX-01 · hộp'), findsOneWidget);
    });

    testWidgets('report_available_only_current hides Khả dụng for past period', (
      tester,
    ) async {
      repo.stockReportResult = stockReportOf([stockRow(available: null)], showAvailable: false);
      await tester.pumpWidget(
        page(size: const Size(1280, 800), period: ReportPeriod.lastMonth(reportsToday)),
      );
      await tester.pumpAndSettle();

      expect(find.text('KHẢ DỤNG'), findsNothing);
      expect(find.text('CUỐI KỲ'), findsOneWidget);
    });

    testWidgets('report_staff_no_money_390 has no money text', (tester) async {
      repo.stockReportResult = stockReportOf(
        [stockRow(value: null)],
        masked: true,
      );
      await tester.pumpWidget(page());
      await tester.pumpAndSettle();

      expect(find.text('Vắc xin Dại'), findsOneWidget);
      expect(findMoneyText(), findsNothing);
      expect(find.textContaining('Tổng giá trị cuối kỳ', findRichText: true), findsNothing);
    });

    testWidgets('report_staff_no_money_1280 has no value column', (tester) async {
      repo.stockReportResult = stockReportOf(
        [stockRow(value: null)],
        masked: true,
      );
      await tester.pumpWidget(page(size: const Size(1280, 800)));
      await tester.pumpAndSettle();

      expect(find.text('GIÁ TRỊ CUỐI KỲ'), findsNothing);
      expect(findMoneyText(), findsNothing);
    });

    testWidgets('report_empty_prev_month_action loads last month', (tester) async {
      repo.stockReportResult = stockReportOf(const []);
      await tester.pumpWidget(page());
      await tester.pumpAndSettle();

      expect(find.text('Không có biến động trong kỳ'), findsOneWidget);
      expect(
        find.text('Đổi khoảng ngày hoặc sản phẩm để xem dữ liệu khác.'),
        findsOneWidget,
      );
      await tester.tap(find.text('Xem tháng trước'));
      await tester.pumpAndSettle();

      expect(repo.stockReportPeriods.last, ReportPeriod.lastMonth(reportsToday));
      expect(find.text('Tháng 10/2026'), findsOneWidget);
    });

    testWidgets('report_search_empty_clear shows Xem tất cả and clears', (
      tester,
    ) async {
      await tester.pumpWidget(page());
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'zzz');
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pumpAndSettle();

      expect(repo.stockReportSearches.last, 'zzz');
      expect(find.text('Không có biến động trong kỳ'), findsOneWidget);
      expect(find.text('Xem tất cả'), findsOneWidget);

      await tester.tap(find.text('Xem tất cả'));
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pumpAndSettle();

      expect(find.text('Vắc xin Dại'), findsOneWidget);
    });

    testWidgets('report_row_opens_card_with_period', (tester) async {
      StockReportRow? opened;
      ReportPeriod? openedPeriod;
      await tester.pumpWidget(
        page(onOpen: (r, p) {
          opened = r;
          openedPeriod = p;
        }),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Vắc xin Dại'));
      await tester.pumpAndSettle();

      expect(opened?.productId, 'p1');
      expect(openedPeriod, ReportPeriod.thisMonth(reportsToday));
    });
  });
}
