import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vet45_design_system/design_system.dart';
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
        expect(find.text('Thiết lập kho'), findsNothing);
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
      expect(find.text('Hàng cần xử lý'), findsOneWidget);
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

      expect(find.text('Hàng cần xử lý'), findsNothing);
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

    testWidgets('area_hides_entries_without_route', (tester) async {
      await tester.pumpWidget(
        wrap(const WarehouseAreaPage(area: WarehouseArea.history, isOwner: true)),
      );
      await tester.pumpAndSettle();

      expect(find.byType(VListRow), findsNothing);
    });
  });
}
