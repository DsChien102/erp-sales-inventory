import 'package:erp/core/di/injection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vet45_catalog_application/application.dart';

import '../../catalog_e2e_harness.dart';

void main() {
  setUp(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  tearDown(() async {
    await getIt.reset();
  });

  testWidgets('e2e_e02_u01_fr01_01: guided create via ERP DI navigates to PCC', (tester) async {
    await setUpErpCatalogE2E();

    expect(getIt.isRegistered<ICatalogModule>(), isTrue);
    expect(getIt<ICatalogModule>(), isA<FakeCatalogModule>());

    await tester.pumpWidget(buildGuidedCreateRouter());
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('wgt_e02_u01_fr01_01')), findsOneWidget);

    await createMinimalProduct(tester, name: 'Amoxicillin 100ml');

    expect(find.text('Amoxicillin 100ml'), findsWidgets);
  });

  testWidgets('e2e_e02_u01_fr01_note: guided create persists optional note', (tester) async {
    await setUpErpCatalogE2E();

    await tester.pumpWidget(buildGuidedCreateRouter());
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('input_guided_name')), 'Thuốc có ghi chú');
    await tester.pump();

    final noteStep = find.text('7. Ghi chú');
    await tester.ensureVisible(noteStep);
    await tester.tap(noteStep);
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('input_guided_note')),
      'Hàng nhập từ nhà cung cấp A',
    );
    await tester.pump();

    await tester.tap(find.byKey(const Key('btn_guided_save')));
    await tester.pumpAndSettle();

    expect(find.text('Thuốc có ghi chú'), findsWidgets);
    expect(find.text('Đã điền ghi chú'), findsOneWidget);
  });

  testWidgets('e2e_e02_u01_fr01_01: duplicate SKU opens existing product in PCC', (tester) async {
    await setUpErpCatalogE2E(scenario: FakeCatalogScenario.guidedCreateDupSku);

    await tester.pumpWidget(buildGuidedCreateRouter());
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('input_guided_name')), 'Thuốc A');
    await tester.pump();
    await tester.enterText(find.byKey(const Key('input_guided_sku')), 'SKU-001');
    await tester.pump();
    await tester.tap(find.byKey(const Key('btn_guided_save')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('btn_open_duplicate_product')), findsOneWidget);
    expect(find.byKey(const Key('wgt_e02_u01_fr01_01')), findsOneWidget);

    await tester.tap(find.byKey(const Key('btn_open_duplicate_product')));
    await tester.pumpAndSettle();

    expect(find.text('Existing Product'), findsWidgets);
    expect(find.text('Thiếu dữ liệu'), findsOneWidget);
  });

  testWidgets('e2e_e02_u02_fr01_01: guided create with initial stock and base cost', (
    tester,
  ) async {
    await setUpErpCatalogE2E();

    await tester.pumpWidget(buildGuidedCreateRouter());
    await tester.pumpAndSettle();

    // Fill Step 1 Name
    await tester.enterText(find.byKey(const Key('input_guided_name')), 'Paracetamol 500mg');
    await tester.pump();

    // Open Step 3: Đơn vị cơ sở
    final step3Finder = find.text('3. Đơn vị cơ sở');
    await tester.ensureVisible(step3Finder);
    await tester.tap(step3Finder);
    await tester.pumpAndSettle();

    // Fill Base Unit
    await tester.enterText(find.byKey(const Key('input_guided_base_unit')), 'Hộp');
    await tester.pump();

    // Open Step 4: Tồn kho khởi tạo
    final step4Finder = find.text('4. Tồn kho khởi tạo');
    await tester.ensureVisible(step4Finder);
    await tester.tap(step4Finder);
    await tester.pumpAndSettle();

    // Fill Initial Stock
    await tester.enterText(find.byKey(const Key('input_guided_basic_stock_quantity_base')), '150');
    await tester.pump();

    // Open Step 5: Giá vốn cơ sở
    final step5Finder = find.text('5. Giá vốn cơ sở');
    await tester.ensureVisible(step5Finder);
    await tester.tap(step5Finder);
    await tester.pumpAndSettle();

    // Fill Base Cost
    await tester.enterText(find.byKey(const Key('input_guided_base_cost')), '5000');
    await tester.pump();

    // Confirm step 6 price band (store rule preview)
    final step6Finder = find.text('6. Khung giá bán');
    await tester.ensureVisible(step6Finder);
    await tester.tap(step6Finder);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('btn_guided_price_band_confirm')));
    await tester.tap(find.byKey(const Key('btn_guided_price_band_confirm')));
    await tester.pumpAndSettle();

    // Save product
    await tester.tap(find.byKey(const Key('btn_guided_save')));
    await tester.pumpAndSettle();

    // Verify PCC is reached and shows the created product
    expect(find.text('Paracetamol 500mg'), findsWidgets);
    expect(find.text('Tồn (Hộp): 150'), findsOneWidget);
    expect(find.text('Giá niêm yết: 7,500 đ'), findsOneWidget);
    expect(find.text('Tồn kho'), findsOneWidget);
    expect(find.textContaining('150 Hộp'), findsOneWidget);
    expect(find.text('Giá cơ sở'), findsOneWidget);
    expect(find.textContaining('5,000 đ'), findsOneWidget);
    expect(find.text('Khung giá'), findsOneWidget);
    expect(
      find.text('Niêm yết: 7,500 đ · Sàn: 6,250 đ · Đơn vị: Hộp · Mặc định bán lẻ'),
      findsOneWidget,
    );
  });

  testWidgets('e2e_e02_u01_fr03_01: base unit dropdown lists all units and filters on type', (
    tester,
  ) async {
    await setUpErpCatalogE2E();

    await tester.pumpWidget(buildGuidedCreateRouter());
    await tester.pumpAndSettle();

    final step3Finder = find.text('3. Đơn vị cơ sở');
    await tester.ensureVisible(step3Finder);
    await tester.tap(step3Finder);
    await tester.pumpAndSettle();

    final inputFinder = find.byKey(const Key('input_guided_base_unit'));
    await tester.tap(inputFinder);
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('dropdown_tenant_measurement_unit_matches')), findsOneWidget);
    expect(find.text('Hộp'), findsOneWidget);
    expect(find.text('Lọ'), findsOneWidget);
    expect(find.text('Vỉ'), findsOneWidget);

    await tester.enterText(inputFinder, 'Hộ');
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('dropdown_tenant_measurement_unit_matches')), findsOneWidget);
    expect(find.text('Hộp'), findsOneWidget);
    expect(find.text('Lọ'), findsNothing);

    await tester.tap(find.byKey(const Key('dropdown_tenant_measurement_unit_item_unit-hop')));
    await tester.pumpAndSettle();

    expect(find.widgetWithText(TextField, 'Hộp'), findsOneWidget);
    expect(find.byKey(const Key('dropdown_tenant_measurement_unit_matches')), findsNothing);

    await tester.enterText(inputFinder, 'xyz123');
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('dropdown_tenant_measurement_unit_matches')), findsNothing);
  });

  testWidgets('e2e_e02_u01_fr03_02: base unit dropdown shows when reaching step 3 via Tiếp', (
    tester,
  ) async {
    await setUpErpCatalogE2E();

    await tester.pumpWidget(buildGuidedCreateRouter());
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('input_guided_name')), 'Thuoc test');
    await tester.pump();

    final firstNext = find.text('Tiếp');
    await tester.ensureVisible(firstNext);
    await tester.tap(firstNext);
    await tester.pumpAndSettle();

    final secondNext = find.text('Tiếp');
    await tester.ensureVisible(secondNext);
    await tester.tap(secondNext);
    await tester.pumpAndSettle();

    final inputFinder = find.byKey(const Key('input_guided_base_unit'));
    await tester.ensureVisible(inputFinder);
    await tester.tap(inputFinder);
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('dropdown_tenant_measurement_unit_matches')), findsOneWidget);
    expect(find.text('Hộp'), findsOneWidget);
    expect(find.text('Lọ'), findsOneWidget);
  });

  testWidgets('e2e_e02_u02_fr03_01: skip price band defers setup and shows blocker', (
    tester,
  ) async {
    await setUpErpCatalogE2E();

    await tester.pumpWidget(buildGuidedCreateRouter());
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('input_guided_name')), 'Paracetamol skip price');
    await tester.pump();

    final step3Finder = find.text('3. Đơn vị cơ sở');
    await tester.ensureVisible(step3Finder);
    await tester.tap(step3Finder);
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('input_guided_base_unit')), 'Hộp');
    await tester.pump();

    final step4Finder = find.text('4. Tồn kho khởi tạo');
    await tester.ensureVisible(step4Finder);
    await tester.tap(step4Finder);
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('input_guided_basic_stock_quantity_base')), '150');
    await tester.pump();

    final step5Finder = find.text('5. Giá vốn cơ sở');
    await tester.ensureVisible(step5Finder);
    await tester.tap(step5Finder);
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('input_guided_base_cost')), '5000');
    await tester.pump();

    final step6Finder = find.text('6. Khung giá bán');
    await tester.ensureVisible(step6Finder);
    await tester.tap(step6Finder);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('btn_guided_save')));
    await tester.pumpAndSettle();

    expect(find.text('Paracetamol skip price'), findsWidgets);
    expect(find.text('Thiếu dữ liệu'), findsOneWidget);
    expect(find.text('Giá niêm yết: --'), findsOneWidget);
    expect(find.textContaining('Thiếu khung giá'), findsOneWidget);
    expect(find.text('Cần bổ sung (2)'), findsOneWidget);
  });

  testWidgets('guided create registers new base unit in tenant master list', (
    tester,
  ) async {
    await setUpErpCatalogE2E();
    final catalog = getIt<ICatalogModule>() as FakeCatalogModule;

    final unitsBefore = await catalog.executeQueryAsync(
      ListTenantMeasurementUnitsQuery(tenantId: 'tenant-1', limit: 50),
    );
    expect(unitsBefore.any((unit) => unit.name == 'chai'), isFalse);

    await tester.pumpWidget(buildGuidedCreateRouter());
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('input_guided_name')), 'Thuoc chai');
    await tester.pump();

    final step3Finder = find.text('3. Đơn vị cơ sở');
    await tester.ensureVisible(step3Finder);
    await tester.tap(step3Finder);
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('input_guided_base_unit')), 'chai');
    await tester.pump();

    await tester.tap(find.byKey(const Key('btn_guided_save')));
    await tester.pumpAndSettle();

    final unitsAfter = await catalog.executeQueryAsync(
      ListTenantMeasurementUnitsQuery(tenantId: 'tenant-1', limit: 50),
    );
    expect(unitsAfter.any((unit) => unit.name == 'chai'), isTrue);
    expect(find.text('Thuoc chai'), findsWidgets);
  });
}
