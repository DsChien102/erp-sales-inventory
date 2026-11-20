import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:c45_design_system/design_system.dart';
import 'package:erp/core/di/injection.dart';
import 'package:erp/features/inventory/data/core/inventory_rpc.dart';
import 'package:erp/features/inventory/data/hub/warehouse_hub_repository.dart';

import '../../support/inventory_router_harness.dart';

class _InactiveInventoryRpc extends Fake implements InventoryRpc {
  @override
  Future<Map<String, dynamic>> query(
    String fn, [
    Map<String, dynamic> params = const {},
  ]) async =>
      {'activated': false, 'problems': null};
}

void main() {
  setUp(() async {
    await setUpInventoryRouterTest();
  });

  tearDown(() async {
    await tearDownInventoryRouterTest();
  });

  group('Warehouse Hub Receipt Entry Tests (Task 0)', () {
    testWidgets('quick_action_receive_opens_receipts', (tester) async {
      await pumpInventoryApp(
        tester,
        size: const Size(390, 844),
        location: '/warehouse',
      );

      final quickBtn = find.widgetWithText(VQuickActionButton, 'Nhận hàng');
      expect(quickBtn, findsOneWidget);
      await tester.tap(quickBtn);
      await tester.pumpAndSettle();

      expect(find.text('Thông tin nhận hàng'), findsOneWidget);
    });

    testWidgets('area_entry_receive_opens_receipts', (tester) async {
      await pumpInventoryApp(
        tester,
        size: const Size(390, 844),
        location: '/warehouse/area/movement',
      );

      final areaEntry = find.text('Nhận hàng');
      expect(areaEntry, findsOneWidget);
      await tester.tap(areaEntry);
      await tester.pumpAndSettle();

      expect(find.text('Phiếu nhận hàng'), findsAtLeastNWidgets(1));
    });

    testWidgets('empty_hub_banner_opens_new_receipt', (tester) async {
      getIt.unregister<WarehouseHubRepository>();
      getIt.registerSingleton<WarehouseHubRepository>(
        WarehouseHubRepository(rpc: _InactiveInventoryRpc()),
      );

      await pumpInventoryApp(
        tester,
        size: const Size(390, 844),
        location: '/warehouse',
      );

      expect(find.text('Kho chưa có hàng'), findsOneWidget);
      final bannerBtn = find.widgetWithText(VButton, 'Lập phiếu nhận');
      expect(bannerBtn, findsOneWidget);
      await tester.tap(bannerBtn);
      await tester.pumpAndSettle();

      expect(find.text('Phiếu nhận hàng'), findsOneWidget);
    });
  });
}
