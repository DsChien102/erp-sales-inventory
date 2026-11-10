import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:erp/features/dashboard/presentation/widgets/erp_bottom_navigation.dart';
import 'package:erp/features/inventory/presentation/stock_policy/stock_policy_page.dart';
import 'package:erp/features/inventory/presentation/stock_policy/stock_threshold_single_page.dart';

import '../../support/inventory_router_harness.dart';

void main() {
  setUp(() async {
    await setUpInventoryRouterTest();
  });

  tearDown(() async {
    await tearDownInventoryRouterTest();
  });

  group('StockPolicyRoutes', () {
    testWidgets('route_opens_stock_policy_page', (tester) async {
      await pumpInventoryApp(
        tester,
        location: '/warehouse/stock-policy',
      );
      await tester.pumpAndSettle();

      expect(find.byType(StockPolicyPage), findsOneWidget);
      expect(find.text('Chính sách tồn & cận hạn'), findsOneWidget);
      expect(find.text('Ngưỡng tồn'), findsOneWidget);
    });

    testWidgets('route_has_no_bottom_tabs_390', (tester) async {
      await pumpInventoryApp(
        tester,
        size: const Size(390, 844),
        location: '/warehouse/stock-policy',
      );
      await tester.pumpAndSettle();

      expect(find.byType(StockPolicyPage), findsOneWidget);
      expect(find.byType(ErpBottomNavigation), findsNothing);
    });

    testWidgets('route_with_expiry_tab_opens_expiry_tab', (tester) async {
      await pumpInventoryApp(
        tester,
        location: '/warehouse/stock-policy?tab=expiry',
      );
      await tester.pumpAndSettle();

      expect(find.byType(StockPolicyPage), findsOneWidget);
      expect(find.text('Số ngày cận hạn'), findsOneWidget);
    });

    testWidgets('route_opens_product_single_page', (tester) async {
      await pumpInventoryApp(
        tester,
        location: '/warehouse/stock-policy/product/p_nobivac',
      );
      await tester.pumpAndSettle();

      expect(find.byType(StockThresholdSinglePage), findsOneWidget);
      final singlePage = tester.widget<StockThresholdSinglePage>(
        find.byType(StockThresholdSinglePage),
      );
      expect(singlePage.productId, 'p_nobivac');
      expect(find.text('Nobivac DHPPi'), findsOneWidget);
    });

    testWidgets('setup_area_lists_stock_policy_and_navigates', (tester) async {
      await pumpInventoryApp(
        tester,
        location: '/warehouse/area/setup',
      );
      await tester.pumpAndSettle();

      expect(find.text('Thiết lập kho'), findsOneWidget);
      expect(find.text('Chính sách tồn & cận hạn'), findsOneWidget);

      await tester.tap(find.text('Chính sách tồn & cận hạn'));
      await tester.pumpAndSettle();

      expect(find.byType(StockPolicyPage), findsOneWidget);
    });
  });
}

