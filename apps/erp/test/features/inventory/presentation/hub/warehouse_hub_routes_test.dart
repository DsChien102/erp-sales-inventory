import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vet45_design_system/design_system.dart';
import 'package:erp/features/dashboard/presentation/widgets/erp_bottom_navigation.dart';
import 'package:erp/features/dashboard/presentation/widgets/erp_side_navigation.dart';
import 'package:erp/features/inventory/presentation/pages/receipt_entry_choice_page.dart';
import 'package:erp/features/inventory/presentation/pages/valuation_queue_page.dart';

import '../../support/inventory_router_harness.dart';

void main() {
  setUp(() async {
    await setUpInventoryRouterTest();
  });

  tearDown(() async {
    await tearDownInventoryRouterTest();
  });

  group('Warehouse Hub Routes', () {
    testWidgets('hub_iphone_has_bottom_navigation', (tester) async {
      await pumpInventoryApp(
        tester,
        size: const Size(390, 844),
        location: '/warehouse',
      );

      expect(find.byType(ErpBottomNavigation), findsOneWidget);
      expect(find.text('Kho'), findsAtLeastNWidgets(1));
    });

    testWidgets('hub_web_has_sidebar', (tester) async {
      await pumpInventoryApp(
        tester,
        size: const Size(1280, 800),
        location: '/warehouse',
      );

      expect(find.byType(ErpSideNavigation), findsOneWidget);
    });

    testWidgets('area_route_opens_area', (tester) async {
      await pumpInventoryApp(
        tester,
        location: '/warehouse/area/control',
      );

      expect(find.text('Kiểm kê & xử lý'), findsOneWidget);
    });

    testWidgets('unknown_area_redirects_hub', (tester) async {
      await pumpInventoryApp(
        tester,
        location: '/warehouse/area/xyz',
      );

      expect(find.text('Kho'), findsAtLeastNWidgets(1));
      expect(find.text('Quản lý kho'), findsOneWidget);
    });

    testWidgets('valuation_area_redirects_non_owner', (tester) async {
      await pumpInventoryApp(
        tester,
        location: '/warehouse/area/valuation',
        isOwner: false,
      );

      expect(find.text('Kho'), findsAtLeastNWidgets(1));
      expect(find.text('Quản lý kho'), findsOneWidget);
      expect(find.text('Giá trị kho'), findsNothing);
    });

    testWidgets('quick_receive_opens_old_receipt_entry', (tester) async {
      await pumpInventoryApp(
        tester,
        location: '/warehouse',
      );

      await tester.tap(find.widgetWithText(VQuickActionButton, 'Nhận hàng'));
      await tester.pumpAndSettle();

      expect(find.byType(ReceiptEntryChoicePage), findsOneWidget);
    });

    testWidgets('valuation_entry_opens_old_queue', (tester) async {
      await pumpInventoryApp(
        tester,
        location: '/warehouse/area/valuation',
      );

      await tester.tap(find.text('Hàng chờ xác lập giá trị'));
      await tester.pumpAndSettle();

      expect(find.byType(ValuationQueuePage), findsOneWidget);
    });
  });
}
