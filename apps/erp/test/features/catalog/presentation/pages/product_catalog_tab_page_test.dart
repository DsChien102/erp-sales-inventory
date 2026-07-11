import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:vet45_catalog_application/application.dart';
import 'package:vet45_catalog_application/testing.dart';
import 'package:vet45_shared_application/application.dart';
import 'package:erp/features/catalog/presentation/pages/product_catalog_tab_page.dart';
import 'package:go_router/go_router.dart';

final class _FakeExecutionContext implements IExecutionContext {
  @override
  String get correlationId => 'test-correlation';

  @override
  Future<String> requireTenantId() async => 'tenant-1';

  @override
  Future<String> requireUserId() async => 'user-1';
}

void main() {
  final getIt = GetIt.instance;

  setUp(() async {
    await getIt.reset();
  });

  Widget buildTestableWidget({required FakeCatalogModule catalogModule}) {
    getIt
      ..registerSingleton<IExecutionContext>(_FakeExecutionContext())
      ..registerSingleton<ICatalogModule>(catalogModule);

    final router = GoRouter(
      initialLocation: '/products',
      routes: [
        GoRoute(
          path: '/products',
          builder: (context, state) => const ProductCatalogTabPage(),
        ),
      ],
    );

    return MaterialApp.router(
      routerConfig: router,
    );
  }

  testWidgets('wgt_e01_u01_fr01_01: Render product list page and search bar', (tester) async {
    final catalogModule = FakeCatalogModule(scenario: FakeCatalogScenario.searchEmpty);

    await tester.pumpWidget(buildTestableWidget(catalogModule: catalogModule));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('wgt_e01_u01_fr01_01')), findsOneWidget);
    expect(
      find.text('Tìm tên, SKU, barcode, thông tin bổ sung...'),
      findsOneWidget,
    );
    expect(find.text('Chưa có sản phẩm nào được tạo'), findsOneWidget);
  });

  testWidgets('e2e_e01_u01_fr01_01: keyword search returns matching products', (
    tester,
  ) async {
    final catalogModule = FakeCatalogModule(
      scenario: FakeCatalogScenario.searchWithReadiness,
    );

    await tester.pumpWidget(buildTestableWidget(catalogModule: catalogModule));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('input_product_search')), findsOneWidget);

    await tester.enterText(find.byKey(const Key('input_product_search')), 'amox');
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pumpAndSettle();

    expect(find.textContaining('Amoxicillin'), findsWidgets);
  });
}

