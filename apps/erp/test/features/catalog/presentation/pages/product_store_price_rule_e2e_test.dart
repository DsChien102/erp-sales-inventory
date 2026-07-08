import 'package:erp/core/di/injection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vet45_catalog_application/testing.dart';
import 'package:vet45_catalog_presentation/presentation.dart';
import 'package:vet45_design_system/design_system.dart';

import '../../catalog_e2e_harness.dart';

ProductListItemModel _product1() {
  return const ProductListItemModel(
    id: 'product-1',
    name: 'Amoxicillin 500mg',
    businessStatus: ProductBusinessStatus.active,
    readinessStatus: ProductReadinessStatus.ready,
    baseUnit: 'Hộp',
  );
}

ProductListItemModel _product2() {
  return const ProductListItemModel(
    id: 'product-2',
    name: 'Paracetamol 500mg',
    businessStatus: ProductBusinessStatus.active,
    readinessStatus: ProductReadinessStatus.ready,
    baseUnit: 'Vỉ',
  );
}

ProductListItemModel _product4() {
  return const ProductListItemModel(
    id: 'product-4',
    name: 'Vitamin B Complex',
    businessStatus: ProductBusinessStatus.active,
    readinessStatus: ProductReadinessStatus.needsReview,
    baseUnit: 'Chai',
  );
}

ProductListItemModel _product7() {
  return const ProductListItemModel(
    id: 'product-7',
    name: 'Thuốc thiếu giá',
    businessStatus: ProductBusinessStatus.active,
    readinessStatus: ProductReadinessStatus.needsReview,
    baseUnit: 'Lọ',
  );
}

void main() {
  setUp(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  tearDown(() async {
    await getIt.reset();
  });

  testWidgets('e2e_e06_u02_fr02_01: editor shows store rule price suggestion', (tester) async {
    await setUpErpCatalogE2E();

    await tester.pumpWidget(buildPccPriceBandRouter(_product4()));
    await tester.pumpAndSettle();

    await openPriceBandEditor(tester);

    expect(find.byKey(const Key('wgt_e06_u02_fr02_01')), findsOneWidget);
    expect(find.byKey(const Key('wgt_e06_u02_fr03_01')), findsOneWidget);
    expect(find.textContaining('Mặc định bán lẻ'), findsWidgets);
    expect(find.textContaining('37.500 đ'), findsWidgets);
    expect(find.textContaining('31.250 đ'), findsWidgets);
  });

  testWidgets('e2e_e06_u02_fr02_02: cannot suggest without base price', (tester) async {
    await setUpErpCatalogE2E();

    await tester.pumpWidget(buildPccPriceBandRouter(_product7()));
    await tester.pumpAndSettle();

    await openPriceBandEditor(tester);

    expect(
      find.textContaining('Cần có Giá cơ sở định giá trước'),
      findsOneWidget,
    );

    final saveButton = tester.widget<VButton>(
      find.byKey(const Key('btn_price_band_save')),
    );
    expect(saveButton.onPressed, isNull);
  });

  testWidgets('e2e_e06_u02_fr02_03: inactive store rule disables save', (tester) async {
    await setUpErpCatalogE2E(scenario: FakeCatalogScenario.scnContractE06U02Fr02_03);

    await tester.pumpWidget(buildPccPriceBandRouter(_product4()));
    await tester.pumpAndSettle();

    await openPriceBandEditor(tester);

    expect(
      find.textContaining('Store Price Rule đang không hoạt động'),
      findsOneWidget,
    );

    final saveButton = tester.widget<VButton>(
      find.byKey(const Key('btn_price_band_save')),
    );
    expect(saveButton.onPressed, isNull);
  });

  testWidgets('e2e_e06_u02_fr03_01: apply store rule saves price band', (tester) async {
    await setUpErpCatalogE2E(scenario: FakeCatalogScenario.scnContractE06U02Fr03_01);

    await tester.pumpWidget(buildPccPriceBandRouter(_product4()));
    await tester.pumpAndSettle();

    expect(find.textContaining('Thiếu khung giá bán'), findsWidgets);

    await openPriceBandEditor(tester);
    await tester.tap(find.byKey(const Key('btn_price_band_save')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('wgt_e06_u02_fr02_01')), findsNothing);
    expect(find.textContaining('37.500 đ'), findsWidgets);
    expect(find.textContaining('31.250 đ'), findsWidgets);
    expect(find.textContaining('Thiếu khung giá bán'), findsNothing);
  });

  testWidgets('e2e_e06_u02_fr03_02: overwrite confirm dialog before applying rule', (tester) async {
    await setUpErpCatalogE2E(scenario: FakeCatalogScenario.scnContractE06U02Fr03_02);

    await tester.pumpWidget(buildPccPriceBandRouter(_product1()));
    await tester.pumpAndSettle();

    expect(find.textContaining('95.000 đ'), findsWidgets);

    await openPriceBandEditor(tester);
    await tester.tap(find.byKey(const Key('btn_price_band_save')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('dlg_price_band_overwrite')), findsOneWidget);

    await tester.tap(find.byKey(const Key('btn_price_band_overwrite_cancel')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('dlg_price_band_overwrite')), findsNothing);
    expect(find.byKey(const Key('wgt_e06_u02_fr02_01')), findsOneWidget);

    await tester.tap(find.byKey(const Key('btn_price_band_save')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('btn_price_band_overwrite_confirm')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('wgt_e06_u02_fr02_01')), findsNothing);
    expect(find.textContaining('100.000 đ'), findsWidgets);
  });

  testWidgets('e2e_e06_u02_fr04_01: PCC shows custom override label', (tester) async {
    await setUpErpCatalogE2E();

    await tester.pumpWidget(buildPccPriceBandRouter(_product2()));
    await tester.pumpAndSettle();

    expect(find.textContaining('Giá riêng'), findsWidgets);
    expect(find.textContaining('25.000 đ'), findsWidgets);
    expect(find.textContaining('18.000 đ'), findsWidgets);
  });
}
