import 'dart:io';

import 'package:erp/core/di/injection.dart';
import 'package:erp/features/inventory/data/supplier_program/supplier_program_models.dart';
import 'package:erp/features/inventory/data/supplier_program/supplier_program_repository.dart';
import 'package:erp/features/inventory/data/supplier_rebate/supplier_rebate_models.dart';
import 'package:erp/features/inventory/data/supplier_rebate/supplier_rebate_repository.dart';
import 'package:erp/features/inventory/presentation/supplier_program/program_detail_page.dart';
import 'package:erp/features/inventory/presentation/supplier_rebate/rebate_record_page.dart';
import 'package:erp/features/inventory/presentation/supplier_rebate/rebate_result_page.dart';
import 'package:erp/features/inventory/presentation/supplier_rebate/supplier_compare_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/inventory_router_harness.dart';

String _goldenPath(String fileName) {
  final root = Directory.current.path.endsWith('apps/erp')
      ? Directory.current.parent.parent.path
      : Directory.current.path;
  return '$root/docs/refactor/plans/T7/img/G5-5b/$fileName';
}

class _GoldenProgramRepo extends Fake implements SupplierProgramRepository {
  static const _products = [
    ProgramProduct(
      productId: 'prod-1',
      name: 'Nobivac DHPPi',
      code: 'NBV-01',
      baseUom: 'hộp',
    ),
  ];

  static final _receipts = [
    ProgramReceipt(
      receiptLineId: 'rec-line-1',
      paidQty: 400,
      purchaseAmountVnd: 40000000,
      createdAt: DateTime(2026, 11, 1, 9, 30),
    ),
    ProgramReceipt(
      receiptLineId: 'rec-line-2',
      paidQty: 600,
      purchaseAmountVnd: 60000000,
      createdAt: DateTime(2026, 11, 5, 14, 15),
    ),
  ];

  static const _alloc = RebateAllocation(
    productId: 'prod-1',
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

  late final Map<String, ProgramDetail> _details = {
    'p-active': ProgramDetail(
      row: ProgramRow(
        id: 'p-active',
        supplierId: 'sup-a',
        supplierName: 'NCC A',
        kind: ProgramKind.volumeRebate,
        name: 'Mốc 1.000 hộp Q4',
        status: ProgramStatus.active,
        startedOn: DateTime(2026, 11, 1),
        productIds: const ['prod-1'],
        productCount: 1,
        commonUom: 'hộp',
        tiers: const [],
        targetQty: 1000,
        rebatePercent: 5,
        progressQty: 700,
      ),
      revision: 1,
      isLocked: true,
      viewerIsOwner: true,
      products: _products,
      receipts: [_receipts.first],
      baseAmountVnd: 70000000,
    ),
    'p-reached': ProgramDetail(
      row: ProgramRow(
        id: 'p-reached',
        supplierId: 'sup-a',
        supplierName: 'NCC A',
        kind: ProgramKind.volumeRebate,
        name: 'Mốc 1.000 hộp Q4',
        status: ProgramStatus.reached,
        startedOn: DateTime(2026, 11, 1),
        productIds: const ['prod-1'],
        productCount: 1,
        commonUom: 'hộp',
        tiers: const [],
        targetQty: 1000,
        rebatePercent: 5,
        progressQty: 1000,
      ),
      revision: 1,
      isLocked: true,
      reachedAt: DateTime(2026, 11, 5, 14, 15),
      viewerIsOwner: true,
      products: _products,
      receipts: _receipts,
      baseAmountVnd: 100000000,
    ),
    'p-recorded': ProgramDetail(
      row: ProgramRow(
        id: 'p-recorded',
        supplierId: 'sup-a',
        supplierName: 'NCC A',
        kind: ProgramKind.volumeRebate,
        name: 'Mốc 1.000 hộp Q4',
        status: ProgramStatus.recorded,
        startedOn: DateTime(2026, 11, 1),
        productIds: const ['prod-1'],
        productCount: 1,
        commonUom: 'hộp',
        tiers: const [],
        targetQty: 1000,
        rebatePercent: 5,
        progressQty: 1000,
      ),
      revision: 2,
      isLocked: true,
      reachedAt: DateTime(2026, 11, 5, 14, 15),
      viewerIsOwner: true,
      products: _products,
      receipts: _receipts,
      baseAmountVnd: 100000000,
      rebate: RecordedRebate(
        rebateId: 'reb-14',
        documentNo: 'CK-261112-01',
        documentDate: DateTime(2026, 11, 12),
        baseAmountVnd: 100000000,
        proposedAmountVnd: 5000000,
        rebateAmountVnd: 5000000,
        inventoryPartVnd: 1500000,
        cogsPartVnd: 3500000,
        recordedAt: DateTime(2026, 11, 12, 10, 0),
        recordedByName: 'Chủ cửa hàng',
        allocations: [_alloc],
      ),
    ),
  };

  @override
  Future<ProgramDetail> get(String id) async => _details[id]!;
}

class _GoldenRebateRepo extends Fake implements SupplierRebateRepository {
  @override
  Future<RebatePreview> preview({
    required String programId,
    int? amountVnd,
  }) async {
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
      allocations: const [_GoldenProgramRepo._alloc],
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
  }) async {
    return const ProjectedCost(
      productId: 'prod-1',
      uom: 'hộp',
      progressQty: 700,
      targetQty: 1000,
      missingQty: 300,
      reachesTarget: true,
      rebateEstimate: 5000000,
      avgNow: 100000,
      avgProjected: 95000,
      defaultUnitPrice: 100000,
      financialMasked: false,
    );
  }

  @override
  Future<SupplierCompare> compareSuppliers(String productId) async {
    return SupplierCompare(
      productId: productId,
      name: 'Nobivac DHPPi',
      code: 'NBV-01',
      uom: 'hộp',
      financialMasked: false,
      suppliers: [
        SupplierCompareRow(
          partnerId: 'sup-a',
          name: 'NCC A',
          isSystem: false,
          lastLandedUnitCost: 95000,
          lastReceivedOn: DateTime(2026, 11, 5),
          avgLandedUnitCost: 97200,
          receiptCount: 3,
          paidQty: 1000,
          freeQty: 0,
          program: ProgramRow(
            id: 'p-reached',
            supplierId: 'sup-a',
            supplierName: 'NCC A',
            kind: ProgramKind.volumeRebate,
            name: 'Mốc 1.000 hộp Q4',
            status: ProgramStatus.reached,
            startedOn: DateTime(2026, 11, 1),
            productIds: const ['prod-1'],
            productCount: 1,
            commonUom: 'hộp',
            tiers: const [],
            targetQty: 1000,
            rebatePercent: 5,
            progressQty: 1000,
          ),
        ),
        SupplierCompareRow(
          partnerId: 'sup-b',
          name: 'Cty Á Châu',
          isSystem: false,
          lastLandedUnitCost: 100000,
          lastReceivedOn: DateTime(2026, 11, 1),
          avgLandedUnitCost: 100000,
          receiptCount: 1,
          paidQty: 10,
          freeQty: 1,
        ),
        SupplierCompareRow(
          partnerId: 'sup-sys',
          name: 'Mua lẻ / khác',
          isSystem: true,
          lastLandedUnitCost: 110000,
          lastReceivedOn: DateTime(2026, 11, 1),
          avgLandedUnitCost: 110000,
          receiptCount: 1,
          paidQty: 5,
          freeQty: 0,
        ),
      ],
    );
  }
}

void _goldenTest(String name, WidgetTesterCallback body) {
  testWidgets(name, body, tags: 'golden');
}

void main() {
  setUp(() async {
    await setUpInventoryRouterTest();
    if (getIt.isRegistered<SupplierProgramRepository>()) {
      getIt.unregister<SupplierProgramRepository>();
    }
    if (getIt.isRegistered<SupplierRebateRepository>()) {
      getIt.unregister<SupplierRebateRepository>();
    }
    getIt
      ..registerSingleton<SupplierProgramRepository>(_GoldenProgramRepo())
      ..registerSingleton<SupplierRebateRepository>(_GoldenRebateRepo());
  });

  tearDown(() async {
    await tearDownInventoryRouterTest();
  });

  Future<void> captureBothSizes(
    WidgetTester tester, {
    required String location,
    required Type expectedPage,
    required String prefix,
    String? scrollToTextOn390,
  }) async {
    final key390 = GlobalKey();
    await pumpInventoryApp(
      tester,
      size: const Size(390, 844),
      location: location,
      repaintBoundaryKey: key390,
    );
    expect(find.byType(expectedPage), findsOneWidget);
    if (scrollToTextOn390 != null) {
      await tester.ensureVisible(find.text(scrollToTextOn390));
      await tester.pumpAndSettle();
    }
    await expectLater(
      find.byKey(key390),
      matchesGoldenFile(_goldenPath('$prefix-390.png')),
    );

    final key1280 = GlobalKey();
    await pumpInventoryApp(
      tester,
      size: const Size(1280, 800),
      location: location,
      repaintBoundaryKey: key1280,
    );
    expect(find.byType(expectedPage), findsOneWidget);
    await expectLater(
      find.byKey(key1280),
      matchesGoldenFile(_goldenPath('$prefix-1280.png')),
    );
  }

  group('SupplierRebate Golden Screenshots (G5-5b Task 9)', () {
    _goldenTest('capture_P4_READY_390_and_1280', (tester) async {
      await captureBothSizes(
        tester,
        location: '/warehouse/supplier-programs/p-reached/rebate',
        expectedPage: RebateRecordPage,
        prefix: 'flutter-P4-READY',
      );
    });

    _goldenTest('capture_P4_RESULT_390_and_1280', (tester) async {
      await captureBothSizes(
        tester,
        location: '/warehouse/supplier-programs/p-recorded/rebate/result',
        expectedPage: RebateResultPage,
        prefix: 'flutter-P4-RESULT',
      );
    });

    _goldenTest('capture_P3_PROJECTED_390_and_1280', (tester) async {
      await captureBothSizes(
        tester,
        location: '/warehouse/supplier-programs/p-active',
        expectedPage: ProgramDetailPage,
        prefix: 'flutter-P3-PROJECTED',
        scrollToTextOn390: 'Giá vốn dự kiến',
      );
    });

    _goldenTest('capture_P3_RECORDED_390_and_1280', (tester) async {
      await captureBothSizes(
        tester,
        location: '/warehouse/supplier-programs/p-recorded',
        expectedPage: ProgramDetailPage,
        prefix: 'flutter-P3-RECORDED',
      );
    });

    _goldenTest('capture_P5_READY_390_and_1280', (tester) async {
      await captureBothSizes(
        tester,
        location: '/warehouse/stock/prod-1/suppliers',
        expectedPage: SupplierComparePage,
        prefix: 'flutter-P5-READY',
      );
    });
  });
}
