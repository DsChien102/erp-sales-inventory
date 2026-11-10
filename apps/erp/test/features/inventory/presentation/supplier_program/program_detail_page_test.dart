import 'dart:io';

import 'package:erp/core/di/injection.dart';
import 'package:erp/core/errors/app_exception.dart';
import 'package:erp/features/inventory/data/core/inventory_error_codes.dart';
import 'package:erp/features/inventory/data/supplier_program/supplier_program_models.dart';
import 'package:erp/features/inventory/data/supplier_program/supplier_program_repository.dart';
import 'package:erp/features/inventory/presentation/supplier_program/program_detail_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:vet45_design_system/design_system.dart';

import '../../support/inventory_test_surface.dart';

String _goldenPath(String fileName) {
  final root = Directory.current.path.endsWith('apps/erp')
      ? Directory.current.parent.parent.path
      : Directory.current.path;
  return '$root/docs/refactor/plans/T7/img/G5-2b/$fileName';
}

class _FakeSupplierProgramRepository implements SupplierProgramRepository {
  ProgramDetail detail;
  AppException? getError;
  int endCallCount = 0;

  _FakeSupplierProgramRepository({
    required this.detail,
  });

  @override
  Future<ProgramDetail> get(String id) async {
    if (getError != null) throw getError!;
    return detail;
  }

  @override
  Future<int> end({
    required String idempotencyKey,
    required String id,
    required int expectedRevision,
  }) async {
    endCallCount++;
    final nextRev = expectedRevision + 1;
    final current = detail.row;
    detail = ProgramDetail(
      row: ProgramRow(
        id: current.id,
        supplierId: current.supplierId,
        supplierName: current.supplierName,
        kind: current.kind,
        name: current.name,
        status: ProgramStatus.ended,
        startedOn: current.startedOn,
        productIds: current.productIds,
        productCount: current.productCount,
        commonUom: current.commonUom,
        tiers: current.tiers,
        buyQty: current.buyQty,
        freeQty: current.freeQty,
        targetQty: current.targetQty,
        rebatePercent: current.rebatePercent,
        progressQty: current.progressQty,
      ),
      note: detail.note,
      revision: nextRev,
      isLocked: detail.isLocked,
      reachedAt: detail.reachedAt,
      endedAt: DateTime.utc(2026, 11, 15),
      products: detail.products,
      receipts: detail.receipts,
      baseAmountVnd: detail.baseAmountVnd,
    );
    return nextRev;
  }

  @override
  Future<List<ProgramRow>> list() async => [];

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
      (id: 'new', revision: 1);

  @override
  Future<({String id, int revision})> update({
    required String idempotencyKey,
    required String id,
    required int expectedRevision,
    required ProgramPayload payload,
  }) async =>
      (id: id, revision: expectedRevision + 1);

  @override
  Future<List<ProgramHint?>> receiptHints({
    required String supplierId,
    required List<({String productId, num paidQty, int unitPrice})> lines,
  }) async =>
      [];
}

ProgramDetail _volumeDetail({
  ProgramStatus status = ProgramStatus.active,
  bool isLocked = false,
  DateTime? endedAt,
}) {
  return ProgramDetail(
    row: ProgramRow(
      id: 'prog-1',
      supplierId: 'sup-1',
      supplierName: 'NCC A',
      kind: ProgramKind.volumeRebate,
      name: 'Mốc 1.000 hộp Q4',
      status: status,
      startedOn: DateTime.utc(2026, 11, 10),
      productIds: const ['prod-1', 'prod-2'],
      productCount: 2,
      commonUom: 'hộp',
      tiers: const [],
      targetQty: 1000,
      rebatePercent: 5,
      progressQty: 400,
    ),
    note: 'Ghi chú Q4',
    revision: 1,
    isLocked: isLocked,
    endedAt: endedAt,
    products: const [
      ProgramProduct(
        productId: 'prod-1',
        name: 'Nobivac DHPPi',
        code: 'NBV-01',
        baseUom: 'hộp',
      ),
      ProgramProduct(
        productId: 'prod-2',
        name: 'Nobivac Rabies',
        code: 'NBV-02',
        baseUom: 'hộp',
      ),
    ],
    receipts: const [],
    baseAmountVnd: 40000000,
  );
}

ProgramDetail _tierDetail() {
  return ProgramDetail(
    row: ProgramRow(
      id: 'prog-2',
      supplierId: 'sup-1',
      supplierName: 'NCC A',
      kind: ProgramKind.tierDiscount,
      name: 'Nobivac bậc SL',
      status: ProgramStatus.active,
      startedOn: DateTime.utc(2026, 11, 10),
      productIds: const ['prod-1'],
      productCount: 1,
      commonUom: 'hộp',
      tiers: const [
        ProgramTier(minQty: 100, discountPercent: 3),
        ProgramTier(minQty: 300, discountPercent: 5),
      ],
      progressQty: 0,
    ),
    revision: 1,
    isLocked: false,
    products: const [
      ProgramProduct(
        productId: 'prod-1',
        name: 'Nobivac DHPPi',
        code: 'NBV-01',
        baseUom: 'hộp',
      ),
    ],
    receipts: const [],
    baseAmountVnd: 0,
  );
}

void main() {
  late _FakeSupplierProgramRepository fakeRepo;

  setUp(() async {
    await getIt.reset();
    fakeRepo = _FakeSupplierProgramRepository(detail: _volumeDetail());
    getIt.registerSingleton<SupplierProgramRepository>(fakeRepo);
  });

  tearDown(() async {
    await getIt.reset();
  });

  Widget buildApp({
    String programId = 'prog-1',
    Size size = const Size(390, 844),
  }) {
    useInventoryTestSurface(size);
    final router = GoRouter(
      initialLocation: '/warehouse/supplier-programs/$programId',
      routes: [
        GoRoute(
          path: '/warehouse/supplier-programs',
          builder: (_, _) => const Scaffold(body: Text('LIST_PAGE')),
        ),
        GoRoute(
          path: '/warehouse/supplier-programs/:id',
          builder: (_, state) => ProgramDetailPage(
            programId: state.pathParameters['id']!,
          ),
        ),
        GoRoute(
          path: '/warehouse/supplier-programs/:id/edit',
          builder: (_, state) => Scaffold(
            body: Text('EDIT:${state.pathParameters['id']}'),
          ),
        ),
        GoRoute(
          path: '/partner/:id',
          builder: (_, state) => Scaffold(
            body: Text('PARTNER:${state.pathParameters['id']}'),
          ),
        ),
        GoRoute(
          path: '/warehouse/stock/:productId',
          builder: (_, state) => Scaffold(
            body: Text('STOCK:${state.pathParameters['productId']}'),
          ),
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

  group('ProgramDetailPage', () {
    testWidgets('volume_active_390', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      expect(find.text('Mốc 1.000 hộp Q4'), findsWidgets);
      expect(find.text('Đang chạy'), findsOneWidget);
      expect(find.text('Tiến độ'), findsOneWidget);
      expect(find.text('400 / 1.000 hộp'), findsOneWidget);
      expect(find.text('Căn cứ chiết khấu'), findsOneWidget);
      expect(find.text('40.000.000 đ'), findsOneWidget);
      expect(find.text('Phiếu đã tính: Chưa có phiếu nhận.'), findsOneWidget);
      expect(find.text('Kết thúc chương trình'), findsOneWidget);
      expect(find.text('Sửa'), findsOneWidget);

      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile(_goldenPath('flutter-P3-VOLUME-390.png')),
      );
    });

    testWidgets('tier_shows_tier_table_390', (tester) async {
      fakeRepo.detail = _tierDetail();
      await tester.pumpWidget(buildApp(programId: 'prog-2'));
      await tester.pumpAndSettle();

      expect(find.text('Tiến độ'), findsNothing);
      expect(find.text('Bậc giảm giá'), findsOneWidget);
      expect(find.text('Từ 100 hộp'), findsOneWidget);
      expect(find.text('3%'), findsOneWidget);
      expect(find.text('Từ 300 hộp'), findsOneWidget);
      expect(find.text('5%'), findsOneWidget);
    });

    testWidgets('reached_banner_390', (tester) async {
      fakeRepo.detail = _volumeDetail(status: ProgramStatus.reached);
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      expect(
        find.text('Đã đạt mốc, chờ ghi nhận chiết khấu'),
        findsOneWidget,
      );
    });

    testWidgets('ended_no_footer_390', (tester) async {
      fakeRepo.detail = _volumeDetail(
        status: ProgramStatus.ended,
        endedAt: DateTime.utc(2026, 11, 15),
      );
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      expect(find.text('Kết thúc'), findsWidgets);
      expect(find.text('15/11/2026'), findsOneWidget);
      expect(find.text('Kết thúc chương trình'), findsNothing);
      expect(find.text('Sửa'), findsNothing);
    });

    testWidgets('locked_end_only_390', (tester) async {
      fakeRepo.detail = _volumeDetail(isLocked: true);
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      expect(find.text('Kết thúc chương trình'), findsOneWidget);
      expect(find.text('Sửa'), findsNothing);
    });

    testWidgets('end_confirm_flow', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Kết thúc chương trình'));
      await tester.pumpAndSettle();

      expect(
        find.text('Kết thúc chương trình "Mốc 1.000 hộp Q4"?'),
        findsOneWidget,
      );
      expect(
        find.text(
          'Phiếu nhận sau sẽ không áp ưu đãi này nữa. Không mở lại được.',
        ),
        findsOneWidget,
      );

      await tester.tap(find.text('Kết thúc'));
      await tester.pumpAndSettle();

      expect(fakeRepo.endCallCount, 1);
      expect(find.text('Kết thúc'), findsWidgets);
      expect(find.text('Kết thúc chương trình'), findsNothing);
    });

    testWidgets('end_cancel_no_call', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Kết thúc chương trình'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Huỷ'));
      await tester.pumpAndSettle();

      expect(fakeRepo.endCallCount, 0);
      expect(find.text('Đang chạy'), findsOneWidget);
    });

    testWidgets('supplier_row_opens_partner', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      await tester.tap(find.text('NCC A'));
      await tester.pumpAndSettle();

      expect(find.text('PARTNER:sup-1'), findsOneWidget);
    });

    testWidgets('product_row_opens_stock', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Nobivac DHPPi'));
      await tester.pumpAndSettle();

      expect(find.text('STOCK:prod-1'), findsOneWidget);
    });

    testWidgets('not_found_390', (tester) async {
      fakeRepo.getError = const AppException(InventoryErrorCode.contextInvalid);
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      expect(find.text('Không tìm thấy chương trình'), findsOneWidget);
      expect(find.text('Về danh sách'), findsOneWidget);
    });

    testWidgets('detail_1280_max_720', (tester) async {
      await tester.pumpWidget(buildApp(size: const Size(1280, 900)));
      await tester.pumpAndSettle();

      expect(find.byType(VContentWidth), findsWidgets);

      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile(_goldenPath('flutter-P3-VOLUME-1280.png')),
      );
    });
  });
}
