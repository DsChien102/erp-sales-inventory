import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:c45_design_system/design_system.dart';
import 'package:erp/core/errors/app_exception.dart';
import 'package:erp/features/inventory/data/core/inventory_rpc.dart';
import 'package:erp/features/inventory/data/hub/warehouse_hub_repository.dart';
import 'package:erp/features/inventory/data/hub/warehouse_hub_summary.dart';
import 'package:erp/features/inventory/logic/hub/warehouse_hub_cubit.dart';
import 'package:erp/features/inventory/presentation/hub/warehouse_area_page.dart';
import 'package:erp/features/inventory/presentation/hub/warehouse_entries.dart';
import 'package:erp/features/inventory/presentation/hub/warehouse_hub_page.dart';
import '../../support/inventory_test_surface.dart';

class _MockInventoryRpc extends Mock implements InventoryRpc {}

class _FakeHubRepo extends WarehouseHubRepository {
  _FakeHubRepo(this._summary) : super(rpc: _MockInventoryRpc());
  final WarehouseHubSummary _summary;

  @override
  Future<WarehouseHubSummary> getSummary() async {
    return _summary;
  }
}

class _ThrowingHubRepo extends WarehouseHubRepository {
  _ThrowingHubRepo() : super(rpc: _MockInventoryRpc());
  int calls = 0;
  bool shouldThrow = true;

  @override
  Future<WarehouseHubSummary> getSummary() async {
    calls++;
    if (shouldThrow) {
      throw const AppException(AppErrorCode.unknown);
    }
    return const WarehouseHubSummary(activated: true);
  }
}

void _expectSingleChevronPerRow(WidgetTester tester) {
  final rowFinders = find.byType(VListRow);
  expect(rowFinders, findsWidgets);

  for (final rowElement in rowFinders.evaluate()) {
    final chevrons = find.descendant(
      of: find.byElementPredicate((e) => identical(e, rowElement)),
      matching: find.byWidgetPredicate(
        (w) => w is VIcon && w.icon == VIcons.chevronRight,
      ),
    );
    expect(chevrons, findsOneWidget);
  }
}

void main() {
  Widget wrap(Widget child, {Size size = const Size(390, 844)}) {
    useInventoryTestSurface(size);
    return MaterialApp(
      theme: VTheme.lightTheme,
      home: MediaQuery(
        data: MediaQueryData(size: size),
        child: child,
      ),
    );
  }

  group('WarehouseHubPage', () {
    for (final size in const [Size(390, 844), Size(1280, 800)]) {
      testWidgets('hub_rows_single_chevron_and_management_title ${size.width.toInt()}',
          (tester) async {
        const summary = WarehouseHubSummary(activated: true);
        final cubit = WarehouseHubCubit(
          repository: _FakeHubRepo(summary),
          isOwner: () => true,
        );

        await tester.pumpWidget(wrap(WarehouseHubPage(cubit: cubit), size: size));
        await tester.pumpAndSettle();

        _expectSingleChevronPerRow(tester);
        expect(find.text('Quản lý kho'), findsOneWidget);
        expect(find.text('Thiết lập kho'), findsOneWidget);
      });
    }

    testWidgets('hub_normal_with_attention', (tester) async {
      const summary = WarehouseHubSummary(
        activated: true,
        problems: WarehouseAttention(count: 2, text: '2 hàng hỏng'),
      );
      final repo = _FakeHubRepo(summary);
      final cubit = WarehouseHubCubit(repository: repo, isOwner: () => true);

      await tester.pumpWidget(wrap(WarehouseHubPage(cubit: cubit)));
      await tester.pumpAndSettle();

      expect(find.text('Cần chú ý'), findsOneWidget);
      expect(find.text('Tồn kho cần chú ý'), findsOneWidget);
      expect(find.text('2 hàng hỏng'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
      expect(find.text('Chờ duyệt'), findsNothing);
    });

    testWidgets('hub_no_attention_hides_section', (tester) async {
      const summary = WarehouseHubSummary(activated: true);
      final repo = _FakeHubRepo(summary);
      final cubit = WarehouseHubCubit(repository: repo, isOwner: () => true);

      await tester.pumpWidget(wrap(WarehouseHubPage(cubit: cubit)));
      await tester.pumpAndSettle();

      expect(find.text('Cần chú ý'), findsNothing);
    });

    testWidgets('hub_not_activated', (tester) async {
      const summary = WarehouseHubSummary(activated: false);
      final repo = _FakeHubRepo(summary);
      final cubit = WarehouseHubCubit(repository: repo, isOwner: () => true);

      await tester.pumpWidget(wrap(WarehouseHubPage(cubit: cubit)));
      await tester.pumpAndSettle();

      expect(find.text('Kho chưa có hàng'), findsOneWidget);

      final receiveBtn = tester.widget<VButton>(
        find.widgetWithText(VButton, 'Lập phiếu nhận'),
      );
      expect(receiveBtn.onPressed, isNotNull);

      // Q-b19: Nút nhanh vẫn bật khi kho trống (chưa kích hoạt)
      final quickReceive = tester.widget<VQuickActionButton>(
        find.widgetWithText(VQuickActionButton, 'Nhận hàng'),
      );
      expect(quickReceive.onPressed, isNotNull);

      final quickCheck = tester.widget<VQuickActionButton>(
        find.widgetWithText(VQuickActionButton, 'Kiểm kê'),
      );
      expect(quickCheck.onPressed, isNotNull);

      final quickSearch = tester.widget<VQuickActionButton>(
        find.widgetWithText(VQuickActionButton, 'Tra cứu tồn'),
      );
      expect(quickSearch.onPressed, isNotNull);

      expect(find.text('Khởi tạo tồn kho'), findsNothing);
    });

    testWidgets('hub_not_activated_problems_hidden', (tester) async {
      const summary = WarehouseHubSummary(
        activated: false,
        problems: WarehouseAttention(count: 3, text: 'Hỏng'),
      );
      final repo = _FakeHubRepo(summary);
      final cubit = WarehouseHubCubit(repository: repo, isOwner: () => true);

      await tester.pumpWidget(wrap(WarehouseHubPage(cubit: cubit)));
      await tester.pumpAndSettle();

      expect(find.text('Tồn kho cần chú ý'), findsNothing);
    });

    testWidgets('hub_non_owner_hides_owner_rows', (tester) async {
      const summary = WarehouseHubSummary(activated: true);
      final repo = _FakeHubRepo(summary);
      final cubit = WarehouseHubCubit(repository: repo, isOwner: () => false);

      await tester.pumpWidget(wrap(WarehouseHubPage(cubit: cubit)));
      await tester.pumpAndSettle();

      expect(find.text('Giá trị kho'), findsNothing);
    });

    testWidgets('hub_shows_all_quick_actions_and_search', (tester) async {
      const summary = WarehouseHubSummary(activated: true);
      final repo = _FakeHubRepo(summary);
      final cubit = WarehouseHubCubit(repository: repo, isOwner: () => true);

      await tester.pumpWidget(wrap(WarehouseHubPage(cubit: cubit)));
      await tester.pumpAndSettle();

      expect(find.text('Nhận hàng'), findsOneWidget);
      expect(find.text('Kiểm kê'), findsOneWidget);
      expect(find.text('Tra cứu tồn'), findsOneWidget);
      expect(find.text('Lấy hàng'), findsNothing);
      expect(find.byType(VSearchBar), findsOneWidget);
    });

    testWidgets('hub_web_two_columns', (tester) async {
      const summary = WarehouseHubSummary(
        activated: true,
        problems: WarehouseAttention(count: 1, text: 'Cần kiểm kê'),
      );
      final repo = _FakeHubRepo(summary);
      final cubit = WarehouseHubCubit(repository: repo, isOwner: () => true);

      await tester.pumpWidget(
        wrap(
          WarehouseHubPage(cubit: cubit),
          size: const Size(1280, 800),
        ),
      );
      await tester.pumpAndSettle();

      final attentionDy = tester.getTopLeft(find.text('Cần chú ý')).dy;
      final managementDy = tester.getTopLeft(find.text('Quản lý kho')).dy;
      final attentionDx = tester.getTopLeft(find.text('Cần chú ý')).dx;
      final managementDx = tester.getTopLeft(find.text('Quản lý kho')).dx;

      // Cùng hàng dọc (dy xấp xỉ), cột khác nhau (dx khác)
      expect((attentionDy - managementDy).abs(), lessThan(5.0));
      expect(attentionDx, lessThan(managementDx));
    });

    testWidgets('hub_web_no_back_button / hub_iphone_back_button', (tester) async {
      const summary = WarehouseHubSummary(activated: true);
      final repo = _FakeHubRepo(summary);

      // Web
      final cubitWeb = WarehouseHubCubit(repository: repo, isOwner: () => true);
      await tester.pumpWidget(
        wrap(WarehouseHubPage(cubit: cubitWeb), size: const Size(1280, 800)),
      );
      await tester.pumpAndSettle();
      expect(find.byTooltip('Quay lại'), findsNothing);

      // iPhone
      final cubitPhone = WarehouseHubCubit(repository: repo, isOwner: () => true);
      await tester.pumpWidget(
        wrap(WarehouseHubPage(cubit: cubitPhone), size: const Size(390, 844)),
      );
      await tester.pumpAndSettle();
      expect(find.byTooltip('Quay lại'), findsOneWidget);
    });

    testWidgets('hub_error_retry', (tester) async {
      final repo = _ThrowingHubRepo();
      final cubit = WarehouseHubCubit(repository: repo, isOwner: () => true);

      await tester.pumpWidget(wrap(WarehouseHubPage(cubit: cubit)));
      await tester.pumpAndSettle();

      expect(find.text('Chưa tải được Kho'), findsOneWidget);
      expect(find.text('Thử lại'), findsOneWidget);

      repo.shouldThrow = false;
      await tester.tap(find.text('Thử lại'));
      await tester.pumpAndSettle();

      expect(repo.calls, 2);
      expect(find.text('Chưa tải được Kho'), findsNothing);
    });
  });

  group('WarehouseAreaPage', () {
    for (final size in const [Size(390, 844), Size(1280, 800)]) {
      testWidgets('area_rows_single_chevron ${size.width.toInt()}', (tester) async {
        await tester.pumpWidget(
          wrap(
            const WarehouseAreaPage(area: WarehouseArea.valuation, isOwner: true),
            size: size,
          ),
        );
        await tester.pumpAndSettle();

        _expectSingleChevronPerRow(tester);
      });
    }

    testWidgets('area_lists_entries_with_route', (tester) async {
      await tester.pumpWidget(
        wrap(const WarehouseAreaPage(area: WarehouseArea.movement, isOwner: true)),
      );
      await tester.pumpAndSettle();

      expect(find.text('Nhận hàng'), findsOneWidget);
    });

    testWidgets('hub_history_entries owner sees 3 report entries', (tester) async {
      await tester.pumpWidget(
        wrap(const WarehouseAreaPage(area: WarehouseArea.history, isOwner: true)),
      );
      await tester.pumpAndSettle();

      expect(find.byType(VListRow), findsNWidgets(3));
      expect(find.text('Báo cáo tồn & thẻ kho'), findsOneWidget);
      expect(find.text('Lãi gộp'), findsOneWidget);
      expect(find.text('Doanh thu, giá vốn và lãi theo kỳ'), findsOneWidget);
      expect(find.text('Nhập hàng theo NCC'), findsOneWidget);
      expect(
        find.text('Tiền mua, hàng tặng và giá gốc theo nhà cung cấp'),
        findsOneWidget,
      );
    });

    testWidgets('hub_history_entries staff sees only stock report', (tester) async {
      await tester.pumpWidget(
        wrap(const WarehouseAreaPage(area: WarehouseArea.history, isOwner: false)),
      );
      await tester.pumpAndSettle();

      expect(find.byType(VListRow), findsOneWidget);
      expect(find.text('Báo cáo tồn & thẻ kho'), findsOneWidget);
      expect(find.text('Lãi gộp'), findsNothing);
      expect(find.text('Nhập hàng theo NCC'), findsNothing);
    });

    test('hub_history_entries routes', () {
      final routes = {
        for (final e in warehouseAreaEntries(WarehouseArea.history)) e.id: e.route,
      };
      expect(routes, {
        'stock_card_reports': '/warehouse/reports/stock',
        'gross_profit': '/warehouse/reports/gross-profit',
        'supplier_purchases': '/warehouse/reports/supplier-purchases',
      });
      expect(
        warehouseAreaEntries(WarehouseArea.history)
            .where((e) => e.ownerOnly)
            .map((e) => e.id),
        ['gross_profit', 'supplier_purchases'],
      );
    });

    test('valuation_area_has_supplier_programs', () {
      final entries = warehouseAreaEntries(WarehouseArea.valuation);
      final ids = entries.map((e) => e.id).toList();
      final spIndex = ids.indexOf('supplier_programs');
      final cogsIndex = ids.indexOf('cogs');

      expect(spIndex, isNonNegative);
      expect(cogsIndex, isNonNegative);
      expect(spIndex, lessThan(cogsIndex));

      final spEntry = entries[spIndex];
      expect(spEntry.title, 'Chương trình nhà cung cấp');
      expect(
        spEntry.subtitle,
        'Ưu đãi giảm giá, hàng tặng, chiết khấu đạt mốc',
      );
      expect(spEntry.route, '/warehouse/supplier-programs');
    });

    test('hub_entry_stocktakes routes both control entry and quick action', () {
      final controlEntries = warehouseAreaEntries(WarehouseArea.control);
      final stocktakeEntry = controlEntries.firstWhere(
        (e) => e.title == 'Kiểm kê kho',
      );
      expect(stocktakeEntry.route, '/warehouse/stocktakes');

      final quickAction = warehouseQuickActions.firstWhere(
        (a) => a.label == 'Kiểm kê',
      );
      expect(quickAction.route, '/warehouse/stocktakes');
    });

    testWidgets(
      'hub_attention_stocktakes shows open stocktakes row and opens /warehouse/stocktakes',
      (tester) async {
        const summary = WarehouseHubSummary(
          activated: true,
          openStocktakes: 2,
        );
        final cubit = WarehouseHubCubit(
          repository: _FakeHubRepo(summary),
          isOwner: () => true,
        );
        String? pushedRoute;
        final router = GoRouter(
          initialLocation: '/warehouse',
          routes: [
            GoRoute(
              path: '/warehouse',
              builder: (_, _) => WarehouseHubPage(cubit: cubit),
            ),
            GoRoute(
              path: '/warehouse/stocktakes',
              builder: (_, _) {
                pushedRoute = '/warehouse/stocktakes';
                return const Scaffold(body: Text('Danh sách kiểm kê'));
              },
            ),
          ],
        );

        await tester.pumpWidget(
          MaterialApp.router(
            theme: VTheme.lightTheme,
            routerConfig: router,
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Kiểm kê đang dở'), findsOneWidget);
        expect(find.text('2 phiên chưa ghi nhận'), findsOneWidget);
        expect(find.text('2'), findsOneWidget);

        await tester.tap(find.text('Kiểm kê đang dở'));
        await tester.pumpAndSettle();

        expect(pushedRoute, '/warehouse/stocktakes');
        expect(find.text('Danh sách kiểm kê'), findsOneWidget);

        final zeroCubit = WarehouseHubCubit(
          repository: _FakeHubRepo(const WarehouseHubSummary(activated: true)),
          isOwner: () => true,
        );
        await tester.pumpWidget(wrap(WarehouseHubPage(cubit: zeroCubit)));
        await tester.pumpAndSettle();
        expect(find.text('Kiểm kê đang dở'), findsNothing);
      },
    );

    testWidgets(
      'hub_attention_programs_reached owner shows row and opens /warehouse/supplier-programs?status=REACHED',
      (tester) async {
        const summary = WarehouseHubSummary(
          activated: true,
          programsReached: 2,
        );
        final ownerCubit = WarehouseHubCubit(
          repository: _FakeHubRepo(summary),
          isOwner: () => true,
        );
        String? pushedUri;
        final router = GoRouter(
          initialLocation: '/warehouse',
          routes: [
            GoRoute(
              path: '/warehouse',
              builder: (_, _) => WarehouseHubPage(cubit: ownerCubit),
            ),
            GoRoute(
              path: '/warehouse/supplier-programs',
              builder: (_, state) {
                pushedUri = state.uri.toString();
                return Scaffold(body: Text('LIST:${state.uri}'));
              },
            ),
          ],
        );

        await tester.pumpWidget(
          MaterialApp.router(
            theme: VTheme.lightTheme,
            routerConfig: router,
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Chương trình đạt mốc'), findsOneWidget);
        expect(
          find.text('2 chương trình nhà cung cấp đạt mốc chờ ghi nhận chiết khấu'),
          findsOneWidget,
        );
        expect(find.text('2'), findsOneWidget);

        await tester.tap(find.text('Chương trình đạt mốc'));
        await tester.pumpAndSettle();

        expect(pushedUri, '/warehouse/supplier-programs?status=REACHED');

        // 0 => ẩn
        final zeroCubit = WarehouseHubCubit(
          repository: _FakeHubRepo(const WarehouseHubSummary(activated: true)),
          isOwner: () => true,
        );
        await tester.pumpWidget(wrap(WarehouseHubPage(cubit: zeroCubit)));
        await tester.pumpAndSettle();
        expect(find.text('Chương trình đạt mốc'), findsNothing);

        // Nhân viên (không phải owner) => ẩn dù > 0
        final staffCubit = WarehouseHubCubit(
          repository: _FakeHubRepo(summary),
          isOwner: () => false,
        );
        await tester.pumpWidget(wrap(WarehouseHubPage(cubit: staffCubit)));
        await tester.pumpAndSettle();
        expect(find.text('Chương trình đạt mốc'), findsNothing);
      },
    );

    test('hub_cogs_entry_routes_costing sets /warehouse/costing on cogs entry',
        () {
      final entries = warehouseAreaEntries(WarehouseArea.valuation);
      final cogs = entries.firstWhere((e) => e.id == 'cogs');
      expect(cogs.route, '/warehouse/costing');
    });

    testWidgets(
      'hub_attention_cost_rows_owner_only shows period close and pending runs only for owner',
      (tester) async {
        final summary = WarehouseHubSummary(
          activated: true,
          costPeriodToClose: DateTime(2026, 10, 1),
          costRunsPending: 2,
        );
        final ownerCubit = WarehouseHubCubit(
          repository: _FakeHubRepo(summary),
          isOwner: () => true,
        );

        String? pushedUri;
        final router = GoRouter(
          initialLocation: '/warehouse',
          routes: [
            GoRoute(
              path: '/warehouse',
              builder: (_, _) => WarehouseHubPage(cubit: ownerCubit),
            ),
            GoRoute(
              path: '/warehouse/costing',
              builder: (_, state) {
                pushedUri = state.uri.toString();
                return const Scaffold(body: SizedBox.shrink());
              },
            ),
          ],
        );

        await tester.pumpWidget(
          MaterialApp.router(
            theme: VTheme.lightTheme,
            routerConfig: router,
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Kỳ 10/2026 chưa chốt giá vốn'), findsOneWidget);
        expect(find.text('Tháng đã kết thúc, cần chốt giá vốn'), findsOneWidget);
        expect(find.text('Lần tính giá vốn chờ công bố'), findsOneWidget);
        expect(find.text('2 lần tính đã tính, chờ công bố'), findsOneWidget);

        await tester.tap(find.text('Kỳ 10/2026 chưa chốt giá vốn'));
        await tester.pumpAndSettle();
        expect(pushedUri, '/warehouse/costing');

        final staffCubit = WarehouseHubCubit(
          repository: _FakeHubRepo(summary),
          isOwner: () => false,
        );
        await tester.pumpWidget(wrap(WarehouseHubPage(cubit: staffCubit)));
        await tester.pumpAndSettle();
        expect(find.text('Kỳ 10/2026 chưa chốt giá vốn'), findsNothing);
        expect(find.text('Lần tính giá vốn chờ công bố'), findsNothing);
      },
    );
  });
}
