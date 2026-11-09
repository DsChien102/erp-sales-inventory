import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vet45_design_system/design_system.dart';
import 'package:erp/core/errors/app_exception.dart';
import 'package:erp/features/inventory/data/hub/warehouse_hub_repository.dart';
import 'package:erp/features/inventory/data/hub/warehouse_hub_summary.dart';
import 'package:erp/features/inventory/logic/hub/warehouse_hub_cubit.dart';
import 'package:erp/features/inventory/presentation/hub/warehouse_entries.dart';
import 'package:erp/features/inventory/presentation/hub/warehouse_hub_page.dart';
import 'package:erp/features/inventory/presentation/hub/warehouse_area_page.dart';
import 'package:erp/features/inventory/presentation/hub/warehouse_pending_approvals_page.dart';
import '../../support/inventory_test_surface.dart';

class _FakeHubRepo extends WarehouseHubRepository {
  _FakeHubRepo(this._summary);
  final WarehouseHubSummary _summary;
  int calls = 0;

  @override
  Future<WarehouseHubSummary> getSummary() async {
    calls++;
    return _summary;
  }
}

class _ThrowingHubRepo extends WarehouseHubRepository {
  int calls = 0;
  bool shouldThrow = true;

  @override
  Future<WarehouseHubSummary> getSummary() async {
    calls++;
    if (shouldThrow) {
      throw const AppException(AppErrorCode.network);
    }
    return const WarehouseHubSummary(activated: true);
  }
}

/// Mỗi `VListRow` có đúng một mũi tên › (R1-1).
void _expectSingleChevronPerRow(WidgetTester tester) {
  final rows = find.byType(VListRow);
  expect(rows, findsWidgets);
  for (final row in rows.evaluate()) {
    final chevrons = find.descendant(
      of: find.byWidget(row.widget),
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
      testWidgets('hub_rows_single_chevron_and_setup_title_once ${size.width.toInt()}',
          (tester) async {
        const summary = WarehouseHubSummary(
          activated: true,
          pending: [
            WarehousePendingGroup(
              sourceId: 'receipts',
              label: 'nhận hàng',
              items: [
                WarehousePendingItem(
                  title: 'PN-01',
                  subtitle: 'NCC A',
                  icon: VIcons.cloudUpload,
                  route: '/r/1',
                ),
              ],
            ),
          ],
        );
        final cubit = WarehouseHubCubit(
          repository: _FakeHubRepo(summary),
          isOwner: () => true,
        );

        await tester.pumpWidget(wrap(WarehouseHubPage(cubit: cubit), size: size));
        await tester.pumpAndSettle();

        _expectSingleChevronPerRow(tester);
        expect(find.text('Thiết lập kho'), findsOneWidget);
      });
    }

    testWidgets('hub_normal_with_attention', (tester) async {
      const summary = WarehouseHubSummary(
        activated: true,
        pending: [
          WarehousePendingGroup(
            sourceId: 'receipts',
            label: 'nhận hàng',
            items: [
              WarehousePendingItem(
                title: 'PN-01',
                subtitle: 'NCC A',
                icon: VIcons.cloudUpload,
                route: '/r/1',
              ),
              WarehousePendingItem(
                title: 'PN-02',
                subtitle: 'NCC B',
                icon: VIcons.cloudUpload,
                route: '/r/2',
              ),
            ],
          ),
        ],
      );
      final repo = _FakeHubRepo(summary);
      final cubit = WarehouseHubCubit(repository: repo, isOwner: () => true);

      await tester.pumpWidget(wrap(WarehouseHubPage(cubit: cubit)));
      await tester.pumpAndSettle();

      expect(find.text('Cần chú ý'), findsOneWidget);
      expect(find.text('Chờ duyệt'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
      expect(find.text('Hàng cần xử lý'), findsNothing);
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

      expect(find.text('Kho chưa kích hoạt'), findsOneWidget);

      final receiveBtn = tester.widget<VQuickActionButton>(
        find.widgetWithText(VQuickActionButton, 'Nhận hàng'),
      );
      expect(receiveBtn.onPressed, isNull);

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

    testWidgets('hub_hides_entries_without_route', (tester) async {
      const summary = WarehouseHubSummary(activated: true);
      final repo = _FakeHubRepo(summary);
      final cubit = WarehouseHubCubit(repository: repo, isOwner: () => true);

      await tester.pumpWidget(wrap(WarehouseHubPage(cubit: cubit)));
      await tester.pumpAndSettle();

      expect(find.text('Lấy hàng'), findsNothing);
      expect(find.text('Kiểm kê'), findsNothing);
      expect(find.text('Tra cứu tồn'), findsNothing);
      expect(find.byType(VSearchBar), findsNothing);
    });

    testWidgets('hub_web_two_columns', (tester) async {
      const summary = WarehouseHubSummary(
        activated: true,
        pending: [
          WarehousePendingGroup(
            sourceId: 'receipts',
            label: 'nhận hàng',
            items: [
              WarehousePendingItem(
                title: 'PN-01',
                subtitle: 'NCC A',
                icon: VIcons.cloudUpload,
                route: '/r/1',
              ),
            ],
          ),
        ],
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
      expect(find.text('Lấy & bàn giao'), findsNothing);
    });

    testWidgets('area_hides_entries_without_route', (tester) async {
      await tester.pumpWidget(
        wrap(const WarehouseAreaPage(area: WarehouseArea.history, isOwner: true)),
      );
      await tester.pumpAndSettle();

      expect(find.byType(VListRow), findsNothing);
    });
  });

  group('WarehousePendingApprovalsPage', () {
    testWidgets('pending_list_rows_and_badge', (tester) async {
      const summary = WarehouseHubSummary(
        activated: true,
        pending: [
          WarehousePendingGroup(
            sourceId: 'receipts',
            label: 'nhận hàng',
            items: [
              WarehousePendingItem(
                title: 'PN-01',
                subtitle: 'NCC A',
                icon: VIcons.cloudUpload,
                route: '/r/1',
              ),
              WarehousePendingItem(
                title: 'PN-02',
                subtitle: 'NCC B',
                icon: VIcons.cloudUpload,
                route: '/r/2',
              ),
            ],
          ),
        ],
      );
      final repo = _FakeHubRepo(summary);
      final cubit = WarehouseHubCubit(repository: repo, isOwner: () => true);

      await tester.pumpWidget(
        wrap(WarehousePendingApprovalsPage(cubit: cubit)),
      );
      await tester.pumpAndSettle();

      expect(find.text('Đang chờ xử lý'), findsOneWidget);
      expect(find.byType(VListRow), findsNWidgets(2));
      expect(find.widgetWithText(VBadge, 'Chờ duyệt'), findsNWidgets(2));
    });
  });
}
