import 'package:erp/core/di/injection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vet45_catalog_application/testing.dart';

import '../../catalog_e2e_harness.dart';

void main() {
  setUp(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  tearDown(() async {
    await getIt.reset();
  });

  testWidgets('e2e_e02_u03_fr01_01: post-create PCC shows readiness blockers', (tester) async {
    await setUpErpCatalogE2E();

    await tester.pumpWidget(buildCatalogPostCreateRouter());
    await tester.pumpAndSettle();

    await createMinimalProduct(tester, name: 'Thuốc A');

    expect(find.byKey(const Key('wgt_e02_u03_fr01_01')), findsOneWidget);
    expect(find.textContaining('Cần bổ sung'), findsOneWidget);
    expect(find.text('Thiếu dữ liệu'), findsOneWidget);
    expect(find.text('Tồn kho'), findsWidgets);
  });

  testWidgets('e2e_e02_u03_fr02_04: successful create navigates to PCC with product name',
      (tester) async {
    await setUpErpCatalogE2E();

    await tester.pumpWidget(buildCatalogPostCreateRouter());
    await tester.pumpAndSettle();

    await createMinimalProduct(tester, name: 'Amoxicillin 500mg');

    expect(find.byKey(const Key('wgt_e02_u03_fr01_01')), findsOneWidget);
    expect(find.text('Amoxicillin 500mg'), findsWidgets);
    expect(find.byKey(const Key('wgt_e02_u01_fr01_01')), findsNothing);
  });

  testWidgets('e2e_e02_u03_fr02_04: failed create stays on guided create form', (tester) async {
    await setUpErpCatalogE2E();

    await tester.pumpWidget(buildCatalogPostCreateRouter());
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('btn_guided_save')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('wgt_e02_u01_fr01_01')), findsOneWidget);
    expect(find.byKey(const Key('wgt_e02_u03_fr01_01')), findsNothing);
    expect(find.text('Vui lòng nhập tên nội bộ sản phẩm.'), findsOneWidget);
  });

  testWidgets('e2e_e02_u03_fr03_01: checklist shows base unit blocker and CTA', (tester) async {
    await setUpErpCatalogE2E(scenario: FakeCatalogScenario.readinessManyBlockers);

    await tester.pumpWidget(buildCatalogPostCreateRouter());
    await tester.pumpAndSettle();

    await createMinimalProduct(tester, name: 'Thuốc B');

    expect(find.byKey(const Key('btn_readiness_checklist_banner')), findsOneWidget);
    await tester.tap(find.byKey(const Key('btn_readiness_checklist_banner')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('wgt_e02_u03_checklist')), findsOneWidget);
    expect(find.text('Thiếu đơn vị cơ sở'), findsOneWidget);
    expect(find.text('Thiết lập đơn vị'), findsOneWidget);
  });

  testWidgets('e2e_e02_u03_fr04_01: readiness refresh drops base unit blocker after create',
      (tester) async {
    await setUpErpCatalogE2E(scenario: FakeCatalogScenario.readinessRefreshAfterUnit);

    await tester.pumpWidget(buildCatalogPostCreateRouter());
    await tester.pumpAndSettle();

    await createMinimalProduct(tester, name: 'Thuốc C', baseUnit: 'Lọ');

    expect(find.byKey(const Key('btn_readiness_checklist_banner')), findsOneWidget);
    await tester.tap(find.byKey(const Key('btn_readiness_checklist_banner')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('wgt_e02_u03_checklist')), findsOneWidget);
    expect(find.text('Thiếu đơn vị cơ sở'), findsNothing);
    expect(find.text('Thiếu khung giá bán'), findsOneWidget);
  });

  testWidgets('e2e_e02_u03_fr01_05: ready to sell product shows success badge without banner',
      (tester) async {
    await setUpErpCatalogE2E(scenario: FakeCatalogScenario.readinessReadyToSell);

    await tester.pumpWidget(buildCatalogPostCreateRouter());
    await tester.pumpAndSettle();

    await createMinimalProduct(tester, name: 'Thuốc D', baseUnit: 'Lọ');

    expect(find.byKey(const Key('wgt_e02_u03_fr01_01')), findsOneWidget);
    expect(find.text('Sẵn sàng bán'), findsOneWidget);
    expect(find.text('Thiếu tồn kho'), findsNothing);
    expect(find.text('Thiếu khung giá bán'), findsNothing);
    expect(find.text('Thiếu giá'), findsNothing);
  });
}
