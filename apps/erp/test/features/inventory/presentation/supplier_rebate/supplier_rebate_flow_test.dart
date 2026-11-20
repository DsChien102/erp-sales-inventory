import 'package:erp/core/di/injection.dart';
import 'package:erp/features/inventory/data/core/inventory_rpc.dart';
import 'package:erp/features/inventory/data/hub/warehouse_hub_repository.dart';
import 'package:erp/features/inventory/data/hub/warehouse_hub_summary.dart';
import 'package:erp/features/inventory/data/stock/stock_models.dart';
import 'package:erp/features/inventory/data/stock/stock_repository.dart';
import 'package:erp/features/inventory/data/supplier_program/supplier_program_models.dart';
import 'package:erp/features/inventory/data/supplier_program/supplier_program_repository.dart';
import 'package:erp/features/inventory/data/supplier_rebate/supplier_rebate_models.dart';
import 'package:erp/features/inventory/data/supplier_rebate/supplier_rebate_repository.dart';
import 'package:erp/features/inventory/presentation/hub/warehouse_hub_page.dart';
import 'package:erp/features/inventory/presentation/stock/stock_routes.dart';
import 'package:erp/features/inventory/presentation/supplier_program/supplier_program_routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:c45_design_system/design_system.dart';

import '../../support/inventory_test_surface.dart';

class _FakeInventoryRpc extends Fake implements InventoryRpc {}

class _StatefulHubRepo extends WarehouseHubRepository {
  _StatefulHubRepo(this._getProgramsReached) : super(rpc: _FakeInventoryRpc());

  final int Function() _getProgramsReached;

  @override
  Future<WarehouseHubSummary> getSummary() async => WarehouseHubSummary(
        activated: true,
        programsReached: _getProgramsReached(),
      );
}

class _StatefulProgramRepo implements SupplierProgramRepository {
  ProgramStatus _status = ProgramStatus.reached;
  RecordedRebate? _rebate;

  static final _products = [
    const ProgramProduct(
      productId: 'P',
      name: 'Nobivac DHPPi',
      code: 'NBV-01',
      baseUom: 'hộp',
    ),
  ];

  ProgramRow get _row => ProgramRow(
        id: 'prog-1',
        supplierId: 'A',
        supplierName: 'NCC A',
        kind: ProgramKind.volumeRebate,
        name: 'Mốc 1.000 hộp Q4',
        status: _status,
        startedOn: DateTime(2026, 11, 1),
        productIds: const ['P'],
        productCount: 1,
        commonUom: 'hộp',
        tiers: const [],
        targetQty: 1000,
        rebatePercent: 5,
        progressQty: 1000,
      );

  @override
  Future<List<ProgramRow>> list() async => [_row];

  @override
  Future<ProgramDetail> get(String id) async => ProgramDetail(
        row: _row,
        revision: _status == ProgramStatus.recorded ? 2 : 1,
        isLocked: _status == ProgramStatus.recorded,
        viewerIsOwner: true,
        products: _products,
        receipts: const [],
        baseAmountVnd: 100000000,
        rebate: _rebate,
      );

  void markRecorded(RecordedRebate rebate) {
    _status = ProgramStatus.recorded;
    _rebate = rebate;
  }

  @override
  Future<ProgramFormOptions> formOptions() async => const ProgramFormOptions(
        suppliers: [
          SupplierOption(partnerId: 'A', displayName: 'NCC A'),
          SupplierOption(partnerId: 'B', displayName: 'Cty Á Châu'),
        ],
        products: [
          ProductOption(
            productId: 'P',
            name: 'Nobivac DHPPi',
            code: 'NBV-01',
            baseUnitId: 'u-1',
            baseUom: 'hộp',
          ),
        ],
      );

  @override
  Future<({String id, int revision})> create({
    required String idempotencyKey,
    required ProgramPayload payload,
  }) =>
      throw UnimplementedError();

  @override
  Future<({String id, int revision})> update({
    required String idempotencyKey,
    required String id,
    required int expectedRevision,
    required ProgramPayload payload,
  }) =>
      throw UnimplementedError();

  @override
  Future<int> end({
    required String idempotencyKey,
    required String id,
    required int expectedRevision,
  }) =>
      throw UnimplementedError();

  @override
  Future<List<ProgramHint?>> receiptHints({
    required String supplierId,
    required List<({String productId, num paidQty, int unitPrice})> lines,
  }) async =>
      const [];
}

class _StatefulRebateRepo implements SupplierRebateRepository {
  _StatefulRebateRepo(this._programRepo);

  final _StatefulProgramRepo _programRepo;

  @override
  Future<RebatePreview> preview({
    required String programId,
    int? amountVnd,
  }) async {
    const alloc = RebateAllocation(
      productId: 'P',
      name: 'Nobivac DHPPi',
      uom: 'hộp',
      paidQty: 1000,
      purchaseAmountVnd: 100000000,
      rebatePartVnd: 5000000,
      onHandQty: 300,
      inventoryPartVnd: 1500000,
      cogsPartVnd: 3500000,
      avgCostBefore: 100000,
      avgCostAfter: 95000,
    );
    return RebatePreview(
      programId: programId,
      programName: 'Mốc 1.000 hộp Q4',
      supplierName: 'NCC A',
      targetQty: 1000,
      progressQty: 1000,
      rebatePercent: 5,
      uom: 'hộp',
      baseAmountVnd: 100000000,
      proposedAmountVnd: 5000000,
      amountVnd: amountVnd ?? 5000000,
      allocations: const [alloc],
      inventoryPartTotal: 1500000,
      cogsPartTotal: 3500000,
    );
  }

  @override
  Future<RebateRecordResult> record({
    required String idempotencyKey,
    required String programId,
    required String documentNo,
    required DateTime documentDate,
    required int amountVnd,
    String? overrideReason,
  }) async {
    const alloc = RebateAllocation(
      productId: 'P',
      name: 'Nobivac DHPPi',
      uom: 'hộp',
      paidQty: 1000,
      purchaseAmountVnd: 100000000,
      rebatePartVnd: 5000000,
      onHandQty: 300,
      inventoryPartVnd: 1500000,
      cogsPartVnd: 3500000,
      avgCostBefore: 100000,
      avgCostAfter: 95000,
    );
    _programRepo.markRecorded(
      RecordedRebate(
        rebateId: 'reb-1',
        documentNo: documentNo,
        documentDate: documentDate,
        baseAmountVnd: 100000000,
        proposedAmountVnd: 5000000,
        rebateAmountVnd: amountVnd,
        inventoryPartVnd: 1500000,
        cogsPartVnd: 3500000,
        recordedAt: DateTime.utc(2026, 11, 12),
        recordedByName: 'Chủ cửa hàng',
        allocations: const [alloc],
      ),
    );
    return RebateRecordResult(
      rebateId: 'reb-1',
      programId: programId,
      programName: 'Mốc 1.000 hộp Q4',
      supplierName: 'NCC A',
      targetQty: 1000,
      progressQty: 1000,
      rebatePercent: 5,
      uom: 'hộp',
      baseAmountVnd: 100000000,
      proposedAmountVnd: 5000000,
      amountVnd: amountVnd,
      allocations: const [alloc],
      inventoryPartTotal: 1500000,
      cogsPartTotal: 3500000,
    );
  }

  @override
  Future<ProjectedCost> projectedCost({
    required String programId,
    required String productId,
    num? extraQty,
    num? unitPrice,
  }) =>
      throw UnimplementedError();

  @override
  Future<SupplierCompare> compareSuppliers(String productId) async =>
      SupplierCompare(
        productId: productId,
        name: 'Nobivac DHPPi',
        code: 'NBV-01',
        uom: 'hộp',
        financialMasked: false,
        suppliers: [
          SupplierCompareRow(
            partnerId: 'A',
            name: 'NCC A',
            isSystem: false,
            lastLandedUnitCost: 95000,
            lastReceivedOn: DateTime(2026, 11, 5),
            avgLandedUnitCost: 97200,
            receiptCount: 2,
            paidQty: 1000,
            freeQty: 0,
            program: _programRepo._row,
          ),
          SupplierCompareRow(
            partnerId: 'B',
            name: 'Cty Á Châu',
            isSystem: false,
            lastLandedUnitCost: 100000,
            lastReceivedOn: DateTime(2026, 11, 1),
            avgLandedUnitCost: 100000,
            receiptCount: 1,
            paidQty: 10,
            freeQty: 0,
          ),
        ],
      );
}

class _FakeStockRepo extends Fake implements StockRepository {
  @override
  Future<StockDetail> loadDetail(String productId) async => StockDetail(
        asOf: DateTime(2026, 11, 12, 9, 0),
        warehouseName: 'Kho trung tâm',
        isOwner: true,
        productId: productId,
        name: 'Nobivac DHPPi',
        code: 'NBV-01',
        uom: 'hộp',
        isLotTracked: false,
        physical: 300,
        available: 300,
        expiredQuantity: 0,
        threshold: 30,
        target: 80,
      );
}

void main() {
  late _StatefulProgramRepo programRepo;
  late _StatefulRebateRepo rebateRepo;
  late _StatefulHubRepo hubRepo;

  setUp(() async {
    await getIt.reset();
    programRepo = _StatefulProgramRepo();
    rebateRepo = _StatefulRebateRepo(programRepo);
    hubRepo = _StatefulHubRepo(
      () => programRepo._status == ProgramStatus.reached ? 1 : 0,
    );
    getIt
      ..registerSingleton<WarehouseHubRepository>(hubRepo)
      ..registerSingleton<SupplierProgramRepository>(programRepo)
      ..registerSingleton<SupplierRebateRepository>(rebateRepo)
      ..registerSingleton<StockRepository>(_FakeStockRepo());
  });

  tearDown(() async {
    await getIt.reset();
  });

  Widget buildRouterApp({required String initialLocation}) {
    const size = Size(390, 844);
    useInventoryTestSurface(size);
    final router = GoRouter(
      initialLocation: initialLocation,
      routes: [
        GoRoute(
          path: '/warehouse',
          builder: (_, _) => const WarehouseHubPage(),
        ),
        ...supplierProgramRoutes(),
        ...stockRoutes(),
      ],
    );
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      theme: VTheme.lightTheme,
      routerConfig: router,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(size: size),
        child: child!,
      ),
    );
  }

  testWidgets('supplier_rebate_flow_test', (tester) async {
    await tester.pumpWidget(buildRouterApp(initialLocation: '/warehouse'));
    await tester.pumpAndSettle();

    // 1. Hub "Chương trình đạt mốc" -> P1 Đạt mốc
    expect(find.text('Chương trình đạt mốc'), findsOneWidget);
    await tester.tap(find.text('Chương trình đạt mốc'));
    await tester.pumpAndSettle();

    expect(find.text('Mốc 1.000 hộp Q4'), findsOneWidget);

    // 2. Chạm chương trình -> P3 -> "Ghi nhận chiết khấu" -> P4
    await tester.tap(find.text('Mốc 1.000 hộp Q4'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Ghi nhận chiết khấu'));
    await tester.pumpAndSettle();

    // 3. P4 nhập số chứng từ -> "Ghi nhận" -> sheet "Ghi nhận" -> K4
    final docField = find.byType(TextField).first;
    await tester.ensureVisible(docField);
    await tester.enterText(docField, 'CK-2026-01');
    await tester.pumpAndSettle();

    await tester.tap(find.text('Ghi nhận'));
    await tester.pumpAndSettle();

    // Nút Ghi nhận trong bottom sheet (cái cuối cùng trong cây)
    await tester.tap(find.text('Ghi nhận').last);
    await tester.pumpAndSettle();

    expect(find.text('Đã ghi nhận chiết khấu'), findsOneWidget);

    // 4. K4 "Xem chương trình" -> P3 có "Chiết khấu đã ghi nhận", ẩn nút ghi nhận
    await tester.tap(find.text('Xem chương trình'));
    await tester.pumpAndSettle();

    expect(find.text('Chiết khấu đã ghi nhận'), findsOneWidget);
    expect(find.text('Ghi nhận chiết khấu'), findsNothing);
  });

  testWidgets('compare_flow', (tester) async {
    await tester.pumpWidget(buildRouterApp(initialLocation: '/warehouse/stock/P'));
    await tester.pumpAndSettle();

    // 1. Tồn kho -> "So sánh nhà cung cấp" -> P5
    await tester.ensureVisible(find.text('So sánh nhà cung cấp'));
    await tester.tap(find.text('So sánh nhà cung cấp'));
    await tester.pumpAndSettle();

    expect(find.text('Cty Á Châu'), findsOneWidget);
    expect(find.text('Thêm ưu đãi'), findsOneWidget);

    // 2. "Thêm ưu đãi" -> P2 có sẵn NCC + sản phẩm
    await tester.tap(find.text('Thêm ưu đãi'));
    await tester.pumpAndSettle();

    expect(find.text('Cty Á Châu'), findsOneWidget);
    expect(find.text('Nobivac DHPPi'), findsOneWidget);
  });
}
