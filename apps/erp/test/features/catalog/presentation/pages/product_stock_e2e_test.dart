import 'dart:async';

import 'package:erp/core/di/injection.dart';
import 'package:erp/features/catalog/data/product_repository.dart';
import 'package:erp/features/catalog/presentation/pages/product_control_center_page.dart';
import 'package:erp/features/catalog/presentation/pages/product_stock_adjustment_page.dart';
import 'package:erp/features/catalog/presentation/pages/product_note_edit_page.dart';
import 'package:erp/features/catalog/presentation/widgets/product_form_bottom_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:erp/features/catalog/presentation.dart';
import 'package:vet45_design_system/design_system.dart';

import '../../catalog_e2e_harness.dart';
import '../../support/fake_catalog_repositories.dart';

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
        path: '/products/items/:productId/stock',
        builder: (context, state) {
          final args = state.extra as ProductStockAdjustmentRouteArgs;
          return ProductStockAdjustmentPage(args: args);
        },
      ),
      GoRoute(
        path: '/products/items/:productId/note',
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
    expect(
      find.text('Ghi chú riêng cho chính bạn. Không hiển thị cho khách hàng.'),
      findsOneWidget,
    );

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

  group('5-C behavior', () {
    testWidgets('T0-1 adjust combines chip and note', (tester) async {
      await setUpErpCatalogE2E(scenario: FakeCatalogScenario.pccReadyToSell);
      await tester.pumpWidget(_buildPccRouter(_product1()));
      await tester.pumpAndSettle();

      await tapEditStock(tester);
      expect(find.byKey(const Key('wgt_e05_u01_fr01_01')), findsOneWidget);

      await tester.enterText(find.byKey(const Key('input_stock_quantity')), '147');
      await tester.pump();
      await tester.tap(find.text('Hao hụt'));
      await tester.pump();
      await tester.enterText(find.byType(TextField).last, 'vỡ 3 chai');
      await tester.pump();

      await tester.tap(find.byKey(const Key('btn_stock_save')));
      await tester.pumpAndSettle();

      final backend = (getIt<ProductRepository>() as FakeProductRepository).backend;
      final p = backend.products.firstWhere((prod) => prod.id == 'product-1');
      expect(p.stockQty, 147);
      expect(p.stockMovements.last.reason, 'Hao hụt - vỡ 3 chai');
      expect(p.stockMovements.last.quantityBefore, 150);
      expect(p.stockMovements.last.delta, -3);
    });

    testWidgets('T0-2 adjust note only', (tester) async {
      await setUpErpCatalogE2E(scenario: FakeCatalogScenario.pccReadyToSell);
      await tester.pumpWidget(_buildPccRouter(_product1()));
      await tester.pumpAndSettle();

      await tapEditStock(tester);
      await tester.enterText(find.byKey(const Key('input_stock_quantity')), '140');
      await tester.pump();
      await tester.enterText(find.byType(TextField).last, '  đếm lại  ');
      await tester.pump();

      await tester.tap(find.byKey(const Key('btn_stock_save')));
      await tester.pumpAndSettle();

      final backend = (getIt<ProductRepository>() as FakeProductRepository).backend;
      final p = backend.products.firstWhere((prod) => prod.id == 'product-1');
      expect(p.stockQty, 140);
      expect(p.stockMovements.last.reason, 'đếm lại');
    });

    testWidgets('T0-3 adjust no reason', (tester) async {
      await setUpErpCatalogE2E(scenario: FakeCatalogScenario.pccReadyToSell);
      await tester.pumpWidget(_buildPccRouter(_product1()));
      await tester.pumpAndSettle();

      await tapEditStock(tester);
      await tester.enterText(find.byKey(const Key('input_stock_quantity')), '151');
      await tester.pump();

      await tester.tap(find.byKey(const Key('btn_stock_save')));
      await tester.pumpAndSettle();

      final backend = (getIt<ProductRepository>() as FakeProductRepository).backend;
      final p = backend.products.firstWhere((prod) => prod.id == 'product-1');
      expect(p.stockQty, 151);
      expect(p.stockMovements.last.reason, isNull);
    });

    testWidgets('T0-4 adjust stale stays on page', (tester) async {
      await setUpErpCatalogE2E(scenario: FakeCatalogScenario.pccReadyToSell);
      await tester.pumpWidget(_buildPccRouter(_product1()));
      await tester.pumpAndSettle();

      await tapEditStock(tester);
      expect(find.byKey(const Key('wgt_e05_u01_fr01_01')), findsOneWidget);

      final backend = (getIt<ProductRepository>() as FakeProductRepository).backend;
      final p = backend.products.firstWhere((prod) => prod.id == 'product-1');
      p.stockQty = 140; // Máy khác vừa đổi

      await tester.enterText(find.byKey(const Key('input_stock_quantity')), '100');
      await tester.pump();
      await tester.tap(find.byKey(const Key('btn_stock_save')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byKey(const Key('wgt_e05_u01_fr01_01')), findsOneWidget);
      expect(p.stockQty, 140);
      expect(find.byType(VToast), findsOneWidget);
      expect(tester.widget<VToast>(find.byType(VToast)).title, 'Lỗi');
    });

    testWidgets('T0-5 no base unit shows S-01', (tester) async {
      await setUpErpCatalogE2E();
      await tester.pumpWidget(
        const MaterialApp(
          home: ProductStockAdjustmentPage(
            args: ProductStockAdjustmentRouteArgs(
              product: ProductListItemModel(
                id: 'p-x',
                name: 'Thuốc thiếu đơn vị',
                businessStatus: ProductBusinessStatus.active,
                readinessStatus: ProductReadinessStatus.needsReview,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.byWidgetPredicate(
          (w) => w is RichText && w.text.toPlainText().contains('trước khi thiết lập tồn kho'),
        ),
        findsOneWidget,
      );
      expect(find.text('Tồn kho được tính theo đơn vị cơ sở của sản phẩm.'), findsOneWidget);
      expect(find.byKey(const Key('input_stock_quantity')), findsNothing);
    });

    testWidgets('T0-6 negative rejected', (tester) async {
      await setUpErpCatalogE2E(scenario: FakeCatalogScenario.pccReadyToSell);
      await tester.pumpWidget(_buildPccRouter(_product1()));
      await tester.pumpAndSettle();

      await tapEditStock(tester);
      await tester.enterText(find.byKey(const Key('input_stock_quantity')), '-1');
      await tester.pump();
      await tester.tap(find.byKey(const Key('btn_stock_save')));
      await tester.pump();

      expect(find.text('Tồn kho không được âm'), findsOneWidget);
      final backend = (getIt<ProductRepository>() as FakeProductRepository).backend;
      final p = backend.products.firstWhere((prod) => prod.id == 'product-1');
      expect(p.stockQty, 150);
    });

    testWidgets('T0-7 save enabled only with changes', (tester) async {
      await setUpErpCatalogE2E(scenario: FakeCatalogScenario.pccReadyToSell);
      await tester.pumpWidget(_buildPccRouter(_product1()));
      await tester.pumpAndSettle();

      await tapEditStock(tester);
      expect(tester.widget<ProductFormBottomBar>(find.byType(ProductFormBottomBar)).saveEnabled, isFalse);

      await tester.tap(find.text('Kiểm kê'));
      await tester.pump();
      expect(tester.widget<ProductFormBottomBar>(find.byType(ProductFormBottomBar)).saveEnabled, isTrue);
    });

    testWidgets('T0-8 initial mode hides reason', (tester) async {
      await setUpErpCatalogE2E();
      await tester.pumpWidget(buildCatalogPostCreateRouter());
      await tester.pumpAndSettle();

      await createMinimalProduct(tester, name: 'Thuốc mới', baseUnit: 'Hộp');
      await tester.pumpAndSettle();

      await tapEditStock(tester);
      expect(find.text('Lý do'), findsNothing);
      expect(find.text('Kiểm kê'), findsNothing);
      expect(find.text('Chưa thiết lập'), findsOneWidget);
    });

    testWidgets('sp10_from_checklist_args_shows_form', (tester) async {
      await setUpErpCatalogE2E();
      await tester.pumpWidget(
        MaterialApp(
          home: ProductStockAdjustmentPage(
            args: ProductStockAdjustmentRouteArgs(product: _product1()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('input_stock_quantity')), findsOneWidget);
      expect(find.text('Tồn mới (Hộp)'), findsOneWidget);
    });

    testWidgets('sp10_stale_shows_64_message', (tester) async {
      await setUpErpCatalogE2E(scenario: FakeCatalogScenario.pccReadyToSell);
      await tester.pumpWidget(_buildPccRouter(_product1()));
      await tester.pumpAndSettle();

      await tapEditStock(tester);
      final backend = (getIt<ProductRepository>() as FakeProductRepository).backend;
      final p = backend.products.firstWhere((prod) => prod.id == 'product-1');
      p.stockQty = 140;

      await tester.enterText(find.byKey(const Key('input_stock_quantity')), '100');
      await tester.pump();
      await tester.tap(find.byKey(const Key('btn_stock_save')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(
        find.text('Tồn kho hiện tại đã thay đổi. Vui lòng tải lại dữ liệu trước khi điều chỉnh.'),
        findsOneWidget,
      );
    });

    testWidgets('sp10_labels_match_th02', (tester) async {
      await setUpErpCatalogE2E(scenario: FakeCatalogScenario.pccReadyToSell);
      await tester.pumpWidget(_buildPccRouter(_product1()));
      await tester.pumpAndSettle();

      await tapEditStock(tester);
      expect(find.text('Tồn hiện tại'), findsOneWidget);
      expect(find.text('Tồn mới (Hộp)'), findsOneWidget);
      expect(find.text('Lý do'), findsOneWidget);
    });

    testWidgets('sp10_rejects_thousand_separator', (tester) async {
      await setUpErpCatalogE2E(scenario: FakeCatalogScenario.pccReadyToSell);
      await tester.pumpWidget(_buildPccRouter(_product1()));
      await tester.pumpAndSettle();

      await tapEditStock(tester);
      final repo = getIt<ProductRepository>() as FakeProductRepository;
      await tester.enterText(find.byKey(const Key('input_stock_quantity')), '1,000');
      await tester.pump();
      await tester.tap(find.byKey(const Key('btn_stock_save')));
      await tester.pump();

      expect(find.text('Tồn kho phải là số nguyên'), findsOneWidget);
      final p = repo.backend.products.firstWhere((prod) => prod.id == 'product-1');
      expect(p.stockQty, 150);
      expect(repo.calls, isNot(contains('adjustBasicStock')));
    });

    testWidgets('sp10_footer_ki04', (tester) async {
      await setUpErpCatalogE2E(scenario: FakeCatalogScenario.pccReadyToSell);
      await tester.pumpWidget(_buildPccRouter(_product1()));
      await tester.pumpAndSettle();

      await tapEditStock(tester);
      final footerFinder = find.text('Thay đổi sẽ ghi vào Lịch sử thay đổi.');
      await tester.scrollUntilVisible(
        footerFinder,
        200,
        scrollable: find.byType(Scrollable).last,
      );
      expect(footerFinder, findsOneWidget);
      expect(find.textContaining('Growth'), findsNothing);
    });

    testWidgets('sp10_save_disabled_while_loading', (tester) async {
      await setUpErpCatalogE2E(scenario: FakeCatalogScenario.pccReadyToSell);
      final backend = (getIt<ProductRepository>() as FakeProductRepository).backend;
      final blockingRepo = _BlockingProductRepository(backend: backend);
      final completer = Completer<void>();
      blockingRepo.completer = completer;
      getIt.unregister<ProductRepository>();
      getIt.registerSingleton<ProductRepository>(blockingRepo);

      await tester.pumpWidget(_buildPccRouter(_product1()));
      await tester.pumpAndSettle();

      await tapEditStock(tester);
      await tester.enterText(find.byKey(const Key('input_stock_quantity')), '120');
      await tester.pump();

      await tester.tap(find.byKey(const Key('btn_stock_save')));
      await tester.pump(); // Start submission

      final bar = tester.widget<ProductFormBottomBar>(find.byType(ProductFormBottomBar));
      expect(bar.isLoading, isTrue);
      expect(bar.onCancel, isNull);

      // Tap save second time
      await tester.tap(find.byKey(const Key('btn_stock_save')));
      await tester.pump();
      expect(blockingRepo.stockCalls.length, 1);

      // Complete submission
      completer.complete();
      await tester.pumpAndSettle();
    });
  });
}

class _BlockingProductRepository extends FakeProductRepository {
  _BlockingProductRepository({required super.backend});
  Completer<void>? completer;
  final List<String> stockCalls = [];

  @override
  Future<void> setBasicStock({required String productId, required int quantity}) async {
    stockCalls.add('setBasicStock');
    if (completer != null) await completer!.future;
  }

  @override
  Future<void> adjustBasicStock({
    required String productId,
    required int newQuantity,
    String? reason,
    int? expectedQuantity,
  }) async {
    stockCalls.add('adjustBasicStock');
    if (completer != null) await completer!.future;
  }
}
