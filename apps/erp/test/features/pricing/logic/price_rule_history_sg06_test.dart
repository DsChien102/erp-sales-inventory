import 'package:erp/features/pricing/data/models.dart';
import 'package:erp/features/pricing/presentation.dart';
import 'package:erp/features/pricing/presentation/widgets/price_rule_history_timeline_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:c45_design_system/design_system.dart';

import '../support/fake_customer_price_rule_repository.dart';
import '../support/fake_pricing_backend.dart';

void main() {
  final testActivity = CustomerPriceRuleActivityDto(
    id: 'act-001',
    activityType: CustomerPriceRuleActivityType.updated,
    actor: const CustomerPriceRuleActivityActorDto(
      actorId: 'user-01',
      displayName: 'Nguyễn Văn A',
      isSystemActor: false,
    ),
    sourceType: CustomerPriceRuleSourceType.manual,
    sourceTrace: const CustomerPriceRuleActivitySourceTraceDto(),
    oldValue: const {
      'rule_price_minor': 95000,
      'effective_from': '2024-03-01T00:00:00Z',
      'effective_to': null,
      'floor_price_diff_minor': 5000,
    },
    newValue: const {
      'rule_price_minor': 100200,
      'effective_from': '2024-03-01T00:00:00Z',
      'effective_to': '2026-12-31T00:00:00Z',
      'floor_price_diff_minor': 10200,
    },
    reason: 'Điều chỉnh theo chính sách bán hàng tháng 7.',
    sensitiveValuesHidden: false,
    createdAt: DateTime.parse('2026-07-06T09:41:00Z'),
  );

  final testOrderActivity = CustomerPriceRuleActivityDto(
    id: 'act-002',
    activityType: CustomerPriceRuleActivityType.memoryCreated,
    actor: const CustomerPriceRuleActivityActorDto(
      actorId: 'system',
      displayName: 'Hệ thống',
      isSystemActor: true,
    ),
    sourceType: CustomerPriceRuleSourceType.salesOrder,
    sourceTrace: const CustomerPriceRuleActivitySourceTraceDto(
      orderId: 'HD-2026-002381',
    ),
    oldValue: null,
    newValue: const {'rule_price_minor': 190000},
    reason: null,
    sensitiveValuesHidden: false,
    createdAt: DateTime.parse('2026-07-05T16:20:00Z'),
  );

  testWidgets(
    'SG-06 D-02: PriceRuleHistoryView renders timeline & quick filter',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PriceRuleHistoryView(
              items: [testActivity, testOrderActivity],
              hasMore: false,
              onLoadMore: () {},
              customerName: 'Mai Phương Retail',
              productUnitName: 'ANK-500mg · Hộp',
            ),
          ),
        ),
      );

      expect(find.text('Mai Phương Retail'), findsOneWidget);
      expect(find.text('ANK-500mg · Hộp'), findsOneWidget);
      expect(find.text('Sửa giá'), findsAtLeast(2));
      expect(find.text('Nguyễn Văn A · Tạo thủ công'), findsOneWidget);
    },
  );

  testWidgets(
    'SG-06 D-03: PriceRuleHistoryFilterSheet selects and resets options',
    (tester) async {
      PriceRuleHistoryFilterState? appliedFilter;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PriceRuleHistoryFilterSheet(
              initialFilter: const PriceRuleHistoryFilterState(),
              onApply: (f) => appliedFilter = f,
              actorOptions: const ['Tất cả', 'Nguyễn Văn A'],
            ),
          ),
        ),
      );

      expect(find.text('Bộ lọc lịch sử'), findsOneWidget);
      expect(find.text('Loại hoạt động'), findsOneWidget);
      expect(find.text('Sửa giá'), findsOneWidget);

      await tester.tap(find.text('Sửa giá'));
      await tester.pump();

      await tester.tap(find.text('Áp dụng'));
      await tester.pump();

      expect(appliedFilter, isNotNull);
      expect(appliedFilter!.activityType, 'Sửa giá');
    },
  );

  testWidgets(
    'SG-06 D-05 & D-07: PriceRuleActivityDetailSheet shows diff table and masked data',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PriceRuleActivityDetailSheet(
              activity: testActivity,
              hasSensitivePermission: false,
            ),
          ),
        ),
      );

      expect(
        find.text('Bạn không có quyền xem một số dữ liệu nhạy cảm.'),
        findsOneWidget,
      );
      expect(find.text('So sánh trước / sau'), findsOneWidget);
      expect(find.text('95.000đ'), findsOneWidget);
      expect(find.text('100.200đ'), findsOneWidget);
      expect(find.text('Ẩn theo quyền 🔒'), findsNWidgets(2));
      expect(
        find.text('Điều chỉnh theo chính sách bán hàng tháng 7.'),
        findsOneWidget,
      );
    },
  );

  testWidgets('SG-06 D-08: System states render no permission state', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PriceRuleHistoryView(
            items: const [],
            hasMore: false,
            onLoadMore: () {},
            hasPermission: false,
          ),
        ),
      ),
    );

    expect(
      find.text('Bạn không có quyền xem lịch sử giá riêng'),
      findsOneWidget,
    );
    expect(
      find.text('Vui lòng liên hệ quản trị viên để được cấp quyền.'),
      findsOneWidget,
    );
    expect(find.text('Quay lại'), findsOneWidget);
  });

  test('history_error_message_by_code', () async {
    final noPermissionCubit = PriceRuleHistoryCubit(
      ruleId: 'fake-rule-1',
      repository: FakeCustomerPriceRuleRepository(
        historyScenario: FakePricingScenario.historyDenied,
      ),
    );
    await noPermissionCubit.fetchHistory();
    expect(noPermissionCubit.state, isA<PriceRuleHistoryNoPermission>());
    await noPermissionCubit.close();

    final notFoundCubit = PriceRuleHistoryCubit(
      ruleId: 'fake-rule-1',
      repository: FakeCustomerPriceRuleRepository(
        historyScenario: FakePricingScenario.historyNotFound,
      ),
    );
    await notFoundCubit.fetchHistory();
    expect(
      notFoundCubit.state,
      isA<PriceRuleHistoryError>().having(
        (s) => s.message,
        'message',
        'Không tìm thấy giá riêng này.',
      ),
    );
    await notFoundCubit.close();

    final systemErrorCubit = PriceRuleHistoryCubit(
      ruleId: 'fake-rule-1',
      repository: FakeCustomerPriceRuleRepository(
        historyScenario: FakePricingScenario.historySystemError,
      ),
    );
    await systemErrorCubit.fetchHistory();
    expect(
      systemErrorCubit.state,
      isA<PriceRuleHistoryError>().having(
        (s) => s.message,
        'message',
        'Đã xảy ra lỗi. Vui lòng thử lại.',
      ),
    );
    await systemErrorCubit.close();
  });

  test('history_loaded_keeps_sensitive_permission', () async {
    final cubit = PriceRuleHistoryCubit(
      ruleId: 'fake-rule-1',
      repository: FakeCustomerPriceRuleRepository(),
    );
    await cubit.fetchHistory();
    expect(cubit.state, isA<PriceRuleHistoryLoaded>());
    expect(cubit.state.hasSensitivePermission, isTrue);
    await cubit.close();
  });

  test('history_no_permission_stops_paging', () async {
    final repo = FakeCustomerPriceRuleRepository(
      historyScenario: FakePricingScenario.historyDenied,
    );
    final cubit = PriceRuleHistoryCubit(
      ruleId: 'fake-rule-1',
      repository: repo,
    );
    await cubit.fetchHistory();
    expect(cubit.state, isA<PriceRuleHistoryNoPermission>());
    final callsAfterFirst =
        repo.calls.where((c) => c.method == 'getHistory').length;
    expect(callsAfterFirst, 1);

    await cubit.fetchHistory();
    expect(
      repo.calls.where((c) => c.method == 'getHistory').length,
      callsAfterFirst,
    );
    await cubit.close();
  });

  group('B2 — history filter and search behavioral preservation', () {
    final now = DateTime.now();
    final items = [
      CustomerPriceRuleActivityDto(
        id: 'act-1',
        activityType: CustomerPriceRuleActivityType.created,
        actor: const CustomerPriceRuleActivityActorDto(
          actorId: 'user-lan',
          displayName: 'Lan',
          isSystemActor: false,
        ),
        sourceType: CustomerPriceRuleSourceType.manual,
        sourceTrace: const CustomerPriceRuleActivitySourceTraceDto(),
        oldValue: null,
        newValue: const {},
        reason: null,
        sensitiveValuesHidden: false,
        createdAt: now,
      ),
      CustomerPriceRuleActivityDto(
        id: 'act-2',
        activityType: CustomerPriceRuleActivityType.updated,
        actor: const CustomerPriceRuleActivityActorDto(
          actorId: 'user-minh',
          displayName: 'Minh',
          isSystemActor: false,
        ),
        sourceType: CustomerPriceRuleSourceType.manual,
        sourceTrace: const CustomerPriceRuleActivitySourceTraceDto(),
        oldValue: null,
        newValue: const {},
        reason: null,
        sensitiveValuesHidden: false,
        createdAt: now,
      ),
      CustomerPriceRuleActivityDto(
        id: 'act-3',
        activityType: CustomerPriceRuleActivityType.disabled,
        actor: const CustomerPriceRuleActivityActorDto(
          actorId: 'user-lan',
          displayName: 'Lan',
          isSystemActor: false,
        ),
        sourceType: CustomerPriceRuleSourceType.manual,
        sourceTrace: const CustomerPriceRuleActivitySourceTraceDto(),
        oldValue: null,
        newValue: const {},
        reason: null,
        sensitiveValuesHidden: false,
        createdAt: now.subtract(const Duration(days: 20)),
      ),
      CustomerPriceRuleActivityDto(
        id: 'act-4',
        activityType: CustomerPriceRuleActivityType.reenabled,
        actor: const CustomerPriceRuleActivityActorDto(
          actorId: 'user-minh',
          displayName: 'Minh',
          isSystemActor: false,
        ),
        sourceType: CustomerPriceRuleSourceType.manual,
        sourceTrace: const CustomerPriceRuleActivitySourceTraceDto(),
        oldValue: null,
        newValue: const {},
        reason: null,
        sensitiveValuesHidden: false,
        createdAt: now,
      ),
    ];

    Future<void> pumpHistoryView(WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: VTheme.lightTheme,
          home: Scaffold(
            body: PriceRuleHistoryView(
              items: items,
              hasMore: false,
              onLoadMore: () {},
              customerName: 'Khách A',
              productUnitName: 'Sản phẩm A',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('b2_filter_type_disabled', (tester) async {
      await pumpHistoryView(tester);
      expect(find.byType(PriceRuleHistoryTimelineTile), findsNWidgets(4));

      await tester.tap(find.bySemanticsLabel('Lọc lịch sử thay đổi'));
      await tester.pumpAndSettle();

      await tester.tap(
        find.descendant(
          of: find.byType(PriceRuleHistoryFilterSheet),
          matching: find.text('Tắt'),
        ),
      );
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        find.text('Áp dụng'),
        50,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.tap(find.text('Áp dụng'));
      await tester.pumpAndSettle();

      expect(find.byType(PriceRuleHistoryTimelineTile), findsNWidgets(1));
    });

    testWidgets('b2_filter_actor', (tester) async {
      await pumpHistoryView(tester);
      await tester.tap(find.bySemanticsLabel('Lọc lịch sử thay đổi'));
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        find.text('Lan'),
        50,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.tap(find.text('Lan'));
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        find.text('Áp dụng'),
        50,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.tap(find.text('Áp dụng'));
      await tester.pumpAndSettle();

      expect(find.byType(PriceRuleHistoryTimelineTile), findsNWidgets(2));
    });

    testWidgets('b2_filter_7_days', (tester) async {
      await pumpHistoryView(tester);
      await tester.tap(find.bySemanticsLabel('Lọc lịch sử thay đổi'));
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        find.text('7 ngày gần đây'),
        50,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.tap(find.text('7 ngày gần đây'));
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        find.text('Áp dụng'),
        50,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.tap(find.text('Áp dụng'));
      await tester.pumpAndSettle();

      expect(find.byType(PriceRuleHistoryTimelineTile), findsNWidgets(3));
    });

    testWidgets('b2_search_actor', (tester) async {
      await pumpHistoryView(tester);
      await tester.enterText(find.byType(TextField), 'minh');
      await tester.pumpAndSettle();

      expect(find.byType(PriceRuleHistoryTimelineTile), findsNWidgets(2));
    });

    testWidgets('b2_quick_price_edit', (tester) async {
      await pumpHistoryView(tester);
      await tester.tap(find.widgetWithText(VChip, 'Sửa giá'));
      await tester.pumpAndSettle();

      expect(find.byType(PriceRuleHistoryTimelineTile), findsNWidgets(2));
    });
  });

  group('H7 — history without source / orders', () {
    testWidgets('h7_history_filter_sheet_options', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: VTheme.lightTheme,
          home: Scaffold(
            body: PriceRuleHistoryFilterSheet(
              initialFilter: const PriceRuleHistoryFilterState(),
              onApply: (_) {},
              actorOptions: const ['Tất cả', 'Lan Nguyễn'],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Nhập Excel'), findsNothing);
      expect(find.text('Từ đơn hàng'), findsNothing);
      expect(find.text('Migration'), findsNothing);
      expect(find.text('Tùy chọn'), findsNothing);
      expect(find.text('Nguồn'), findsNothing);
      expect(find.text('Nguyễn Văn A'), findsNothing);
      expect(find.text('Quản trị viên'), findsNothing);

      expect(find.text('Tạo giá riêng'), findsOneWidget);
      expect(find.text('Sửa giá'), findsOneWidget);
      expect(find.text('Tắt'), findsOneWidget);
      expect(find.text('Bật lại'), findsOneWidget);
      expect(find.text('Lan Nguyễn'), findsOneWidget);
      expect(find.text('7 ngày gần đây'), findsOneWidget);
    });

    testWidgets('h7_history_quick_chips', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: VTheme.lightTheme,
          home: Scaffold(
            body: PriceRuleHistoryView(
              items: const [],
              hasMore: false,
              onLoadMore: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.widgetWithText(VChip, 'Tất cả'), findsOneWidget);
      expect(find.widgetWithText(VChip, 'Sửa giá'), findsOneWidget);
      expect(find.widgetWithText(VChip, 'Từ đơn hàng'), findsNothing);
      expect(find.widgetWithText(VChip, 'Nhập Excel'), findsNothing);
    });

    testWidgets('h7_no_source_order_block', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: VTheme.lightTheme,
          home: Scaffold(
            body: PriceRuleActivityDetailSheet(
              activity: testOrderActivity,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Chứng từ nguồn'), findsNothing);
      expect(find.textContaining('Đơn hàng'), findsNothing);
      expect(find.text('Xem chứng từ'), findsNothing);
    });

    testWidgets('t93_history_actor_options_from_data', (tester) async {
      final now = DateTime.now();
      final items = [
        CustomerPriceRuleActivityDto(
          id: 'act-lan',
          activityType: CustomerPriceRuleActivityType.created,
          actor: const CustomerPriceRuleActivityActorDto(
            actorId: 'user-lan',
            displayName: 'Lan',
            isSystemActor: false,
          ),
          sourceType: CustomerPriceRuleSourceType.manual,
          sourceTrace: const CustomerPriceRuleActivitySourceTraceDto(),
          oldValue: null,
          newValue: const {},
          reason: null,
          sensitiveValuesHidden: false,
          createdAt: now,
        ),
        CustomerPriceRuleActivityDto(
          id: 'act-minh',
          activityType: CustomerPriceRuleActivityType.updated,
          actor: const CustomerPriceRuleActivityActorDto(
            actorId: 'user-minh',
            displayName: 'Minh',
            isSystemActor: false,
          ),
          sourceType: CustomerPriceRuleSourceType.manual,
          sourceTrace: const CustomerPriceRuleActivitySourceTraceDto(),
          oldValue: null,
          newValue: const {},
          reason: null,
          sensitiveValuesHidden: false,
          createdAt: now,
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          theme: VTheme.lightTheme,
          home: Scaffold(
            body: PriceRuleHistoryView(
              items: items,
              hasMore: false,
              onLoadMore: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.bySemanticsLabel('Lọc lịch sử thay đổi'));
      await tester.pumpAndSettle();

      expect(find.byType(PriceRuleHistoryFilterSheet), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(PriceRuleHistoryFilterSheet),
          matching: find.text('Tất cả'),
        ),
        findsWidgets,
      );
      expect(
        find.descendant(
          of: find.byType(PriceRuleHistoryFilterSheet),
          matching: find.text('Lan'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byType(PriceRuleHistoryFilterSheet),
          matching: find.text('Minh'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byType(PriceRuleHistoryFilterSheet),
          matching: find.text('Nguyễn Văn A'),
        ),
        findsNothing,
      );
    });
  });
}
