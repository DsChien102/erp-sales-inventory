import 'package:erp/core/di/injection.dart';
import 'package:erp/features/inventory/data/supplier_program/supplier_program_models.dart';
import 'package:erp/features/inventory/data/supplier_program/supplier_program_repository.dart';
import 'package:erp/features/inventory/data/supplier_rebate/supplier_rebate_models.dart';
import 'package:erp/features/inventory/presentation/supplier_rebate/rebate_result_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:c45_design_system/design_system.dart';

import '../../support/inventory_test_surface.dart';

class _FakeSupplierProgramRepository implements SupplierProgramRepository {
  ProgramDetail detail;

  _FakeSupplierProgramRepository(this.detail);

  @override
  Future<ProgramDetail> get(String id) async => detail;

  @override
  Future<List<ProgramRow>> list() async => const [];

  @override
  Future<ProgramFormOptions> formOptions() async => const ProgramFormOptions(
        suppliers: [],
        products: [],
      );

  @override
  Future<({String id, int revision})> create({
    required String idempotencyKey,
    required ProgramPayload payload,
  }) async =>
      (id: 'p1', revision: 1);

  @override
  Future<({String id, int revision})> update({
    required String idempotencyKey,
    required String id,
    required int expectedRevision,
    required ProgramPayload payload,
  }) async =>
      (id: id, revision: expectedRevision + 1);

  @override
  Future<int> end({
    required String idempotencyKey,
    required String id,
    required int expectedRevision,
  }) async =>
      expectedRevision + 1;

  @override
  Future<List<ProgramHint?>> receiptHints({
    required String supplierId,
    required List<({String productId, num paidQty, int unitPrice})> lines,
  }) async =>
      const [];
}

ProgramDetail _recordedDetail({int inventoryPartVnd = 1500000}) {
  final cogs = 5000000 - inventoryPartVnd;
  return ProgramDetail(
    row: ProgramRow(
      id: 'p1',
      supplierId: 'sup-1',
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
    viewerIsOwner: true,
    products: const [
      ProgramProduct(
        productId: 'prod-1',
        name: 'Nobivac DHPPi',
        code: 'NBV-01',
        baseUom: 'hộp',
      ),
    ],
    receipts: const [],
    baseAmountVnd: 100000000,
    rebate: RecordedRebate(
      rebateId: 'reb-1',
      documentNo: 'CK-2026-11',
      documentDate: DateTime(2026, 11, 12),
      baseAmountVnd: 100000000,
      proposedAmountVnd: 5000000,
      rebateAmountVnd: 5000000,
      inventoryPartVnd: inventoryPartVnd,
      cogsPartVnd: cogs,
      recordedAt: DateTime(2026, 11, 12, 14, 5),
      recordedByName: 'Chủ',
      allocations: [
        RebateAllocation(
          productId: 'prod-1',
          name: 'Nobivac DHPPi',
          uom: 'hộp',
          paidQty: 1000,
          purchaseAmountVnd: 100000000,
          rebatePartVnd: 5000000,
          onHandQty: 300,
          inventoryPartVnd: inventoryPartVnd,
          cogsPartVnd: cogs,
          avgCostBefore: 100000,
          avgCostAfter: 95000,
        ),
      ],
    ),
  );
}

void main() {
  late _FakeSupplierProgramRepository programs;

  setUp(() async {
    await getIt.reset();
    programs = _FakeSupplierProgramRepository(_recordedDetail());
    getIt.registerSingleton<SupplierProgramRepository>(programs);
  });

  tearDown(() async {
    await getIt.reset();
  });

  Widget buildApp({
    int? previewInventoryTotal,
    void Function(String path)? onNavigated,
  }) {
    useInventoryTestSurface(const Size(390, 844));
    final router = GoRouter(
      initialLocation: '/warehouse/supplier-programs/p1/rebate/result',
      routes: [
        GoRoute(
          path: '/warehouse',
          builder: (_, _) {
            onNavigated?.call('/warehouse');
            return const Scaffold(body: Text('WAREHOUSE'));
          },
        ),
        GoRoute(
          path: '/warehouse/supplier-programs/:programId',
          builder: (_, state) {
            final id = state.pathParameters['programId']!;
            onNavigated?.call('/warehouse/supplier-programs/$id');
            return Scaffold(body: Text('DETAIL:$id'));
          },
        ),
        GoRoute(
          path: '/warehouse/supplier-programs/:programId/rebate/result',
          builder: (_, state) => RebateResultPage(
            programId: state.pathParameters['programId']!,
            previewInventoryTotal: previewInventoryTotal,
          ),
        ),
      ],
    );

    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      theme: VTheme.lightTheme,
      routerConfig: router,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(size: const Size(390, 844)),
        child: child!,
      ),
    );
  }

  group('RebateResultPage', () {
    testWidgets('result_page', (tester) async {
      String? routedTo;
      await tester.pumpWidget(
        buildApp(onNavigated: (p) => routedTo = p),
      );
      await tester.pumpAndSettle();

      final scaffold = tester.widget<VPageScaffold>(find.byType(VPageScaffold));
      expect(scaffold.showBackButton, isFalse);

      expect(find.text('Đã ghi nhận chiết khấu'), findsOneWidget);
      expect(
        find.text('5.000.000 đ từ NCC A cho chương trình "Mốc 1.000 hộp Q4".'),
        findsOneWidget,
      );
      expect(find.text('Giảm giá trị tồn'), findsOneWidget);
      expect(find.text('Tồn kho đã đổi'), findsOneWidget);
      expect(
        find.text('Nobivac DHPPi 100.000 đ/hộp → 95.000 đ/hộp'),
        findsOneWidget,
      );
      expect(find.text('Xem chương trình'), findsOneWidget);
      expect(find.text('Về Kho'), findsOneWidget);

      await tester.tap(find.text('Xem chương trình'));
      await tester.pumpAndSettle();
      expect(routedTo, '/warehouse/supplier-programs/p1');
    });

    testWidgets('result_shows_changed_note', (tester) async {
      programs.detail = _recordedDetail(inventoryPartVnd: 1000000);

      await tester.pumpWidget(buildApp(previewInventoryTotal: 1500000));
      await tester.pumpAndSettle();

      expect(
        find.text(
          'Tồn đã đổi từ lúc xem trước, số đã tính lại theo tồn hiện tại.',
        ),
        findsOneWidget,
      );

      await tester.pumpWidget(buildApp(previewInventoryTotal: null));
      await tester.pumpAndSettle();

      expect(
        find.text(
          'Tồn đã đổi từ lúc xem trước, số đã tính lại theo tồn hiện tại.',
        ),
        findsNothing,
      );
    });
  });
}

