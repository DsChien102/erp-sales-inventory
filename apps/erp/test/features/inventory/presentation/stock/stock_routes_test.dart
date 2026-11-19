import 'package:erp/core/di/injection.dart';
import 'package:erp/features/dashboard/presentation/widgets/erp_bottom_navigation.dart';
import 'package:erp/features/inventory/data/core/inventory_rpc.dart';
import 'package:erp/features/inventory/data/hub/warehouse_hub_repository.dart';
import 'package:erp/features/inventory/presentation/stock/stock_detail_page.dart';
import 'package:erp/features/inventory/presentation/stock/stock_list_page.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:c45_design_system/design_system.dart';

import '../../support/inventory_router_harness.dart';

class _HubRpcWithProblems extends Fake implements InventoryRpc {
  @override
  Future<Map<String, dynamic>> query(
    String fn, [
    Map<String, dynamic> params = const {},
  ]) async =>
      {
        'activated': true,
        'problems': {
          'out': 1,
          'low': 1,
          'expired': 0,
          'near_expiry': 0,
          'products': 2,
        },
      };
}

void main() {
  setUp(() async {
    await setUpInventoryRouterTest();
  });

  tearDown(() async {
    await tearDownInventoryRouterTest();
  });

  group('StockRoutes & Hub integration', () {
    testWidgets('hub_attention_row_opens_stock', (tester) async {
      if (getIt.isRegistered<WarehouseHubRepository>()) {
        getIt.unregister<WarehouseHubRepository>();
      }
      getIt.registerSingleton<WarehouseHubRepository>(
        WarehouseHubRepository(rpc: _HubRpcWithProblems()),
      );

      await pumpInventoryApp(
        tester,
        location: '/warehouse',
      );
      await tester.pumpAndSettle();

      expect(find.text('Tồn kho cần chú ý'), findsOneWidget);
      expect(find.text('1 hết hàng · 1 tồn thấp'), findsOneWidget);

      await tester.tap(find.text('Tồn kho cần chú ý'));
      await tester.pumpAndSettle();

      expect(find.byType(StockListPage), findsOneWidget);
      expect(find.byType(ErpBottomNavigation), findsNothing);
    });

    testWidgets('quick_action_tra_cuu_ton_opens_stock', (tester) async {
      await pumpInventoryApp(
        tester,
        location: '/warehouse',
      );
      await tester.pumpAndSettle();

      await tester.tap(
        find.widgetWithText(VQuickActionButton, 'Tra cứu tồn'),
      );
      await tester.pumpAndSettle();

      expect(find.byType(StockListPage), findsOneWidget);
    });

    testWidgets('route_detail_opens_product', (tester) async {
      await pumpInventoryApp(
        tester,
        location: '/warehouse/stock/INV-NOB',
      );
      await tester.pumpAndSettle();

      expect(find.byType(StockDetailPage), findsOneWidget);
      expect(find.text('Nobivac DHPPi'), findsOneWidget);
      expect(find.byType(ErpBottomNavigation), findsNothing);
    });
  });
}
