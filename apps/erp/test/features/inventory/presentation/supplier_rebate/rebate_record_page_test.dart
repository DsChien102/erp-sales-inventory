import 'package:erp/core/di/injection.dart';
import 'package:erp/core/errors/app_exception.dart';
import 'package:erp/features/inventory/data/core/inventory_error_codes.dart';
import 'package:erp/features/inventory/data/supplier_program/supplier_program_models.dart';
import 'package:erp/features/inventory/data/supplier_program/supplier_program_repository.dart';
import 'package:erp/features/inventory/data/supplier_rebate/supplier_rebate_models.dart';
import 'package:erp/features/inventory/data/supplier_rebate/supplier_rebate_repository.dart';
import 'package:erp/features/inventory/presentation/supplier_rebate/rebate_record_page.dart';
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

class _FakeSupplierRebateRepository implements SupplierRebateRepository {
  RebatePreview previewResponse = _defaultPreview();
  RebateRecordResult? recordResponse;
  Object? previewError;
  Object? recordError;
  int previewCallCount = 0;
  int recordCallCount = 0;

  @override
  Future<RebatePreview> preview({
    required String programId,
    int? amountVnd,
  }) async {
    previewCallCount++;
    if (previewError != null) throw previewError!;
    if (amountVnd != null && amountVnd != previewResponse.amountVnd) {
      return RebatePreview(
        programId: previewResponse.programId,
        programName: previewResponse.programName,
        supplierName: previewResponse.supplierName,
        targetQty: previewResponse.targetQty,
        progressQty: previewResponse.progressQty,
        rebatePercent: previewResponse.rebatePercent,
        uom: previewResponse.uom,
        baseAmountVnd: previewResponse.baseAmountVnd,
        proposedAmountVnd: previewResponse.proposedAmountVnd,
        amountVnd: amountVnd,
        allocations: previewResponse.allocations,
        inventoryPartTotal: 1200000,
        cogsPartTotal: amountVnd - 1200000,
      );
    }
    return previewResponse;
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
    recordCallCount++;
    if (recordError != null) throw recordError!;
    return recordResponse ??
        RebateRecordResult(
          rebateId: 'reb-1',
          programId: programId,
          programName: previewResponse.programName,
          supplierName: previewResponse.supplierName,
          targetQty: previewResponse.targetQty,
          progressQty: previewResponse.progressQty,
          rebatePercent: previewResponse.rebatePercent,
          uom: previewResponse.uom,
          baseAmountVnd: previewResponse.baseAmountVnd,
          proposedAmountVnd: previewResponse.proposedAmountVnd,
          amountVnd: amountVnd,
          allocations: previewResponse.allocations,
          inventoryPartTotal: previewResponse.inventoryPartTotal,
          cogsPartTotal: previewResponse.cogsPartTotal,
        );
  }

  @override
  Future<ProjectedCost> projectedCost({
    required String programId,
    required String productId,
    num? extraQty,
    num? unitPrice,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<SupplierCompare> compareSuppliers(String productId) {
    throw UnimplementedError();
  }
}

ProgramDetail _reachedDetail({bool viewerIsOwner = true}) {
  return ProgramDetail(
    row: ProgramRow(
      id: 'p1',
      supplierId: 'sup-1',
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
    viewerIsOwner: viewerIsOwner,
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
  );
}

RebatePreview _defaultPreview() {
  return const RebatePreview(
    programId: 'p1',
    programName: 'Mốc 1.000 hộp Q4',
    supplierName: 'NCC A',
    targetQty: 1000,
    progressQty: 1000,
    rebatePercent: 5,
    uom: 'hộp',
    baseAmountVnd: 100000000,
    proposedAmountVnd: 5000000,
    amountVnd: 5000000,
    allocations: [
      RebateAllocation(
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
      ),
    ],
    inventoryPartTotal: 1500000,
    cogsPartTotal: 3500000,
  );
}

void main() {
  late _FakeSupplierProgramRepository programs;
  late _FakeSupplierRebateRepository rebates;

  setUp(() async {
    await getIt.reset();
    programs = _FakeSupplierProgramRepository(_reachedDetail());
    rebates = _FakeSupplierRebateRepository();
    getIt.registerSingleton<SupplierProgramRepository>(programs);
    getIt.registerSingleton<SupplierRebateRepository>(rebates);
  });

  tearDown(() async {
    await getIt.reset();
  });

  Widget buildApp({
    Size size = const Size(390, 844),
    void Function(String path, Object? extra)? onNavigated,
  }) {
    useInventoryTestSurface(size);
    final router = GoRouter(
      initialLocation: '/warehouse/supplier-programs/p1/rebate',
      routes: [
        GoRoute(
          path: '/warehouse/supplier-programs/:programId',
          builder: (_, state) {
            final id = state.pathParameters['programId']!;
            onNavigated?.call('/warehouse/supplier-programs/$id', state.extra);
            return Scaffold(body: Text('DETAIL:$id'));
          },
        ),
        GoRoute(
          path: '/warehouse/supplier-programs/:programId/rebate',
          builder: (_, state) => RebateRecordPage(
            programId: state.pathParameters['programId']!,
          ),
        ),
        GoRoute(
          path: '/warehouse/supplier-programs/:programId/rebate/result',
          builder: (_, state) {
            final id = state.pathParameters['programId']!;
            onNavigated?.call(
              '/warehouse/supplier-programs/$id/rebate/result',
              state.extra,
            );
            return Scaffold(body: Text('RESULT:$id:${state.extra}'));
          },
        ),
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

  group('RebateRecordPage', () {
    testWidgets('ready_390', (tester) async {
      await tester.pumpWidget(buildApp(size: const Size(390, 844)));
      await tester.pumpAndSettle();

      expect(find.text('Căn cứ'), findsOneWidget);
      expect(find.text('Đề xuất'), findsOneWidget);
      expect(find.text('5.000.000 đ'), findsWidgets);
      expect(find.text('Số chứng từ'), findsOneWidget);
      expect(find.text('Phân bổ (xem trước)'), findsOneWidget);
      expect(find.text('Giảm giá trị tồn'), findsOneWidget);
      expect(find.text('Bình quân'), findsOneWidget);
      expect(
        find.text(
          'Hàng đang tồn được coi là thuộc các lần nhập của chương trình (tối đa số đã mua). Ghi nhận xong không sửa được.',
        ),
        findsOneWidget,
      );
      expect(find.text('Lý do khác đề xuất'), findsNothing);
    });

    testWidgets('ready_1280', (tester) async {
      await tester.pumpWidget(buildApp(size: const Size(1280, 800)));
      await tester.pumpAndSettle();

      expect(find.text('Căn cứ'), findsOneWidget);
      expect(find.text('Đề xuất'), findsOneWidget);
      expect(find.text('5.000.000 đ'), findsWidgets);
      expect(find.text('Số chứng từ'), findsOneWidget);
      expect(find.text('Phân bổ (xem trước)'), findsOneWidget);
      expect(find.text('TỒN / MUA'), findsOneWidget);
      expect(find.text('GIẢM GIÁ TRỊ TỒN'), findsOneWidget);
      expect(find.text('BÌNH QUÂN'), findsOneWidget);
      expect(
        find.text(
          'Hàng đang tồn được coi là thuộc các lần nhập của chương trình (tối đa số đã mua). Ghi nhận xong không sửa được.',
        ),
        findsOneWidget,
      );
      expect(find.text('Lý do khác đề xuất'), findsNothing);
    });

    testWidgets('override_shows_reason', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      expect(find.text('Lý do khác đề xuất'), findsNothing);

      final fields = tester.widgetList<VTextField>(find.byType(VTextField));
      expect(fields.length, 2);
      await tester.enterText(find.byType(TextField).at(1), '4.000.000');
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();

      expect(find.text('Lý do khác đề xuất'), findsOneWidget);
    });

    testWidgets('confirm_sheet_text', (tester) async {
      String? routedTo;
      Object? routedExtra;
      await tester.pumpWidget(
        buildApp(
          onNavigated: (path, extra) {
            routedTo = path;
            routedExtra = extra;
          },
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).first, 'CK-2026-11');
      await tester.pumpAndSettle();

      await tester.tap(find.text('Ghi nhận').last);
      await tester.pumpAndSettle();

      expect(find.text('Ghi nhận chiết khấu 5.000.000 đ?'), findsOneWidget);
      expect(
        find.text(
          'Giá trị tồn và bình quân của 1 sản phẩm sẽ giảm. Không hoàn tác được.',
        ),
        findsOneWidget,
      );

      await tester.tap(find.text('Ghi nhận').last);
      await tester.pumpAndSettle();

      expect(rebates.recordCallCount, 1);
      expect(routedTo, '/warehouse/supplier-programs/p1/rebate/result');
      expect(routedExtra, 1500000);
    });

    testWidgets('staff_locked_390', (tester) async {
      programs.detail = _reachedDetail(viewerIsOwner: false);

      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      expect(
        find.text('Chỉ chủ cửa hàng ghi nhận được chiết khấu.'),
        findsOneWidget,
      );
      expect(find.text('Về chương trình'), findsOneWidget);
      expect(find.byType(VTextField), findsNothing);
      expect(rebates.previewCallCount, 0);
    });

    testWidgets('record_already_recorded_stale_390', (tester) async {
      rebates.recordError = const AppException(
        InventoryErrorCode.programNotReached,
        serverMessage: 'already recorded',
      );
      String? routedTo;

      await tester.pumpWidget(
        buildApp(onNavigated: (path, _) => routedTo = path),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).first, 'CK-2026-11');
      await tester.pumpAndSettle();

      await tester.tap(find.text('Ghi nhận').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Ghi nhận').last);
      await tester.pumpAndSettle();

      expect(
        find.text('Chương trình đã được ghi nhận chiết khấu'),
        findsOneWidget,
      );
      expect(find.text('Xem chương trình'), findsOneWidget);

      await tester.tap(find.text('Xem chương trình'));
      await tester.pumpAndSettle();
      expect(routedTo, '/warehouse/supplier-programs/p1');
    });

    testWidgets('period_closed_banner', (tester) async {
      rebates.recordError = const AppException(
        InventoryErrorCode.periodClosed,
        serverMessage: 'period closed',
      );

      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).first, 'CK-2026-11');
      await tester.pumpAndSettle();

      await tester.tap(find.text('Ghi nhận').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Ghi nhận').last);
      await tester.pumpAndSettle();

      expect(
        find.text(
          inventoryErrorMessage(
            const AppException(InventoryErrorCode.periodClosed),
            fallback: '',
          ),
        ),
        findsOneWidget,
      );
      expect(find.text('CK-2026-11'), findsOneWidget);
    });
  });
}
