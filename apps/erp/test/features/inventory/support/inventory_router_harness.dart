import 'package:erp/core/di/injection.dart';
import 'package:erp/core/router/app_router.dart';
import 'package:erp/core/session/session_controller.dart';
import 'package:erp/core/session/session_store.dart';
import 'package:erp/features/dashboard/data/default_pair_repository.dart';
import 'package:erp/features/inventory/data/core/inventory_rpc.dart';
import 'package:erp/features/inventory/data/goods_receipt_repository.dart';
import 'package:erp/features/inventory/data/hub/warehouse_hub_repository.dart';
import 'package:erp/features/inventory/data/stock_policy/stock_policy_models.dart';
import 'package:erp/features/inventory/data/stock_policy/stock_policy_repository.dart';
import 'package:erp/features/inventory/data/valuation_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vet45_design_system/design_system.dart';
import 'package:vet45_shared_application/application.dart';
import 'package:vet45_shared_testing/shared_testing.dart';

import '../../auth/support/scripted_auth.dart';
import '../../dashboard/presentation/fake_default_pair_repository.dart';

class _FakeInventoryRpc extends Fake implements InventoryRpc {
  @override
  Future<Map<String, dynamic>> query(
    String fn, [
    Map<String, dynamic> params = const {},
  ]) async =>
      {'activated': true, 'problems': null};
}

class _FakeStockPolicyRepo extends Fake implements StockPolicyRepository {
  @override
  Future<StockPolicySnapshot> load() async => const StockPolicySnapshot(
        revision: 1,
        isOwner: true,
        nearExpiryDays: 30,
        products: [
          StockPolicyProduct(
            productId: 'p_nobivac',
            name: 'Nobivac DHPPi',
            code: 'NOBI',
            uom: 'hộp',
            isLotTracked: true,
            available: 30,
            hasExpired: false,
            hasNearExpiry: false,
            threshold: 20,
            target: 50,
          ),
        ],
      );
}

base class InventorySessionStore extends SessionStore {
  InventorySessionStore({this.isOwner = true});

  @override
  final bool isOwner;

  @override
  bool hasPermission(String code) => true;

  @override
  String? get tenantId => 'tenant-test';
}

Future<void> setUpInventoryRouterTest({bool isOwner = true}) async {
  await getIt.reset();
  final store = InventorySessionStore(isOwner: isOwner);
  final session = loginSession(store: store);
  session.applySignedInUser('user-1');
  final valuationRepo = ValuationRepository();
  getIt
    ..registerSingleton<SessionStore>(store)
    ..registerSingleton<IExecutionContext>(FakeExecutionContext(tenantId: 'tenant-test'))
    ..registerSingleton<DefaultPairRepository>(FakeDefaultPairRepository())
    ..registerSingleton<WarehouseHubRepository>(WarehouseHubRepository(rpc: _FakeInventoryRpc()))
    ..registerSingleton<StockPolicyRepository>(_FakeStockPolicyRepo())
    ..registerSingleton<ValuationRepository>(valuationRepo)
    ..registerSingleton<GoodsReceiptRepository>(GoodsReceiptRepository(valuation: valuationRepo))
    ..registerSingleton<SessionController>(session);
}

Future<void> tearDownInventoryRouterTest() async {
  try {
    appRouter.go('/');
  } catch (_) {}
  await getIt.reset();
}

Future<void> pumpInventoryApp(
  WidgetTester tester, {
  Size size = const Size(390, 844),
  String location = '/more',
  bool? isOwner,
  GlobalKey? repaintBoundaryKey,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final previousOnError = FlutterError.onError;
  FlutterError.onError = (details) {
    if (details.exceptionAsString().contains('overflowed')) return;
    previousOnError?.call(details);
  };
  addTearDown(() => FlutterError.onError = previousOnError);

  if (!getIt.isRegistered<SessionController>() || isOwner != null) {
    if (getIt.isRegistered<SessionController>()) {
      getIt.unregister<SessionController>();
    }
    if (getIt.isRegistered<SessionStore>()) {
      getIt.unregister<SessionStore>();
    }
    final store = InventorySessionStore(isOwner: isOwner ?? true);
    getIt.registerSingleton<SessionStore>(store);
    final session = loginSession(store: store);
    session.applySignedInUser('user-1');
    getIt.registerSingleton<SessionController>(session);
  }

  await tester.pumpWidget(
    MaterialApp.router(
      theme: VTheme.lightTheme,
      routerConfig: appRouter,
      builder: repaintBoundaryKey != null
          ? (context, child) => RepaintBoundary(
                key: repaintBoundaryKey,
                child: child ?? const SizedBox.shrink(),
              )
          : null,
    ),
  );
  appRouter.go(location);
  await tester.pumpAndSettle();
}
