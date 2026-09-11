import 'package:erp/core/di/injection.dart';
import 'package:flutter_test/flutter_test.dart';
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

ProductListItemModel _product5() {
  return const ProductListItemModel(
    id: 'product-5',
    name: 'Ibuprofen 400mg',
    businessStatus: ProductBusinessStatus.inactive,
    readinessStatus: ProductReadinessStatus.ready,
    baseUnit: 'Hộp',
  );
}

void main() {
  setUp(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  tearDown(() async {
    await getIt.reset();
  });

  testWidgets('e2e_e07_u02_fr01_01: deactivate active product without warnings', (tester) async {
    await setUpErpCatalogE2E(scenario: FakeCatalogScenario.pccReadyToSell);

    // pccReadyToSell scenario returns product-1, which doesn't trigger warnings for this scenario.
    await tester.pumpWidget(buildPccMaintenanceRouter(_product1()));
    await tester.pumpAndSettle();

    // Expand the danger section
    final dangerSection = find.text('Nâng cao');
    await tester.ensureVisible(dangerSection);
    await tester.tap(dangerSection);
    await tester.pumpAndSettle();

    // Tap deactivate action
    final deactivateBtn = find.text('Ngừng kinh doanh').last;
    await tester.ensureVisible(deactivateBtn);
    await tester.tap(deactivateBtn);
    await tester.pumpAndSettle();

    // Verify bottom sheet appears
    expect(find.text('Ngừng kinh doanh sản phẩm này?'), findsOneWidget);

    // Tap confirm
    await tester.tap(find.text('Ngừng kinh doanh').last);
    await tester.pumpAndSettle();

    // Verify UI update (button changes to reactivate)
    expect(find.text('Kinh doanh lại'), findsWidgets);
  });

  testWidgets('e2e_e07_u02_fr01_02: deactivate product with stock shows warnings in bottom sheet', (
    tester,
  ) async {
    await setUpErpCatalogE2E(scenario: FakeCatalogScenario.scnContractE07U02Fr01_02);

    await tester.pumpWidget(buildPccMaintenanceRouter(_product1()));
    await tester.pumpAndSettle();

    // Expand the danger section
    final dangerSection = find.text('Nâng cao');
    await tester.ensureVisible(dangerSection);
    await tester.tap(dangerSection);
    await tester.pumpAndSettle();

    // Tap deactivate action
    final deactivateBtn = find.text('Ngừng kinh doanh').last;
    await tester.ensureVisible(deactivateBtn);
    await tester.tap(deactivateBtn);
    await tester.pumpAndSettle();

    // Verify bottom sheet appears without warnings initially
    expect(find.text('Ngừng kinh doanh sản phẩm này?'), findsOneWidget);

    // Tap confirm
    await tester.tap(find.text('Ngừng kinh doanh').last);
    await tester.pumpAndSettle();

    // Verify bottom sheet appears AGAIN and shows warnings
    expect(find.text('Ngừng kinh doanh sản phẩm này?'), findsOneWidget);
    expect(find.text('Cần xác nhận'), findsOneWidget);
    expect(find.textContaining('Sản phẩm vẫn còn tồn kho hiện hành'), findsOneWidget);

    // Tap confirm again
    await tester.tap(find.text('Ngừng kinh doanh').last);
    await tester.pumpAndSettle();

    // Verify UI update (button changes to reactivate)
    expect(find.text('Kinh doanh lại'), findsWidgets);
  });

  testWidgets('e2e_e07_u02_fr02_01: reactivate inactive product', (tester) async {
    await setUpErpCatalogE2E(scenario: FakeCatalogScenario.pccInactive);

    // Use product-5 which is inactive in FakeCatalogScenario.pccInactive
    await tester.pumpWidget(buildPccMaintenanceRouter(_product5()));
    await tester.pumpAndSettle();

    // Expand the danger section
    final dangerSection = find.text('Nâng cao');
    await tester.ensureVisible(dangerSection);
    await tester.tap(dangerSection);
    await tester.pumpAndSettle();

    // Tap reactivate action
    final reactivateBtn = find.text('Kinh doanh lại').last;
    await tester.ensureVisible(reactivateBtn);
    await tester.tap(reactivateBtn);
    await tester.pumpAndSettle();

    // Verify bottom sheet appears
    expect(find.text('Kinh doanh lại sản phẩm này?'), findsOneWidget);

    // Tap confirm
    await tester.tap(find.text('Kinh doanh lại').last);
    await tester.pumpAndSettle();

    // Verify UI update (button changes to deactivate)
    expect(find.text('Ngừng kinh doanh'), findsWidgets);
  });
}
