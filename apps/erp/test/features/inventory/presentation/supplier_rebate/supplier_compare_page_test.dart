import 'package:erp/core/di/injection.dart';
import 'package:erp/features/inventory/data/supplier_program/supplier_program_models.dart';
import 'package:erp/features/inventory/data/supplier_rebate/supplier_rebate_models.dart';
import 'package:erp/features/inventory/data/supplier_rebate/supplier_rebate_repository.dart';
import 'package:erp/features/inventory/presentation/supplier_rebate/supplier_compare_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:vet45_design_system/design_system.dart';

import '../../support/inventory_test_surface.dart';

class _FakeSupplierRebateRepository implements SupplierRebateRepository {
  SupplierCompare response;

  _FakeSupplierRebateRepository(this.response);

  @override
  Future<SupplierCompare> compareSuppliers(String productId) async => response;

  @override
  Future<RebatePreview> preview({required String programId, int? amountVnd}) {
    throw UnimplementedError();
  }

  @override
  Future<RebateRecordResult> record({
    required String idempotencyKey,
    required String programId,
    required String documentNo,
    required DateTime documentDate,
    required int amountVnd,
    String? overrideReason,
  }) {
    throw UnimplementedError();
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
}

SupplierCompare _compareRows() {
  return SupplierCompare(
    productId: 'P',
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
        program: ProgramRow(
          id: 'prog-1',
          supplierId: 'A',
          supplierName: 'NCC A',
          kind: ProgramKind.volumeRebate,
          name: 'Mốc 1.000 hộp Q4',
          status: ProgramStatus.reached,
          startedOn: DateTime(2026, 11, 1),
          productIds: const ['P'],
          productCount: 1,
          commonUom: 'hộp',
          tiers: const [],
          targetQty: 1000,
          rebatePercent: 5,
          progressQty: 1000,
        ),
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
        freeQty: 1,
      ),
      SupplierCompareRow(
        partnerId: 'SYS',
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

void main() {
  late _FakeSupplierRebateRepository fakeRebates;

  setUp(() async {
    await getIt.reset();
    fakeRebates = _FakeSupplierRebateRepository(_compareRows());
    getIt.registerSingleton<SupplierRebateRepository>(fakeRebates);
  });

  tearDown(() async {
    await getIt.reset();
  });

  Widget buildApp({
    String productId = 'P',
    Size size = const Size(390, 844),
    void Function(String uri)? onNavigated,
  }) {
    useInventoryTestSurface(size);
    final router = GoRouter(
      initialLocation: '/warehouse/stock/$productId/suppliers',
      routes: [
        GoRoute(
          path: '/warehouse/stock/:productId/suppliers',
          builder: (_, state) => SupplierComparePage(
            productId: state.pathParameters['productId']!,
          ),
        ),
        GoRoute(
          path: '/warehouse/supplier-programs/new',
          builder: (_, state) {
            onNavigated?.call(state.uri.toString());
            return Scaffold(body: Text('NEW:${state.uri}'));
          },
        ),
        GoRoute(
          path: '/warehouse/supplier-programs/:programId',
          builder: (_, state) {
            onNavigated?.call(state.uri.toString());
            return Scaffold(body: Text('P3:${state.pathParameters['programId']}'));
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

  group('SupplierComparePage', () {
    testWidgets('compare_390', (tester) async {
      await tester.pumpWidget(buildApp(size: const Size(390, 844)));
      await tester.pumpAndSettle();

      expect(find.text('So sánh nhà cung cấp'), findsOneWidget);
      expect(find.text('Nobivac DHPPi'), findsOneWidget);

      final nccATop = tester.getTopLeft(find.text('NCC A')).dy;
      final sysTop = tester.getTopLeft(find.text('Mua lẻ / khác')).dy;
      expect(nccATop, lessThan(sysTop));

      expect(find.text('Rẻ nhất'), findsOneWidget);
      expect(find.text('Giá gốc gần nhất'), findsWidgets);
      expect(find.text('97.200 đ/hộp'), findsOneWidget);
      expect(find.text('2 lần nhập · mua 1.000 · tặng 0 hộp'), findsOneWidget);
      expect(find.text('Thêm ưu đãi'), findsOneWidget); // Chỉ ở B, không ở SYS
    });

    testWidgets('compare_1280', (tester) async {
      await tester.pumpWidget(buildApp(size: const Size(1280, 800)));
      await tester.pumpAndSettle();

      expect(find.text('SL MUA / TẶNG'), findsOneWidget);
      expect(find.text('NHÀ CUNG CẤP'), findsOneWidget);
      expect(find.text('Rẻ nhất'), findsOneWidget);
      expect(find.text('97.200 đ/hộp'), findsOneWidget);
      expect(find.text('Mua lẻ / khác'), findsOneWidget);
      expect(find.text('Thêm ưu đãi'), findsOneWidget); // Chỉ ở B
    });

    testWidgets('compare_add_offer', (tester) async {
      fakeRebates.response = SupplierCompare(
        productId: 'P',
        name: 'Nobivac DHPPi',
        code: 'NBV-01',
        uom: 'hộp',
        financialMasked: false,
        suppliers: [
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
          SupplierCompareRow(
            partnerId: 'C',
            name: 'NCC Khác SP',
            isSystem: false,
            lastLandedUnitCost: 105000,
            lastReceivedOn: DateTime(2026, 11, 1),
            avgLandedUnitCost: 105000,
            receiptCount: 1,
            paidQty: 5,
            freeQty: 0,
            otherProgram: (id: 'prog-other', name: 'Ưu đãi tháng 11'),
          ),
        ],
      );

      String? navigated;
      await tester.pumpWidget(buildApp(onNavigated: (u) => navigated = u));
      await tester.pumpAndSettle();

      expect(find.text('Ưu đãi: Không có'), findsOneWidget);
      expect(find.text('Thêm ưu đãi'), findsOneWidget);
      expect(
        find.text('Đang có chương trình khác: Ưu đãi tháng 11'),
        findsOneWidget,
      );

      await tester.tap(find.text('Thêm ưu đãi'));
      await tester.pumpAndSettle();
      expect(
        navigated,
        '/warehouse/supplier-programs/new?supplierId=B&productId=P',
      );
    });

    testWidgets('compare_staff_masked_390', (tester) async {
      fakeRebates.response = SupplierCompare(
        productId: 'P',
        name: 'Nobivac DHPPi',
        code: 'NBV-01',
        uom: 'hộp',
        financialMasked: true,
        suppliers: [
          SupplierCompareRow(
            partnerId: 'A',
            name: 'NCC A',
            isSystem: false,
            receiptCount: 2,
            paidQty: 1000,
            freeQty: 0,
          ),
          SupplierCompareRow(
            partnerId: 'B',
            name: 'Cty Á Châu',
            isSystem: false,
            receiptCount: 1,
            paidQty: 10,
            freeQty: 1,
          ),
        ],
      );

      await tester.pumpWidget(buildApp(size: const Size(390, 844)));
      await tester.pumpAndSettle();

      expect(find.text('Rẻ nhất'), findsNothing);
      expect(find.text('—'), findsNWidgets(4));
    });

    testWidgets('compare_empty', (tester) async {
      fakeRebates.response = const SupplierCompare(
        productId: 'P',
        name: 'Nobivac DHPPi',
        code: 'NBV-01',
        uom: 'hộp',
        financialMasked: false,
        suppliers: [],
      );

      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      expect(
        find.text('Chưa nhập sản phẩm này từ nhà cung cấp nào.'),
        findsOneWidget,
      );
    });
  });
}

