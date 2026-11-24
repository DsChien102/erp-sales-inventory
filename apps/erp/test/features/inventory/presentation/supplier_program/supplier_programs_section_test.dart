import 'dart:io';

import 'package:erp/core/di/injection.dart';
import 'package:erp/core/errors/app_exception.dart';
import 'package:erp/features/inventory/data/core/inventory_error_codes.dart';
import 'package:erp/features/inventory/data/supplier_program/supplier_program_models.dart';
import 'package:erp/features/inventory/data/supplier_program/supplier_program_repository.dart';
import 'package:erp/features/inventory/presentation/supplier_program/supplier_programs_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:c45_design_system/design_system.dart';

import '../../support/inventory_test_surface.dart';

String _goldenPath(String fileName) {
  final root = Directory.current.path.endsWith('apps/erp')
      ? Directory.current.parent.parent.path
      : Directory.current.path;
  return '$root/docs/refactor/plans/T7/img/G5-2b/$fileName';
}

class _FakeSupplierProgramRepository implements SupplierProgramRepository {
  List<ProgramRow> rows = const [];
  AppException? listError;

  _FakeSupplierProgramRepository();

  @override
  Future<List<ProgramRow>> list() async {
    if (listError != null) throw listError!;
    return rows;
  }

  @override
  Future<ProgramDetail> get(String id) async => throw UnimplementedError();

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
      [];
}

void main() {
  late _FakeSupplierProgramRepository fakeRepo;

  setUp(() async {
    await getIt.reset();
    fakeRepo = _FakeSupplierProgramRepository();
    getIt.registerSingleton<SupplierProgramRepository>(fakeRepo);
  });

  tearDown(() async {
    await getIt.reset();
  });

  Widget buildApp({
    String partnerId = 'sup-1',
    Size size = const Size(390, 844),
  }) {
    useInventoryTestSurface(size);
    final router = GoRouter(
      initialLocation: '/partner/$partnerId',
      routes: [
        GoRoute(
          path: '/partner/:id',
          builder: (_, state) => Scaffold(
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const Text('PARTNER_HEADER'),
                  SupplierProgramsSection(
                    partnerId: state.pathParameters['id']!,
                  ),
                ],
              ),
            ),
          ),
        ),
        GoRoute(
          path: '/warehouse/supplier-programs',
          builder: (_, state) => Scaffold(
            body: Text(
              'LIST:${state.uri.queryParameters['supplierId'] ?? ''}',
            ),
          ),
        ),
        GoRoute(
          path: '/warehouse/supplier-programs/new',
          builder: (_, state) => Scaffold(
            body: Text(
              'NEW:${state.uri.queryParameters['supplierId'] ?? ''}',
            ),
          ),
        ),
        GoRoute(
          path: '/warehouse/supplier-programs/:id',
          builder: (_, state) => Scaffold(
            body: Text('DETAIL:${state.pathParameters['id']}'),
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

  group('SupplierProgramsSection', () {
    testWidgets('section_shows_effective_program', (tester) async {
      fakeRepo.rows = [
        ProgramRow(
          id: 'prog-1',
          name: 'Mốc 1.000 hộp Q4',
          supplierId: 'sup-1',
          supplierName: 'NCC A',
          kind: ProgramKind.volumeRebate,
          status: ProgramStatus.active,
          startedOn: DateTime.utc(2026, 11, 10),
          productIds: const ['prod-1'],
          productCount: 1,
          commonUom: 'hộp',
          tiers: const [],
          targetQty: 1000,
          rebatePercent: 5,
          progressQty: 400,
        ),
        ProgramRow(
          id: 'prog-ended',
          name: 'Đã đóng',
          supplierId: 'sup-1',
          supplierName: 'NCC A',
          kind: ProgramKind.tierDiscount,
          status: ProgramStatus.ended,
          startedOn: DateTime.utc(2026, 10, 1),
          productIds: const ['prod-1'],
          productCount: 1,
          commonUom: 'hộp',
          tiers: const [ProgramTier(minQty: 10, discountPercent: 2)],
          progressQty: 0,
        ),
      ];

      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      expect(find.text('Chương trình ưu đãi'), findsOneWidget);
      expect(find.text('Mốc 1.000 hộp Q4'), findsOneWidget);
      expect(find.text('Chiết khấu đạt mốc'), findsOneWidget);
      expect(find.text('400 / 1.000 hộp'), findsOneWidget);
      expect(find.text('Đã đóng'), findsNothing);

      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile(_goldenPath('flutter-NCC-SECTION-390.png')),
      );
    });

    testWidgets('section_empty_create_link', (tester) async {
      fakeRepo.rows = const [];

      await tester.pumpWidget(buildApp(partnerId: 'sup-1'));
      await tester.pumpAndSettle();

      expect(find.text('Chưa có chương trình đang chạy.'), findsOneWidget);
      await tester.tap(find.text('Tạo chương trình'));
      await tester.pumpAndSettle();

      expect(find.text('NEW:sup-1'), findsOneWidget);
    });

    testWidgets('section_view_all_link', (tester) async {
      fakeRepo.rows = const [];

      await tester.pumpWidget(buildApp(partnerId: 'sup-1'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Xem tất cả'));
      await tester.pumpAndSettle();

      expect(find.text('LIST:sup-1'), findsOneWidget);
    });

    testWidgets('section_error_does_not_block', (tester) async {
      fakeRepo.listError =
          const AppException(InventoryErrorCode.contextInvalid);

      await tester.pumpWidget(buildApp(partnerId: 'sup-1'));
      await tester.pumpAndSettle();

      expect(find.text('PARTNER_HEADER'), findsOneWidget);
      expect(
        find.text('Không tải được chương trình ưu đãi.'),
        findsOneWidget,
      );
      expect(find.text('Thử lại'), findsOneWidget);
    });
  });
}
