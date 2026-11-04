import 'package:erp/core/di/injection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:erp/features/catalog/data/product_repository.dart';
import '../../support/fake_catalog_repositories.dart';
import 'package:erp/features/catalog/presentation.dart';

import '../../catalog_e2e_harness.dart';

// ProductListItemModel _product1() {
//   return const ProductListItemModel(
//     id: 'product-1',
//     name: 'Amoxicillin 500mg',
//     businessStatus: ProductBusinessStatus.active,
//     readinessStatus: ProductReadinessStatus.ready,
//     baseUnit: 'Hộp',
//   );
// }

ProductListItemModel _product4() {
  return const ProductListItemModel(
    id: 'product-4',
    name: 'Vitamin B Complex',
    businessStatus: ProductBusinessStatus.active,
    readinessStatus: ProductReadinessStatus.needsReview,
    baseUnit: 'Chai',
  );
}

Future<void> _openProductFromDiscovery(WidgetTester tester, String name) async {
  await tester.pumpWidget(buildCatalogDiscoveryRouter());
  await tester.pumpAndSettle();
  await tester.tap(find.textContaining(name));
  await tester.pumpAndSettle();
}

Future<void> _saveProfile(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('btn_profile_maintenance_save')));
  await tester.pumpAndSettle();
}

Future<void> _saveImages(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('btn_images_maintenance_save')));
  await tester.pumpAndSettle();
}

void main() {
  setUp(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  tearDown(() async {
    await getIt.reset();
  });

  testWidgets('e2e_e07_u01_fr01_01: valid profile edit refreshes PCC', (tester) async {
    await setUpErpCatalogE2E(scenario: FakeCatalogScenario.pccReadyToSell);
    expect(getIt<ProductRepository>(), isA<FakeProductRepository>());

    await _openProductFromDiscovery(tester, 'Amoxicillin 500mg');
    await tapEditProfile(tester);

    expect(find.byKey(const Key('wgt_e07_u01_fr01_01')), findsOneWidget);

    const updatedName = 'Amoxicillin 500mg Updated';
    await tester.enterText(find.byKey(const Key('input_profile_name')), updatedName);
    await tester.pump();
    await _saveProfile(tester);

    expect(find.byKey(const Key('wgt_e07_u01_fr01_01')), findsNothing);
    expect(find.byKey(const Key('wgt_e01_u02_fr01_01')), findsOneWidget);

    await tapEditProfile(tester);
    expect(find.byKey(const Key('input_profile_name')), findsOneWidget);
    expect(
      tester
          .widget<TextField>(
            find.descendant(
              of: find.byKey(const Key('input_profile_name')),
              matching: find.byType(TextField),
            ),
          )
          .controller
          ?.text,
      updatedName,
    );
  });

  testWidgets('e2e_e07_u01_fr01_02: blank name shows field validation error', (tester) async {
    await setUpErpCatalogE2E(scenario: FakeCatalogScenario.pccReadyToSell);

    await _openProductFromDiscovery(tester, 'Amoxicillin 500mg');
    await tapEditProfile(tester);

    await tester.enterText(find.byKey(const Key('input_profile_name')), '');
    await tester.pump();
    await _saveProfile(tester);

    expect(find.text('Tên sản phẩm là bắt buộc'), findsOneWidget);
    expect(find.byKey(const Key('wgt_e07_u01_fr01_01')), findsOneWidget);
  });

  testWidgets('e2e_e07_u01_fr01_03: duplicate SKU shows field error', (tester) async {
    await setUpErpCatalogE2E(scenario: FakeCatalogScenario.scnContractE07U01Fr01_03);

    await _openProductFromDiscovery(tester, 'Amoxicillin 500mg');
    await tapEditProfile(tester);

    await tester.enterText(find.byKey(const Key('input_profile_sku')), 'SP0002');
    await tester.pump();
    await _saveProfile(tester);

    expect(find.text('Mã SKU đã được sử dụng'), findsOneWidget);
    expect(find.byKey(const Key('wgt_e07_u01_fr01_01')), findsOneWidget);
  });

  testWidgets('e2e_e07_u01_fr03_01: duplicate barcode includes inactive product', (tester) async {
    await setUpErpCatalogE2E(scenario: FakeCatalogScenario.scnContractE07U01Fr03_01);

    await _openProductFromDiscovery(tester, 'Amoxicillin 500mg');
    await tapEditProfile(tester);

    await tester.enterText(find.byKey(const Key('input_profile_barcode')), '8930000000005');
    await tester.pump();
    await _saveProfile(tester);

    expect(find.text('Mã vạch đã được sử dụng'), findsOneWidget);
    expect(find.byKey(const Key('wgt_e07_u01_fr01_01')), findsOneWidget);
  });

  testWidgets('e2e_e07_u01_fr02_01: PCC opens images maintenance gallery', (tester) async {
    await setUpErpCatalogE2E(scenario: FakeCatalogScenario.pccReadyToSell);

    await _openProductFromDiscovery(tester, 'Amoxicillin 500mg');
    await tapEditImages(tester);

    expect(find.byKey(const Key('wgt_e07_u01_fr02_01')), findsOneWidget);
    expect(find.text('Mặc định'), findsOneWidget);
  });

  testWidgets('e2e_e07_u01_fr02_02: removing primary promotes remaining image', (tester) async {
    await setUpErpCatalogE2E(scenario: FakeCatalogScenario.pccProfileMaintenanceImages);

    await _openProductFromDiscovery(tester, 'Amoxicillin 500mg');
    await tapEditImages(tester);

    expect(find.byKey(const Key('wgt_e07_u01_fr02_01')), findsOneWidget);
    expect(find.text('Mặc định'), findsOneWidget);
    expect(find.byIcon(Icons.close), findsNWidgets(2));

    await tester.tap(find.byIcon(Icons.close).first);
    await tester.pump();
    await _saveImages(tester);

    expect(find.byKey(const Key('wgt_e07_u01_fr02_01')), findsNothing);
    expect(find.textContaining('1 ảnh'), findsWidgets);

    await tapEditImages(tester);
    expect(find.text('Mặc định'), findsOneWidget);
    expect(find.byIcon(Icons.close), findsOneWidget);
  });

  testWidgets('e2e_e07_u01_fr02_03: deleting all images shows zero on PCC', (tester) async {
    await setUpErpCatalogE2E(scenario: FakeCatalogScenario.pccReadyToSell);

    await _openProductFromDiscovery(tester, 'Amoxicillin 500mg');
    await tapEditImages(tester);

    await tester.tap(find.byIcon(Icons.close));
    await tester.pump();
    await _saveImages(tester);

    expect(find.textContaining('0 ảnh'), findsWidgets);
  });

  testWidgets('e2e_e07_u01_fr04_01: deleting images adds readiness blocker on incomplete product', (
    tester,
  ) async {
    await setUpErpCatalogE2E(scenario: FakeCatalogScenario.pccIncomplete);

    await tester.pumpWidget(buildPccMaintenanceRouter(_product4()));
    await tester.pumpAndSettle();

    expect(find.text('Thiếu dữ liệu'), findsOneWidget);
    await tapEditImages(tester);

    await tester.tap(find.byIcon(Icons.close));
    await tester.pump();
    await _saveImages(tester);

    expect(find.text('Thiếu dữ liệu'), findsOneWidget);
    final banner = find.byKey(const Key('btn_readiness_checklist_banner'));
    await tester.ensureVisible(banner);
    await tester.tap(banner);
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('wgt_e02_u03_checklist')), findsOneWidget);
    expect(find.text('Chưa có ảnh sản phẩm'), findsOneWidget);
    expect(find.text('Quản lý ảnh'), findsOneWidget);
  });
}
