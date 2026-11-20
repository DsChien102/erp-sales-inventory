import 'package:erp/core/di/injection.dart';
import 'package:erp/features/catalog/data/product_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:erp/features/catalog/presentation.dart';

import '../../catalog_e2e_harness.dart';

void main() {
  setUp(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  tearDown(() async {
    await getIt.reset();
  });

  testWidgets('e2e_e07_u03_fr01_01: eligible product can be soft-deleted', (
    tester,
  ) async {
    await setUpErpCatalogE2E(
      scenario: FakeCatalogScenario.scnContractE07U03Fr01_01,
    );

    await tester.pumpWidget(buildCatalogDiscoveryRouter());
    await tester.pumpAndSettle();

    await _openProduct(tester, 'Thuốc thiếu đơn vị');
    await _openDangerSection(tester);
    await tester.tap(find.text('Xoá sản phẩm').last);
    await tester.pumpAndSettle();

    expect(find.text('Xoá sản phẩm này?'), findsOneWidget);
    expect(find.textContaining('không xuất hiện trong danh sách'), findsOneWidget);

    await tester.tap(find.text('Xoá sản phẩm').last);
    await tester.pumpAndSettle();

    _expectNoProductTile('Thuốc thiếu đơn vị');
  });

  testWidgets('e2e_e07_u03_fr01_02: open transaction blocker prevents delete', (
    tester,
  ) async {
    await setUpErpCatalogE2E(
      scenario: FakeCatalogScenario.scnContractE07U03Fr01_02,
    );

    await tester.pumpWidget(buildPccMaintenanceRouter(_product4()));
    await tester.pumpAndSettle();

    await _openDangerSection(tester);
    await tester.tap(find.text('Xoá sản phẩm').last);
    await tester.pumpAndSettle();

    expect(find.text('Xoá sản phẩm này?'), findsOneWidget);
    expect(find.textContaining('không thể xóa'), findsOneWidget);
    expect(find.textContaining('giao dịch mở'), findsOneWidget);
    expect(find.text('Đóng'), findsOneWidget);
  });

  testWidgets('e2e_e07_u03_fr01_03: historical data warning is shown before delete', (
    tester,
  ) async {
    await setUpErpCatalogE2E(
      scenario: FakeCatalogScenario.scnContractE07U03Fr01_03,
    );

    await tester.pumpWidget(buildPccMaintenanceRouter(productWithBaseUnit()));
    await tester.pumpAndSettle();

    await _openDangerSection(tester);
    await tester.tap(find.text('Xoá sản phẩm').last);
    await tester.pumpAndSettle();

    expect(find.text('Lưu ý'), findsOneWidget);
    expect(find.textContaining('giao dịch lịch sử'), findsOneWidget);
  });

  testWidgets('e2e_e07_u03_fr02_01: deleted product is excluded from default list', (
    tester,
  ) async {
    await setUpErpCatalogE2E(
      scenario: FakeCatalogScenario.scnContractE07U03Fr02_01,
    );

    await tester.pumpWidget(buildCatalogDiscoveryRouter());
    await tester.pumpAndSettle();

    await _openProduct(tester, 'Thuốc thiếu đơn vị');
    await _openDangerSection(tester);
    await tester.tap(find.text('Xoá sản phẩm').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Xoá sản phẩm').last);
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('input_product_search')),
      'Thuốc thiếu đơn vị',
    );
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();

    _expectNoProductTile('Thuốc thiếu đơn vị');
    expect(find.text('Không tìm thấy sản phẩm'), findsOneWidget);
  });

  testWidgets('e2e_e07_u03_fr02_03: deleted filter shows deleted product label', (
    tester,
  ) async {
    await setUpErpCatalogE2E(
      scenario: FakeCatalogScenario.scnContractE07U03Fr02_03,
    );

    await tester.pumpWidget(buildCatalogDiscoveryRouter());
    await tester.pumpAndSettle();

    await _openProduct(tester, 'Thuốc thiếu đơn vị');
    await _openDangerSection(tester);
    await tester.tap(find.text('Xoá sản phẩm').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Xoá sản phẩm').last);
    await tester.pumpAndSettle();

    await _tapDeletedFilter(tester);

    _expectProductTile('Thuốc thiếu đơn vị');
    expect(find.text('Đã xóa'), findsWidgets);
  });

  testWidgets('e2e_e07_u03_fr03_01: restore deleted product as inactive', (
    tester,
  ) async {
    await setUpErpCatalogE2E(
      scenario: FakeCatalogScenario.scnContractE07U03Fr03_01,
    );

    await _seedDeletedProduct('product-7');
    await tester.pumpWidget(buildPccMaintenanceRouter(_product7SoftDeleted()));
    await tester.pumpAndSettle();

    expect(find.text('Đã xóa'), findsWidgets);
    await _openDangerSection(tester);
    await tester.tap(find.text('Khôi phục').last);
    await tester.pumpAndSettle();

    expect(find.text('Khôi phục sản phẩm này?'), findsOneWidget);
    expect(find.textContaining('Thiếu khung giá'), findsWidgets);

    await tester.tap(find.text('Khôi phục').last);
    await tester.pumpAndSettle();

    expect(find.text('Kinh doanh lại'), findsWidgets);
    expect(find.textContaining('Thiếu khung giá'), findsWidgets);
  });

  testWidgets('e2e_e07_u03_fr03_02: restore duplicate SKU shows clear error', (
    tester,
  ) async {
    await setUpErpCatalogE2E(
      scenario: FakeCatalogScenario.scnContractE07U03Fr03_02,
    );

    await _seedDeletedProduct('product-7');
    await tester.pumpWidget(buildPccMaintenanceRouter(_product7SoftDeleted()));
    await tester.pumpAndSettle();

    await _openDangerSection(tester);
    await tester.tap(find.text('Khôi phục').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Khôi phục').last);
    await tester.pumpAndSettle();

    expect(find.textContaining('SKU đã được sử dụng'), findsWidgets);
  });

  testWidgets('e2e_e07_u03_fr03_03: restore duplicate barcode shows clear error', (
    tester,
  ) async {
    await setUpErpCatalogE2E(
      scenario: FakeCatalogScenario.scnContractE07U03Fr03_03,
    );

    await _seedDeletedProduct('product-7');
    await tester.pumpWidget(buildPccMaintenanceRouter(_product7SoftDeleted()));
    await tester.pumpAndSettle();

    await _openDangerSection(tester);
    await tester.tap(find.text('Khôi phục').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Khôi phục').last);
    await tester.pumpAndSettle();

    expect(find.textContaining('Mã vạch đã được sử dụng'), findsWidgets);
  });

  testWidgets('e2e_e07_u03_fr04_01: deleted PCC preserves operational data', (
    tester,
  ) async {
    await setUpErpCatalogE2E(
      scenario: FakeCatalogScenario.scnContractE07U03Fr04_01,
    );

    await tester.pumpWidget(buildCatalogDiscoveryRouter());
    await tester.pumpAndSettle();

    await _openProduct(tester, 'Amoxicillin 500mg');
    await _openDangerSection(tester);
    await tester.tap(find.text('Xoá sản phẩm').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Xoá sản phẩm').last);
    await tester.pumpAndSettle();

    await _tapDeletedFilter(tester);
    await _openProduct(tester, 'Amoxicillin 500mg');

    expect(find.text('Đã xóa'), findsWidgets);
    expect(find.textContaining('Hộp'), findsWidgets);
    expect(find.text('150 Hộp'), findsOneWidget);
    expect(find.textContaining('80'), findsWidgets);
    expect(find.textContaining('120'), findsWidgets);
    expect(find.textContaining('Xóa mềm sản phẩm'), findsOneWidget);
  });
}

Future<void> _openProduct(WidgetTester tester, String name) async {
  await tester.enterText(find.byKey(const Key('input_product_search')), name);
  await tester.testTextInput.receiveAction(TextInputAction.done);
  await tester.pump(const Duration(milliseconds: 500));
  await tester.pumpAndSettle();

  final productTile = find
      .ancestor(
        of: find.descendant(
          of: find.byType(ProductListItemTile),
          matching: find.textContaining(name),
        ),
        matching: find.byType(ProductListItemTile),
      )
      .first;
  await tester.ensureVisible(productTile);
  await tester.tap(productTile);
  await tester.pumpAndSettle();
}

Future<void> _openDangerSection(WidgetTester tester) async {
  final dangerSection = find.byKey(const Key('btn_product_lifecycle_danger_toggle'));
  await tester.ensureVisible(dangerSection);
  await tester.tap(dangerSection);
  await tester.pumpAndSettle();
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

ProductListItemModel _product7SoftDeleted() {
  return const ProductListItemModel(
    id: 'product-7',
    name: 'Thuốc thiếu giá',
    businessStatus: ProductBusinessStatus.softDeleted,
    readinessStatus: ProductReadinessStatus.needsReview,
    baseUnit: 'Lọ',
  );
}

Future<void> _seedDeletedProduct(String productId) async {
  await getIt<ProductRepository>().delete(productId: productId);
}

Future<void> _tapDeletedFilter(WidgetTester tester) async {
  final filter = find
      .ancestor(
        of: find.text('Đã xóa').first,
        matching: find.byType(GestureDetector),
      )
      .first;
  await tester.tap(filter);
  await tester.pumpAndSettle();
}

void _expectProductTile(String name) {
  expect(
    find.descendant(
      of: find.byType(ProductListItemTile),
      matching: find.textContaining(name),
    ),
    findsOneWidget,
  );
}

void _expectNoProductTile(String name) {
  expect(
    find.descendant(
      of: find.byType(ProductListItemTile),
      matching: find.textContaining(name),
    ),
    findsNothing,
  );
}
