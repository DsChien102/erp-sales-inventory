import 'package:erp/features/catalog/presentation.dart';
import 'package:erp/features/catalog/presentation/pages/product_control_center_page.dart';
import 'package:erp/features/catalog/presentation/pages/product_price_bands_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

import '../../support/catalog_test_registry.dart';
import '../../support/fake_catalog_scenario.dart';

ProductListItemModel _sampleProduct({
  required String id,
  required String name,
}) {
  return ProductListItemModel(
    id: id,
    name: name,
    businessStatus: ProductBusinessStatus.active,
    readinessStatus: ProductReadinessStatus.needsReview,
  );
}

void main() {
  final getIt = GetIt.instance;

  setUp(() async {
    await getIt.reset();
  });

  tearDown(() async {
    await getIt.reset();
  });

  Widget buildTestableWidget({
    String scenario = FakeCatalogScenario.pccReadyToSell,
    required ProductListItemModel product,
  }) {
    registerFakeCatalog(getIt, scenario: scenario);

    final router = GoRouter(
      initialLocation: '/products/items/${product.id}',
      routes: [
        GoRoute(
          path: '/products/items/:productId',
          builder: (context, state) => ProductControlCenterPage(
            productId: state.pathParameters['productId']!,
            initialProduct: product,
          ),
        ),
        GoRoute(
          path: '/products/items/:productId/price-bands',
          builder: (context, state) {
            final args = state.extra as ProductPriceBandsRouteArgs;
            return ProductPriceBandsPage(args: args);
          },
        ),
      ],
    );

    return MaterialApp.router(routerConfig: router);
  }

  testWidgets('clicking price band section navigates to ProductPriceBandsPage', (tester) async {
    final product = _sampleProduct(
      id: 'product-1',
      name: 'Amoxicillin 500mg',
    );

    await tester.pumpWidget(
      buildTestableWidget(scenario: FakeCatalogScenario.pccReadyToSell, product: product),
    );
    await tester.pumpAndSettle();

    // Tap on the price band card
    final priceBandFinder = find.text('Khung giá');
    expect(priceBandFinder, findsWidgets);

    await tester.ensureVisible(priceBandFinder.first);
    await tester.pumpAndSettle();

    await tester.tap(priceBandFinder.first);
    await tester.pumpAndSettle();

    // Verify navigation
    expect(find.byType(ProductPriceBandsPage), findsOneWidget);
    expect(find.text('Khung giá bán'), findsOneWidget);
  });

  testWidgets('g5_price_bands_no_footer_last_row_visible', (tester) async {
    final product = _sampleProduct(
      id: 'product-1',
      name: 'Amoxicillin 500mg',
    );

    await tester.pumpWidget(
      buildTestableWidget(scenario: FakeCatalogScenario.pccReadyToSell, product: product),
    );
    await tester.pumpAndSettle();

    final priceBandFinder = find.text('Khung giá');
    await tester.ensureVisible(priceBandFinder.first);
    await tester.pumpAndSettle();
    await tester.tap(priceBandFinder.first);
    await tester.pumpAndSettle();

    expect(find.byType(ProductPriceBandsPage), findsOneWidget);
    expect(find.text('Thay đổi có áp dụng cho cửa hàng và kênh phân phối.'), findsNothing);
    expect(find.textContaining('Thay đổi có áp dụng cho cửa hàng'), findsNothing);
  });
}
