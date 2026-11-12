import 'package:erp/features/inventory/data/reports/reports_models.dart';
import 'package:erp/features/inventory/data/reports/reports_repository.dart';
import 'package:erp/features/inventory/presentation/reports/stock_card_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:vet45_design_system/design_system.dart';

import '../../support/inventory_test_surface.dart';
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
    ValueChanged<StockCardLine>? onOpen,
  }) {
    return reportsApp(
      StockCardPage(
        productId: 'p1',
        clock: () => reportsToday,
        onOpenMovement: onOpen ?? (_) {},
        onBack: () {},
      ),
      size: size,
    );
  }

  group('StockCardPage', () {
    testWidgets('card_lot_chips_390 chips with closing and lot reload', (
      tester,
    ) async {
      await tester.pumpWidget(page());
      await tester.pumpAndSettle();

      expect(find.text('Thẻ kho'), findsOneWidget);
      expect(find.text('Vắc xin Dại · VX-01 · hộp'), findsOneWidget);
      expect(find.text('Tất cả lô'), findsOneWidget);
      expect(find.text('Lô A'), findsOneWidget);
      expect(find.text('Lô B'), findsOneWidget);
      // dải số + giá trị
      expect(find.text('Đầu kỳ'), findsOneWidget);
      expect(find.text('Cuối kỳ'), findsOneWidget);
      expect(find.textContaining('1.300.000đ', findRichText: true), findsOneWidget);
      // cạnh đầu / cuối kỳ
      expect(find.text('Tồn đầu kỳ'), findsOneWidget);
      expect(find.text('Tồn cuối kỳ'), findsOneWidget);
      // dòng biến động
      expect(find.text('Nhận hàng PN-260904-08'), findsOneWidget);
      expect(find.text('+20'), findsOneWidget);
      expect(find.text('−2'), findsOneWidget);
      expect(find.text('Tồn 48'), findsOneWidget);

      await tester.tap(find.text('Lô A'));
      await tester.pumpAndSettle();
      expect(repo.stockCardLots.last, 'la');
    });

    testWidgets('card_non_lot_note_390 shows note and no chips', (tester) async {
      repo.stockCardResult = stockCardOf(lotTracked: false);
      await tester.pumpWidget(page());
      await tester.pumpAndSettle();

      expect(find.text('Sản phẩm không quản lý theo lô.'), findsOneWidget);
      expect(find.text('Tất cả lô'), findsNothing);
    });

    testWidgets('card_table_1280 has edge rows and lot column only when tracked', (
      tester,
    ) async {
      await tester.pumpWidget(page(size: const Size(1280, 800)));
      await tester.pumpAndSettle();

      expect(find.text('Tồn đầu kỳ'), findsOneWidget);
      expect(find.text('Tồn cuối kỳ'), findsOneWidget);
      for (final h in [
        'NGÀY NGHIỆP VỤ',
        'CHỨNG TỪ',
        'DIỄN GIẢI',
        'LÔ',
        'NHẬP',
        'XUẤT',
        'TỒN',
      ]) {
        expect(find.text(h), findsOneWidget, reason: h);
      }
      expect(find.text('Nhận hàng'), findsOneWidget);
      expect(find.text('Bán hàng'), findsOneWidget);
    });

    testWidgets('card_table_1280_non_lot hides lot column', (tester) async {
      repo.stockCardResult = stockCardOf(lotTracked: false);
      await tester.pumpWidget(page(size: const Size(1280, 800)));
      await tester.pumpAndSettle();

      expect(find.text('LÔ'), findsNothing);
    });

    testWidgets('card_staff_no_money_390', (tester) async {
      repo.stockCardResult = stockCardOf(masked: true);
      await tester.pumpWidget(page());
      await tester.pumpAndSettle();

      expect(findMoneyText(), findsNothing);
      expect(find.textContaining('Giá trị cuối kỳ', findRichText: true), findsNothing);
    });

    testWidgets('card_row_opens_movement', (tester) async {
      StockCardLine? opened;
      await tester.pumpWidget(page(onOpen: (l) => opened = l));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Nhận hàng PN-260904-08'));
      await tester.pumpAndSettle();
      expect(opened?.movementId, 'm1');
    });

    testWidgets('card_empty_with_lot_filter_action', (tester) async {
      repo.stockCardResult = stockCardOf(rows: const []);
      await tester.pumpWidget(page());
      await tester.pumpAndSettle();

      expect(find.text('Không có biến động trong kỳ'), findsOneWidget);
      expect(find.text('Xem tháng trước'), findsOneWidget);

      await tester.tap(find.text('Lô A'));
      await tester.pumpAndSettle();
      expect(find.text('Xem tất cả'), findsOneWidget);
    });

    testWidgets('card_back_to_stock_when_from_stock', (tester) async {
      useInventoryTestSurface(const Size(390, 844));
      final router = GoRouter(
        initialLocation: '/warehouse/reports/stock/p1',
        routes: [
          GoRoute(
            path: '/warehouse/reports/stock/:productId',
            builder: (_, state) => StockCardPage(
              productId: state.pathParameters['productId']!,
              fromStock: true,
              clock: () => reportsToday,
            ),
          ),
          GoRoute(
            path: '/warehouse/stock/:productId',
            builder: (_, _) => const Scaffold(body: Text('STOCK-DETAIL')),
          ),
          GoRoute(
            path: '/warehouse/reports/stock',
            builder: (_, _) => const Scaffold(body: Text('REPORT-LIST')),
          ),
        ],
      );
      await tester.pumpWidget(
        MaterialApp.router(theme: VTheme.lightTheme, routerConfig: router),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Quay lại'));
      await tester.pumpAndSettle();
      expect(find.text('STOCK-DETAIL'), findsOneWidget);
    });

    testWidgets('card_back_to_report_by_default', (tester) async {
      useInventoryTestSurface(const Size(390, 844));
      final router = GoRouter(
        initialLocation: '/warehouse/reports/stock/p1',
        routes: [
          GoRoute(
            path: '/warehouse/reports/stock/:productId',
            builder: (_, state) => StockCardPage(
              productId: state.pathParameters['productId']!,
              clock: () => reportsToday,
            ),
          ),
          GoRoute(
            path: '/warehouse/reports/stock',
            builder: (_, _) => const Scaffold(body: Text('REPORT-LIST')),
          ),
        ],
      );
      await tester.pumpWidget(
        MaterialApp.router(theme: VTheme.lightTheme, routerConfig: router),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Quay lại'));
      await tester.pumpAndSettle();
      expect(find.text('REPORT-LIST'), findsOneWidget);
    });
  });
}
