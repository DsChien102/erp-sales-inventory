import 'package:erp/core/di/injection.dart';
import 'package:erp/features/catalog/presentation/pages/product_control_center_page.dart';
import 'package:erp/features/catalog/presentation/pages/product_manual_base_price_page.dart';
import 'package:erp/features/catalog/presentation/widgets/product_control_center_section_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:vet45_catalog_application/testing.dart';
import 'package:vet45_catalog_presentation/presentation.dart';

import '../../catalog_e2e_harness.dart';

ProductListItemModel _product7() {
  return const ProductListItemModel(
    id: 'product-7',
    name: 'Thuốc thiếu giá',
    businessStatus: ProductBusinessStatus.active,
    readinessStatus: ProductReadinessStatus.needsReview,
    baseUnit: 'Lọ',
  );
}

ProductListItemModel _product8() {
  return const ProductListItemModel(
    id: 'product-8',
    name: 'Thuốc giá vốn module',
    businessStatus: ProductBusinessStatus.active,
    readinessStatus: ProductReadinessStatus.needsReview,
    baseUnit: 'Lọ',
  );
}

Widget _buildPccRouter(ProductListItemModel product) {
  final router = GoRouter(
    initialLocation: '/products/items/pcc',
    routes: [
      GoRoute(
        path: '/products/items/pcc',
        builder: (context, state) => ProductControlCenterPage(product: product),
      ),
      GoRoute(
        path: '/products/items/pcc/manual-base-price',
        builder: (context, state) {
          final args = state.extra as ProductManualBasePriceRouteArgs;
          return ProductManualBasePricePage(
            product: args.product,
            basePriceCard: args.basePriceCard,
          );
        },
      ),
    ],
  );

  return MaterialApp.router(routerConfig: router);
}

void main() {
  setUp(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  tearDown(() async {
    await getIt.reset();
  });

  testWidgets('e2e_e06_u01_fr01_01: PCC shows manual base price card with amount', (tester) async {
    await setUpErpCatalogE2E(scenario: FakeCatalogScenario.pccReadyToSell);

    await tester.pumpWidget(buildCatalogDiscoveryRouter());
    await tester.pumpAndSettle();

    await tester.tap(find.textContaining('Amoxicillin 500mg'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('wgt_e01_u02_fr01_01')), findsOneWidget);
    expect(find.text('Giá cơ sở'), findsOneWidget);
    expect(find.textContaining('80.000 đ'), findsWidgets);
    expect(find.text('Sửa'), findsWidgets);
  });

  testWidgets('e2e_e06_u01_fr01_02: costing mode does not open manual base price page', (tester) async {
    await setUpErpCatalogE2E();

    await tester.pumpWidget(_buildPccRouter(_product8()));
    await tester.pumpAndSettle();

    await tapEditBasePrice(tester);

    expect(find.byKey(const Key('wgt_e06_u01_fr01_01')), findsNothing);
    expect(find.byKey(const Key('wgt_e01_u02_fr01_01')), findsOneWidget);
  });

  testWidgets('e2e_e06_u01_fr01_03: manual mode missing base price on card', (tester) async {
    await setUpErpCatalogE2E();

    await tester.pumpWidget(_buildPccRouter(_product7()));
    await tester.pumpAndSettle();

    expect(find.text('Giá cơ sở'), findsOneWidget);
    expect(find.textContaining('Thiếu Giá cơ sở định giá'), findsWidgets);
  });

  testWidgets('e2e_e06_u01_fr02_01: set manual base price from PCC', (tester) async {
    await setUpErpCatalogE2E(scenario: FakeCatalogScenario.scnContractE06U01Fr02_01);

    await tester.pumpWidget(_buildPccRouter(_product7()));
    await tester.pumpAndSettle();

    expect(find.textContaining('Thiếu Giá cơ sở định giá'), findsWidgets);
    await tapEditBasePrice(tester);

    expect(find.byKey(const Key('wgt_e06_u01_fr01_01')), findsOneWidget);
    expect(find.text('Giá vốn cơ sở'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('input_base_price_amount')), '45000');
    await tester.pump();
    await tester.tap(find.byKey(const Key('btn_manual_base_price_save')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('wgt_e06_u01_fr01_01')), findsNothing);
    expect(find.textContaining('45.000 đ'), findsWidgets);
    expect(find.textContaining('Thiếu Giá cơ sở định giá'), findsNothing);
  });

  testWidgets('e2e_e06_u01_fr02_02: missing base unit cannot open manual base price page', (tester) async {
    await setUpErpCatalogE2E();

    await tester.pumpWidget(_buildPccRouter(productWithoutBaseUnit()));
    await tester.pumpAndSettle();

    final basePriceCard = find.widgetWithText(ProductControlCenterSectionCard, 'Giá cơ sở');
    await tester.ensureVisible(basePriceCard);

    final editButton = find.descendant(
      of: basePriceCard,
      matching: find.widgetWithText(TextButton, 'Sửa'),
    );
    expect(editButton, findsOneWidget);

    final button = tester.widget<TextButton>(editButton);
    expect(button.onPressed, isNull);
    expect(find.byKey(const Key('wgt_e06_u01_fr01_01')), findsNothing);
  });

  testWidgets('e2e_e06_u01_fr04_01: readiness refreshes after setting base price', (tester) async {
    await setUpErpCatalogE2E();

    await tester.pumpWidget(buildCatalogPostCreateRouter());
    await tester.pumpAndSettle();

    await createMinimalProduct(tester, name: 'Thuốc readiness giá', baseUnit: 'Vỉ');
    await tester.pumpAndSettle();

    expect(find.textContaining('Thiếu Giá cơ sở định giá'), findsWidgets);

    await tapEditBasePrice(tester);
    await tester.enterText(find.byKey(const Key('input_base_price_amount')), '25000');
    await tester.pump();
    await tester.tap(find.byKey(const Key('btn_manual_base_price_save')));
    await tester.pumpAndSettle();

    expect(find.textContaining('25.000 đ'), findsWidgets);
    expect(find.textContaining('Thiếu Giá cơ sở định giá'), findsNothing);
  });
}
