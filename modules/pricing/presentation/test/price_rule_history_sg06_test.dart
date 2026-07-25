import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vet45_pricing_application/application.dart';
import 'package:vet45_pricing_domain/domain.dart';
import 'package:vet45_pricing_presentation/presentation.dart';

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
      expect(find.text('Từ đơn hàng'), findsAtLeast(2));
      expect(find.text('Đơn #HD-2026-002381'), findsOneWidget);
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

      expect(find.text('Chi tiết hoạt động'), findsOneWidget);
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

  testWidgets(
    'SG-06 D-06: PriceRuleSourceOrderDetailSheet displays source order details',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PriceRuleSourceOrderDetailSheet(
              orderId: 'HD-2026-002381',
              customerName: 'Trại Minh An',
              orderDate: '05/07/2026 16:20',
              productName: 'VAC-THI-50',
              unitName: 'Hộp',
              priceLabel: '190.000đ',
              staffName: 'Nguyễn Văn A',
            ),
          ),
        ),
      );

      expect(find.text('Chứng từ nguồn'), findsOneWidget);
      expect(find.text('Đơn hàng HD-2026-002381'), findsOneWidget);
      expect(find.text('Trại Minh An'), findsOneWidget);
      expect(find.text('VAC-THI-50'), findsOneWidget);
      expect(find.text('190.000đ'), findsOneWidget);
      expect(find.text('Xem đơn hàng nguồn'), findsOneWidget);
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
}
