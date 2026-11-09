import 'package:erp/features/catalog/data/models.dart';
import 'package:erp/features/catalog/data/product_price_repository.dart';
import 'package:erp/features/catalog/data/product_repository.dart';
import 'package:erp/features/catalog/presentation.dart';
import 'package:erp/features/catalog/presentation/pages/product_control_center_page.dart';
import 'package:erp/features/catalog/presentation/pages/product_note_edit_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:vet45_design_system/design_system.dart';

import '../../support/catalog_test_registry.dart';
import '../../support/fake_catalog_backend.dart';
import '../../support/fake_catalog_repositories.dart';
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

class _UpdateProfileCall {
  final String productId;
  final String productName;
  final String? commercialName;
  final String? sku;
  final String? barcode;
  final String? note;

  const _UpdateProfileCall({
    required this.productId,
    required this.productName,
    this.commercialName,
    this.sku,
    this.barcode,
    this.note,
  });
}

class _SpyProductRepository extends FakeProductRepository {
  _SpyProductRepository({required super.backend});

  final List<_UpdateProfileCall> updateProfileCalls = [];

  @override
  Future<void> updateProfile({
    required String productId,
    int? expectedVersion,
    required String productName,
    String? commercialName,
    String? sku,
    String? barcode,
    String? description,
    String? note,
    ProductTrackingMode? trackingMode,
    bool? expiryRequired,
  }) {
    updateProfileCalls.add(_UpdateProfileCall(
      productId: productId,
      productName: productName,
      commercialName: commercialName,
      sku: sku,
      barcode: barcode,
      note: note,
    ));
    return super.updateProfile(
      productId: productId,
      expectedVersion: expectedVersion,
      productName: productName,
      commercialName: commercialName,
      sku: sku,
      barcode: barcode,
      description: description,
      note: note,
      trackingMode: trackingMode,
      expiryRequired: expiryRequired,
    );
  }
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
    String scenario = FakeCatalogScenario.guidedCreateOk,
    FakeCatalogBackend? backend,
    required ProductListItemModel product,
  }) {
    if (!getIt.isRegistered<ProductRepository>()) {
      registerFakeCatalog(getIt, scenario: scenario, backend: backend);
    }

    final router = GoRouter(
      initialLocation: '/products/items/${product.id}',
      routes: [
        GoRoute(
          path: '/products/items/:productId',
          builder: (context, state) => ProductControlCenterPage(
            productId: product.id,
            initialProduct: product,
          ),
        ),
      ],
    );

    return MaterialApp.router(routerConfig: router);
  }

  testWidgets('wgt_e01_u02_fr01_01: incomplete PCC shows operational cards', (tester) async {
    final product = _sampleProduct(
      id: 'product-4',
      name: 'Vitamin B Complex',
    );

    await tester.pumpWidget(
      buildTestableWidget(scenario: FakeCatalogScenario.pccIncomplete, product: product),
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

  testWidgets('wgt_e01_u02_fr01_01: ready PCC shows success badge and stock', (tester) async {
    final product = _sampleProduct(
      id: 'product-1',
      name: 'Amoxicillin 500mg',
    );

    await tester.pumpWidget(
      buildTestableWidget(scenario: FakeCatalogScenario.pccReadyToSell, product: product),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('wgt_e01_u02_fr01_01')), findsOneWidget);
    expect(find.text('Sẵn sàng bán'), findsOneWidget);
    expect(find.textContaining('Hộp'), findsWidgets);
    expect(find.textContaining('150'), findsWidgets);
  });

  testWidgets('t93_sp04_banner_by_readiness', (tester) async {
    await tester.pumpWidget(
      buildTestableWidget(
        scenario: FakeCatalogScenario.pccIncomplete,
        product: _sampleProduct(id: 'product-4', name: 'Vitamin B Complex'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Thiếu dữ liệu'), findsOneWidget);
    expect(find.byKey(const Key('btn_readiness_checklist_banner')), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await getIt.reset();
    await tester.pumpWidget(
      buildTestableWidget(
        scenario: FakeCatalogScenario.pccReadyToSell,
        product: _sampleProduct(id: 'product-1', name: 'Amoxicillin 500mg'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Sẵn sàng bán'), findsOneWidget);
    expect(find.byKey(const Key('btn_readiness_checklist_banner')), findsNothing);
  });

  testWidgets('pending custom config waits for base price on PCC', (
    tester,
  ) async {
    registerFakeCatalog(getIt);
    final priceRepo = getIt<ProductPriceRepository>();
    await priceRepo.setUnitPriceBand(
      productId: 'product-7',
      sourceType: PriceBandSourceType.customConfig,
      listMarkupRatio: 0.30,
      floorMarkupRatio: 0.10,
    );

    await tester.pumpWidget(
      buildTestableWidget(
        product: _sampleProduct(
          id: 'product-7',
          name: 'Thuốc thiếu giá',
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Đã cấu hình – chờ Giá cơ sở'), findsOneWidget);
    expect(find.text('Giá niêm yết: --'), findsOneWidget);
  });

  testWidgets('wgt_e03_u02_fr01_01: custom field cards display in PCC', (tester) async {
    final product = _sampleProduct(
      id: 'product-5',
      name: 'Ibuprofen 400mg',
    );

    await tester.pumpWidget(
      buildTestableWidget(scenario: FakeCatalogScenario.pccCustomFieldCards, product: product),
    );
    await tester.pumpAndSettle();

    expect(find.text('Ibuprofen 400mg'), findsWidgets);

    // Check if custom field group cards are displayed based on Fake data.
    // In FakeCatalogScenario.pccCustomFieldCards, there's a group "Thông tin thuốc"
    expect(find.text('Thông tin thuốc'), findsOneWidget);
    expect(find.textContaining('trường đã điền'), findsWidgets);
  });

  testWidgets('PCC instantiated by productId alone loads DTO and displays product details', (tester) async {
    registerFakeCatalog(getIt, scenario: FakeCatalogScenario.pccReadyToSell);

    final router = GoRouter(
      initialLocation: '/products/items/product-1',
      routes: [
        GoRoute(
          path: '/products/items/:productId',
          builder: (context, state) => ProductControlCenterPage(
            productId: state.pathParameters['productId']!,
          ),
        ),
      ],
    );

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('wgt_e01_u02_fr01_01')), findsOneWidget);
    expect(find.text('Amoxicillin 500mg'), findsWidgets);
    expect(find.text('Sẵn sàng bán'), findsOneWidget);
  });

  testWidgets('w8_note_from_url_keeps_profile_fields: opens note without initialProduct and keeps profile fields on save', (tester) async {
    final backend = FakeCatalogBackend(scenario: FakeCatalogScenario.pccReadyToSell);
    registerFakeCatalog(getIt, scenario: FakeCatalogScenario.pccReadyToSell, backend: backend);
    final spyRepo = _SpyProductRepository(backend: backend);
    getIt.unregister<ProductRepository>();
    getIt.registerSingleton<ProductRepository>(spyRepo);

    final router = GoRouter(
      initialLocation: '/products/items/product-1',
      routes: [
        GoRoute(
          path: '/products/items/:productId',
          builder: (context, state) => ProductControlCenterPage(
            productId: state.pathParameters['productId']!,
          ),
          routes: [
            GoRoute(
              path: 'note',
              builder: (context, state) => ProductNoteEditPage(
                args: state.extra! as ProductNoteEditRouteArgs,
              ),
            ),
          ],
        ),
      ],
    );

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('wgt_e01_u02_fr01_01')), findsOneWidget);
    expect(find.text('Amoxicillin 500mg'), findsWidgets);

    // Scroll to Note section and tap
    await tester.ensureVisible(find.text('Ghi chú'));
    await tester.tap(find.text('Ghi chú'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('wgt_note_edit_page')), findsOneWidget);

    // Enter note text "n2"
    await tester.enterText(find.byKey(const Key('input_product_note')), 'n2');
    await tester.pumpAndSettle();

    // Tap Save
    await tester.tap(find.byKey(const Key('btn_note_save')));
    await tester.pumpAndSettle();

    expect(spyRepo.updateProfileCalls.length, 1);
    final call = spyRepo.updateProfileCalls.first;
    expect(call.productId, 'product-1');
    expect(call.productName, 'Amoxicillin 500mg');
    expect(call.commercialName, 'Amox 500');
    expect(call.sku, 'SP0001');
    expect(call.barcode, '8930000000001');
    expect(call.note, 'n2');
  });

  testWidgets('pcc_on_mutated_after_reload: calls onMutated on deactivate and on note save', (tester) async {
    registerFakeCatalog(getIt, scenario: FakeCatalogScenario.pccReadyToSell);

    var mutationCount = 0;

    final router = GoRouter(
      initialLocation: '/products/items/product-1',
      routes: [
        GoRoute(
          path: '/products/items/:productId',
          builder: (context, state) => ProductControlCenterPage(
            productId: state.pathParameters['productId']!,
            onMutated: () => mutationCount++,
          ),
          routes: [
            GoRoute(
              path: 'note',
              builder: (context, state) => ProductNoteEditPage(
                args: state.extra! as ProductNoteEditRouteArgs,
              ),
            ),
          ],
        ),
      ],
    );

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();
    expect(mutationCount, 0);

    // 1. Trigger deactivate
    await tester.ensureVisible(find.byKey(const Key('btn_product_lifecycle_danger_toggle')));
    await tester.tap(find.byKey(const Key('btn_product_lifecycle_danger_toggle')));
    await tester.pumpAndSettle();

    // Tap "Ngừng kinh doanh" action in danger section
    await tester.ensureVisible(find.text('Ngừng kinh doanh'));
    await tester.tap(find.text('Ngừng kinh doanh'));
    await tester.pumpAndSettle();

    // In confirmation sheet, tap "Ngừng kinh doanh" button
    final confirmBtn = find.widgetWithText(VButton, 'Ngừng kinh doanh');
    await tester.tap(confirmBtn);
    await tester.pumpAndSettle();

    expect(mutationCount, 1);

    // 2. Trigger note update
    await tester.ensureVisible(find.text('Ghi chú'));
    await tester.tap(find.text('Ghi chú'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('input_product_note')), 'n2');
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('btn_note_save')));
    await tester.pumpAndSettle();

    expect(mutationCount, 2);
  });
}
