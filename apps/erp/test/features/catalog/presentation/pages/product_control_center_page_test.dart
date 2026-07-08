import 'package:erp/features/catalog/presentation/pages/product_control_center_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:vet45_catalog_application/application.dart';
import 'package:vet45_catalog_application/testing.dart';
import 'package:vet45_catalog_presentation/presentation.dart';
import 'package:vet45_shared_application/application.dart';

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
      ..registerSingleton<ICatalogModule>(catalogModule);

    final router = GoRouter(
      initialLocation: '/products/items/pcc',
      routes: [
        GoRoute(
          path: '/products/items/pcc',
          builder: (context, state) => ProductControlCenterPage(product: product),
        ),
      ],
    );

    return MaterialApp.router(routerConfig: router);
  }

  testWidgets('wgt_e01_u02_fr01_01: incomplete PCC shows operational cards',
      (tester) async {
    final catalogModule =
        FakeCatalogModule(scenario: FakeCatalogScenario.pccIncomplete);
    final product = _sampleProduct(
      id: 'product-4',
      name: 'Vitamin B Complex',
    );

    await tester.pumpWidget(
      buildTestableWidget(catalogModule: catalogModule, product: product),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('wgt_e01_u02_fr01_01')), findsOneWidget);
    expect(find.text('Vitamin B Complex'), findsWidgets);
    expect(find.text('Thiếu dữ liệu'), findsOneWidget);
    expect(find.text('Đơn vị đo lường'), findsOneWidget);
    expect(find.text('Tồn kho'), findsOneWidget);
    expect(find.text('Khung giá'), findsOneWidget);
    expect(find.textContaining('Chai'), findsWidgets);
    expect(find.textContaining('Thiếu khung giá'), findsOneWidget);
  });

  testWidgets('wgt_e01_u02_fr01_01: ready PCC shows success badge and stock',
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

    expect(find.byKey(const Key('wgt_e01_u02_fr01_01')), findsOneWidget);
    expect(find.text('Sẵn sàng bán'), findsOneWidget);
    expect(find.textContaining('Hộp'), findsWidgets);
    expect(find.textContaining('150'), findsWidgets);
  });

  testWidgets('wgt_e03_u02_fr01_01: custom field cards display in PCC',
      (tester) async {
    final catalogModule =
        FakeCatalogModule(scenario: FakeCatalogScenario.pccCustomFieldCards);
    final product = _sampleProduct(
      id: 'product-5',
      name: 'Thuốc bổ sung',
    );

    await tester.pumpWidget(
      buildTestableWidget(catalogModule: catalogModule, product: product),
    );
    await tester.pumpAndSettle();

    expect(find.text('Thuốc bổ sung'), findsWidgets);
    
    // Check if custom field group cards are displayed based on Fake data.
    // In FakeCatalogScenario.pccCustomFieldCards, there's a group "Thông tin thuốc"
    expect(find.text('Thông tin thuốc'), findsOneWidget);
    expect(find.textContaining('trường đã điền'), findsWidgets);
  });
}
