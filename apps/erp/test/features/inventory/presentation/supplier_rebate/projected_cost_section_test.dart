import 'package:erp/core/di/injection.dart';
import 'package:erp/core/errors/app_exception.dart';
import 'package:erp/features/inventory/data/supplier_program/supplier_program_models.dart';
import 'package:erp/features/inventory/data/supplier_rebate/supplier_rebate_models.dart';
import 'package:erp/features/inventory/data/supplier_rebate/supplier_rebate_repository.dart';
import 'package:erp/features/inventory/presentation/supplier_rebate/projected_cost_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vet45_design_system/design_system.dart';

import '../../support/inventory_test_surface.dart';

class _FakeProjectedRebateRepository implements SupplierRebateRepository {
  bool shouldThrow = false;
  int callCount = 0;

  @override
  Future<ProjectedCost> projectedCost({
    required String programId,
    required String productId,
    num? extraQty,
    num? unitPrice,
  }) async {
    callCount++;
    if (shouldThrow) {
      throw const AppException('NETWORK_ERROR');
    }
    final q = extraQty ?? 0;
    if (q >= 600) {
      return ProjectedCost(
        productId: productId,
        uom: 'hộp',
        progressQty: 400,
        targetQty: 1000,
        missingQty: 0,
        reachesTarget: true,
        rebateEstimate: 5000000,
        avgNow: 100000,
        avgProjected: 95000,
        defaultUnitPrice: 100000,
        financialMasked: false,
      );
    }
    if (q > 0) {
      final missing = (1000 - (400 + q)).clamp(0, 1000);
      return ProjectedCost(
        productId: productId,
        uom: 'hộp',
        progressQty: 400,
        targetQty: 1000,
        missingQty: missing,
        reachesTarget: false,
        rebateEstimate: null,
        avgNow: 100000,
        avgProjected: 100000,
        defaultUnitPrice: 100000,
        financialMasked: false,
      );
    }
    return ProjectedCost(
      productId: productId,
      uom: 'hộp',
      progressQty: 400,
      targetQty: 1000,
      missingQty: 600,
      reachesTarget: null,
      rebateEstimate: null,
      avgNow: 100000,
      avgProjected: 100000,
      defaultUnitPrice: 100000,
      financialMasked: false,
    );
  }

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
  Future<SupplierCompare> compareSuppliers(String productId) {
    throw UnimplementedError();
  }
}

void main() {
  late _FakeProjectedRebateRepository fakeRebates;

  setUp(() async {
    await getIt.reset();
    fakeRebates = _FakeProjectedRebateRepository();
    getIt.registerSingleton<SupplierRebateRepository>(fakeRebates);
  });

  tearDown(() async {
    await getIt.reset();
  });

  Widget wrap(Widget child) {
    useInventoryTestSurface(const Size(390, 844));
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: VTheme.lightTheme,
      home: MediaQuery(
        data: const MediaQueryData(size: Size(390, 844)),
        child: Scaffold(
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(VSpacing.space4),
            child: child,
          ),
        ),
      ),
    );
  }

  testWidgets('active_volume_shows_projection', (tester) async {
    await tester.pumpWidget(
      wrap(
        const ProjectedCostSection(
          programId: 'p1',
          products: [
            ProgramProduct(
              productId: 'prod-1',
              name: 'Nobivac DHPPi',
              code: 'NBV-01',
              baseUom: 'hộp',
            ),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Giá vốn dự kiến'), findsOneWidget);
    expect(find.text('Dự kiến, chưa ghi sổ'), findsOneWidget);
    expect(find.byType(VSelect<String>), findsNothing);

    await tester.enterText(find.byType(TextField).first, '600');
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();

    expect(find.text('Đạt mốc 1.000 hộp sau lần mua này'), findsOneWidget);
    expect(find.text('Chiết khấu ước tính'), findsOneWidget);
    expect(find.text('95.000 đ/hộp'), findsOneWidget);

    await tester.enterText(find.byType(TextField).first, '500');
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();

    expect(find.text('Còn thiếu 100 hộp để đạt mốc'), findsOneWidget);
    expect(find.text('Chiết khấu ước tính'), findsNothing);
  });

  testWidgets('projection_error_retry', (tester) async {
    fakeRebates.shouldThrow = true;

    await tester.pumpWidget(
      wrap(
        const ProjectedCostSection(
          programId: 'p1',
          products: [
            ProgramProduct(
              productId: 'prod-1',
              name: 'Nobivac DHPPi',
              code: 'NBV-01',
              baseUom: 'hộp',
            ),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Không tính được giá vốn dự kiến.'), findsOneWidget);
    expect(find.text('Thử lại'), findsOneWidget);

    fakeRebates.shouldThrow = false;
    await tester.tap(find.text('Thử lại'));
    await tester.pumpAndSettle();

    expect(find.text('Không tính được giá vốn dự kiến.'), findsNothing);
    expect(find.text('Bình quân hiện tại'), findsOneWidget);
  });
}
