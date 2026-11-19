import 'package:erp/core/di/injection.dart';
import 'package:erp/core/router/app_router.dart';
import 'package:erp/core/session/session_controller.dart';
import 'package:erp/core/session/session_store.dart';
import 'package:erp/features/dashboard/data/default_pair_repository.dart';
import 'package:erp/features/inventory/data/core/inventory_rpc.dart';
import 'package:erp/features/inventory/data/goods_receipt/goods_receipt_models.dart';
import 'package:erp/features/inventory/data/goods_receipt/goods_receipt_repository.dart';
import 'package:erp/features/inventory/data/hub/warehouse_hub_repository.dart';
import 'package:erp/features/inventory/data/stock/stock_models.dart';
import 'package:erp/features/inventory/data/stock/stock_repository.dart';
import 'package:erp/features/inventory/data/stock_policy/stock_policy_models.dart';
import 'package:erp/features/inventory/data/stock_policy/stock_policy_repository.dart';
import 'package:erp/features/inventory/data/stocktake/stocktake_models.dart';
import 'package:erp/features/inventory/data/stocktake/stocktake_repository.dart';
import 'package:erp/features/inventory/data/supplier_program/supplier_program_models.dart';
import 'package:erp/features/inventory/data/supplier_program/supplier_program_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:c45_design_system/design_system.dart';

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

class _FakeStockRepo extends Fake implements StockRepository {
  @override
  Future<StockOverview> loadOverview() async => StockOverview(
        asOf: DateTime(2026, 9, 17, 21, 30),
        warehouseName: 'Kho trung tâm',
        products: const [
          StockOverviewItem(
            productId: 'INV-NOB',
            name: 'Nobivac DHPPi',
            code: 'SP-000184',
            barcode: '8938500001012',
            uom: 'hộp',
            isLotTracked: true,
            physical: 120,
            available: 118,
            hasExpired: false,
            hasNearExpiry: true,
            threshold: 30,
          ),
        ],
      );

  @override
  Future<StockDetail> loadDetail(String productId) async => StockDetail(
        asOf: DateTime(2026, 9, 17, 21, 30),
        warehouseName: 'Kho trung tâm',
        isOwner: true,
        productId: productId,
        name: 'Nobivac DHPPi',
        code: 'SP-000184',
        uom: 'hộp',
        isLotTracked: true,
        physical: 120,
        available: 118,
        expiredQuantity: 0,
        threshold: 30,
        target: 80,
      );
}

class _FakeGoodsReceiptRepo extends Fake implements GoodsReceiptRepository {
  @override
  Future<List<ReceiptListRow>> list({String? supplierId, int limit = 100}) async => [];

  @override
  Future<ReceiptFormOptions> formOptions() async => const ReceiptFormOptions(
        warehouseName: 'Kho chính',
        today: '2026-11-10',
        suppliers: [],
        products: [],
        lots: [],
      );
}

class _FakeSupplierProgramRepo extends Fake implements SupplierProgramRepository {
  @override
  Future<List<ProgramHint?>> receiptHints({
    required String supplierId,
    required List<({String productId, num paidQty, int unitPrice})> lines,
  }) async =>
      [];
}

class _FakeStocktakeRepo extends Fake implements StocktakeRepository {
  @override
  Future<List<StocktakeListRow>> list({int limit = 20, int offset = 0}) async =>
      [];
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
  getIt
    ..registerSingleton<SessionStore>(store)
    ..registerSingleton<DefaultPairRepository>(FakeDefaultPairRepository())
    ..registerSingleton<WarehouseHubRepository>(WarehouseHubRepository(rpc: _FakeInventoryRpc()))
    ..registerSingleton<StockPolicyRepository>(_FakeStockPolicyRepo())
    ..registerSingleton<StockRepository>(_FakeStockRepo())
    ..registerSingleton<GoodsReceiptRepository>(_FakeGoodsReceiptRepo())
    ..registerSingleton<StocktakeRepository>(_FakeStocktakeRepo())
    ..registerSingleton<SupplierProgramRepository>(_FakeSupplierProgramRepo())
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
