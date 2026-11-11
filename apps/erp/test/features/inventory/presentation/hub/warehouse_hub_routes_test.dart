import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:erp/features/dashboard/presentation/widgets/erp_bottom_navigation.dart';
import 'package:erp/features/dashboard/presentation/widgets/erp_side_navigation.dart';

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
  });
}
