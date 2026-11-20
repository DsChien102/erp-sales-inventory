import 'package:erp/features/catalog/data/models.dart';
import 'package:erp/features/catalog/presentation/pages/edit_product_unit_price_band_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:c45_design_system/design_system.dart';

import '../../support/catalog_test_registry.dart';

void main() {
  final getIt = GetIt.instance;

  setUp(() async {
    await getIt.reset();
    registerFakeCatalog(getIt);
  });

  tearDown(() => getIt.reset());

  testWidgets('reopens custom config from persisted ratios and switches mode', (
    tester,
  ) async {
    const row = ProductUnitPriceBandRowDto(
      productUnitId: 'product-9-hop',
      unitName: 'Hộp',
      isBaseUnit: false,
      isActive: true,
      isMissing: false,
      sourceType: PriceBandSourceType.customConfig,
      listBeforeVat: 130000,
      floorBeforeVat: 110000,
      listAfterVat: 130000,
      floorAfterVat: 110000,
      listMarkupRatio: 0.30,
      floorMarkupRatio: 0.10,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: EditProductUnitPriceBandPage(
          args: EditProductUnitPriceBandRouteArgs(
            row: row,
            productId: 'product-9',
            productName: 'Thuốc multi UOM',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Tự động riêng theo cấu hình'), findsOneWidget);
    expect(find.text('Nhập cấu hình tính toán'), findsOneWidget);
    final inputValues = tester
        .widgetList<EditableText>(find.byType(EditableText))
        .map((field) => field.controller.text)
        .toList();
    expect(inputValues, containsAll(<String>['30', '10']));

    await tester.tap(find.text('Nhập thủ công'));
    await tester.pumpAndSettle();
    expect(find.text('Nhập giá thủ công'), findsOneWidget);
  });

  testWidgets('enables save when applying store rule to a new price band', (
    tester,
  ) async {
    const row = ProductUnitPriceBandRowDto(
      productUnitId: 'product-4-base',
      unitName: 'Chai',
      isBaseUnit: true,
      isActive: true,
      isMissing: true,
      basePrice: 25000,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: EditProductUnitPriceBandPage(
          args: EditProductUnitPriceBandRouteArgs(
            row: row,
            productId: 'product-4',
            productName: 'Vitamin B Complex',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final saveButton = tester.widget<VButton>(
      find.byKey(const Key('btn_price_band_save')),
    );
    expect(saveButton.onPressed, isNotNull);
  });

  testWidgets('g5_store_rule_help_text', (tester) async {
    const row = ProductUnitPriceBandRowDto(
      productUnitId: 'product-4-base',
      unitName: 'Chai',
      isBaseUnit: true,
      isActive: true,
      isMissing: true,
      basePrice: 25000,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: EditProductUnitPriceBandPage(
          args: EditProductUnitPriceBandRouteArgs(
            row: row,
            productId: 'product-4',
            productName: 'Vitamin B Complex',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Tự động áp dụng khung giá cửa hàng.'), findsOneWidget);
    expect(find.text('Tự động áp dụng khung giá của hàng.'), findsNothing);
  });
}
