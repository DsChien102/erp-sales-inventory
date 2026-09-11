import 'package:erp/core/di/injection.dart';
import 'package:erp/features/catalog/presentation/pages/product_control_center_page.dart';
import 'package:erp/features/catalog/presentation/pages/product_stock_adjustment_page.dart';
import 'package:erp/features/catalog/presentation/pages/product_note_edit_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:vet45_catalog_application/testing.dart';
import 'package:erp/features/catalog/presentation.dart';

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

Widget _buildPccRouter(ProductListItemModel product) {
  final router = GoRouter(
    initialLocation: '/products/items/pcc',
    routes: [
      GoRoute(
        path: '/products/items/pcc',
        builder: (context, state) => ProductControlCenterPage(product: product),
      ),
      GoRoute(
        path: '/products/items/pcc/stock',
        builder: (context, state) {
          final args = state.extra as ProductStockAdjustmentRouteArgs;
          return ProductStockAdjustmentPage(args: args);
        },
      ),
      GoRoute(
        path: '/products/items/pcc/note',
        builder: (context, state) {
          final args = state.extra as ProductNoteEditRouteArgs;
          return ProductNoteEditPage(args: args);
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

  testWidgets('e2e_e05_u01_fr01_01: PCC shows basic stock card with quantity', (tester) async {
    await setUpErpCatalogE2E(scenario: FakeCatalogScenario.pccReadyToSell);

    await tester.pumpWidget(buildCatalogDiscoveryRouter());
    await tester.pumpAndSettle();

    await tester.tap(find.textContaining('Amoxicillin 500mg'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('wgt_e01_u02_fr01_01')), findsOneWidget);
    expect(find.text('Tồn kho'), findsOneWidget);
    expect(find.textContaining('150 Hộp'), findsWidgets);
    expect(find.text('Sửa'), findsWidgets);
  });

  testWidgets('e2e_e05_u01_fr02_01: advanced stock does not open adjustment page', (tester) async {
    await setUpErpCatalogE2E(scenario: FakeCatalogScenario.readinessAdvancedStockPending);

    await tester.pumpWidget(buildCatalogPostCreateRouter());
    await tester.pumpAndSettle();

    await createMinimalProduct(tester, name: 'Thuốc Advanced Stock', baseUnit: 'Lọ');
    await tester.pumpAndSettle();

    expect(find.text('Tồn kho'), findsOneWidget);
    await tapEditStock(tester);

    expect(find.byKey(const Key('wgt_e05_u01_fr01_01')), findsNothing);
    expect(find.byKey(const Key('wgt_e02_u03_fr01_01')), findsOneWidget);
  });

  testWidgets('e2e_e05_u01_fr03_01: zero stock is configured not missing', (tester) async {
    await setUpErpCatalogE2E();

    await tester.pumpWidget(buildCatalogDiscoveryRouter());
    await tester.pumpAndSettle();

    await tester.tap(find.textContaining('Ceftriaxone 1g'));
    await tester.pumpAndSettle();

    expect(find.textContaining('0 Lọ'), findsWidgets);
    expect(find.text('Thiếu tồn kho'), findsNothing);
  });

  testWidgets('e2e_e05_u02_fr01_01: set initial stock from PCC', (tester) async {
    await setUpErpCatalogE2E();

    await tester.pumpWidget(buildCatalogPostCreateRouter());
    await tester.pumpAndSettle();

    await createMinimalProduct(tester, name: 'Thuốc mới', baseUnit: 'Hộp');
    await tester.pumpAndSettle();

    expect(find.textContaining('Thiếu tồn kho'), findsOneWidget);
    await tapEditStock(tester);

    expect(find.byKey(const Key('wgt_e05_u01_fr01_01')), findsOneWidget);
    expect(find.text('Chưa thiết lập'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('input_stock_quantity')), '30');
    await tester.pump();
    await tester.tap(find.byKey(const Key('btn_stock_save')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('wgt_e05_u01_fr01_01')), findsNothing);
    expect(find.textContaining('30 Hộp'), findsWidgets);
    expect(find.textContaining('Thiếu tồn kho'), findsNothing);
  });

  testWidgets('e2e_e05_u02_fr02_01: adjust existing stock with reason', (tester) async {
    await setUpErpCatalogE2E(scenario: FakeCatalogScenario.pccReadyToSell);

    await tester.pumpWidget(_buildPccRouter(_product1()));
    await tester.pumpAndSettle();

    expect(find.textContaining('150 Hộp'), findsWidgets);
    await tapEditStock(tester);

    expect(find.byKey(const Key('wgt_e05_u01_fr01_01')), findsOneWidget);
    expect(find.text('150 hộp'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('input_stock_quantity')), '25');
    await tester.pump();
    await tester.tap(find.text('Kiểm kê'));
    await tester.pump();
    await tester.tap(find.byKey(const Key('btn_stock_save')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('wgt_e05_u01_fr01_01')), findsNothing);
    expect(find.textContaining('25 Hộp'), findsWidgets);
  });

  testWidgets('e2e_e05_stock_rejects_fractional_quantity', (tester) async {
    await setUpErpCatalogE2E(scenario: FakeCatalogScenario.pccReadyToSell);

    await tester.pumpWidget(_buildPccRouter(_product1()));
    await tester.pumpAndSettle();

    await tapEditStock(tester);
    expect(find.byKey(const Key('wgt_e05_u01_fr01_01')), findsOneWidget);

    await tester.enterText(find.byKey(const Key('input_stock_quantity')), '1.5');
    await tester.pump();
    await tester.tap(find.byKey(const Key('btn_stock_save')));
    await tester.pump();

    expect(find.text('Tồn kho phải là số nguyên'), findsOneWidget);
    expect(find.byKey(const Key('wgt_e05_u01_fr01_01')), findsOneWidget);
  });

  testWidgets('e2e_e05_u02_fr04_01: readiness refreshes after setting stock', (tester) async {
    await setUpErpCatalogE2E();

    await tester.pumpWidget(buildCatalogPostCreateRouter());
    await tester.pumpAndSettle();

    await createMinimalProduct(tester, name: 'Thuốc readiness', baseUnit: 'Vỉ');
    await tester.pumpAndSettle();

    expect(find.text('Thiếu dữ liệu'), findsOneWidget);
    expect(find.textContaining('Thiếu tồn kho'), findsOneWidget);

    await tapEditStock(tester);
    await tester.enterText(find.byKey(const Key('input_stock_quantity')), '50');
    await tester.pump();
    await tester.tap(find.byKey(const Key('btn_stock_save')));
    await tester.pumpAndSettle();

    expect(find.textContaining('50 Vỉ'), findsWidgets);
    expect(find.textContaining('Thiếu tồn kho'), findsNothing);
  });

  testWidgets('e2e_note_edit: edit product note from PCC', (tester) async {
    await setUpErpCatalogE2E(scenario: FakeCatalogScenario.pccReadyToSell);

    await tester.pumpWidget(_buildPccRouter(_product1()));
    await tester.pumpAndSettle();

    // Verify PCC note section exists
    final noteCardFinder = find.text('Ghi chú');
    expect(noteCardFinder, findsOneWidget);
    
    // Tap on Ghi chú card
    await tester.ensureVisible(noteCardFinder);
    await tester.tap(noteCardFinder);
    await tester.pumpAndSettle();

    // Verify Note Edit page is shown
    expect(find.byKey(const Key('wgt_note_edit_page')), findsOneWidget);
    expect(find.text('Ghi chú riêng cho chính bạn. Không hiển thị cho khách hàng.'), findsOneWidget);

    // Enter note text
    await tester.enterText(find.byKey(const Key('input_product_note')), 'Ghi chu moi tu PCC');
    await tester.pump();

    // Verify character count updated
    expect(find.text('18/500'), findsOneWidget);

    // Tap Save
    await tester.tap(find.byKey(const Key('btn_note_save')));
    await tester.pumpAndSettle();

    // Note page pops and refreshes PCC.
    expect(find.byKey(const Key('wgt_note_edit_page')), findsNothing);
  });
}
