import 'package:erp/features/catalog/presentation/pages/product_control_center_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:vet45_catalog_application/application.dart';
import 'package:vet45_catalog_application/testing.dart';
import 'package:vet45_shared_application/application.dart';
import 'package:vet45_shared_testing/shared_testing.dart';
import 'package:vet45_catalog_presentation/presentation.dart';
import 'package:vet45_shared_application/application.dart';

import 'package:erp/features/catalog/presentation/pages/product_price_bands_page.dart';
import 'package:erp/core/router/app_router.dart';

final class _FakeExecutionContext implements IExecutionContext {
  @override
  String get correlationId => 'test-correlation';

  @override
  Future<String> requireTenantId() async => 'tenant-1';

  @override
  Future<String> requireUserId() async => 'user-1';
}

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

  Widget buildTestableWidget({
    required FakeCatalogModule catalogModule,
    required ProductListItemModel product,
  }) {
    getIt
      ..registerSingleton<IExecutionContext>(_FakeExecutionContext())
      ..registerSingleton<ICatalogModule>(catalogModule)
      ..registerSingleton<IModuleMediator>(FakeModuleMediator(catalogModule: catalogModule));

    final router = GoRouter(
      initialLocation: '/products/items/pcc',
      routes: [
        GoRoute(
          path: '/products/items/pcc',
          builder: (context, state) => ProductControlCenterPage(product: product),
        ),
        GoRoute(
          path: '/products/items/pcc/price-bands',
          builder: (context, state) {
            final args = state.extra as ProductPriceBandsRouteArgs;
            return ProductPriceBandsPage(args: args);
          },
        ),
      ],
    );

    return MaterialApp.router(routerConfig: router);
  }

  testWidgets('clicking price band section navigates to ProductPriceBandsPage',
      (tester) async {
    final catalogModule =
        FakeCatalogModule(scenario: FakeCatalogScenario.pccReadyToSell);
    final product = _sampleProduct(
      id: 'product-1',
      name: 'Amoxicillin 500mg',
    );

    await tester.pumpWidget(
      buildTestableWidget(catalogModule: catalogModule, product: product),
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
}

class FakeModuleMediator implements IModuleMediator {
  final FakeCatalogModule catalogModule;

  FakeModuleMediator({required this.catalogModule});

  @override
  Future<TResult> executeCommandAsync<TResult>(ICommand<TResult> command) async {
    throw UnimplementedError();
  }

  @override
  Future<TResult> executeQueryAsync<TResult>(IQuery<TResult> query) async {
    if (query is ListProductUnitPriceBandsQuery) {
      final q = query as ListProductUnitPriceBandsQuery;
      return ProductUnitPriceBandsDto(
        productId: q.productId,
        baseUnitName: 'Lọ',
        rows: [],
      ) as TResult;
    }
    throw UnimplementedError();
  }
}
