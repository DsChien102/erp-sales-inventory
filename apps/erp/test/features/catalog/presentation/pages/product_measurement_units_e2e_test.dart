import 'package:erp/core/di/injection.dart';
import 'package:erp/features/catalog/presentation/pages/product_control_center_page.dart';
import 'package:erp/features/catalog/presentation/pages/product_measurement_units_page.dart';
import 'package:erp/features/catalog/presentation/pages/product_readiness_checklist_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:vet45_catalog_application/application.dart';
import 'package:vet45_catalog_application/testing.dart';
import 'package:vet45_catalog_presentation/presentation.dart';
import 'package:vet45_shared_application/application.dart';

import '../../catalog_e2e_harness.dart';

ProductListItemModel _sampleProduct() {
  return const ProductListItemModel(
    id: 'product-6',
    name: 'Thuốc thiếu đơn vị',
    businessStatus: ProductBusinessStatus.active,
    readinessStatus: ProductReadinessStatus.needsReview,
  );
}

void main() {
  setUp(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  tearDown(() async {
    await getIt.reset();
  });

  Widget buildTestRouter() {
    final router = GoRouter(
      initialLocation: '/products/items/pcc',
      routes: [
        GoRoute(
          path: '/products/items/pcc',
          builder: (context, state) => ProductControlCenterPage(product: _sampleProduct()),
        ),
        GoRoute(
          path: '/products/items/pcc/checklist',
          builder: (context, state) {
            final args = state.extra as ProductReadinessChecklistRouteArgs;
            return ProductReadinessChecklistPage(readinessView: args.readinessView, product: args.product);
          },
        ),
        GoRoute(
          path: '/products/items/pcc/units',
          builder: (context, state) {
            final args = state.extra as ProductMeasurementUnitsRouteArgs;
            return ProductMeasurementUnitsPage(product: args.product);
          },
        ),
      ],
    );

    return MaterialApp.router(routerConfig: router);
  }

  testWidgets('e2e_e04_u01_fr01_01_create_new: set new base unit from checklist', (tester) async {
    await setUpErpCatalogE2E(scenario: FakeCatalogScenario.unitDependenciesLocked);

    await tester.pumpWidget(buildTestRouter());
    await tester.pumpAndSettle();

    // Now in Product Control Center.
    expect(find.text('Thuốc thiếu đơn vị'), findsWidgets);
    expect(find.byKey(const Key('btn_readiness_checklist_banner')), findsOneWidget);
    await tester.tap(find.byKey(const Key('btn_readiness_checklist_banner')));
    await tester.pumpAndSettle();

    // Now in Checklist page. Tap on 'Thiết lập đơn vị'
    expect(find.text('Thiết lập đơn vị'), findsOneWidget);
    await tester.tap(find.text('Thiết lập đơn vị'));
    await tester.pumpAndSettle();

    // Now in Measurement Units Page
    expect(find.text('ĐƠN VỊ CƠ SỞ'), findsOneWidget);
    
    // Tap the outline button to add a new unit
    expect(find.text('Thiết lập đơn vị cơ sở'), findsOneWidget);
    await tester.tap(find.text('Thiết lập đơn vị cơ sở'));
    await tester.pumpAndSettle();

    // Enter a new unit 'Vỉ'
    await tester.enterText(find.byType(TextField).first, 'Vỉ');
    await tester.pumpAndSettle();

    await tester.tap(find.text('Lưu'));
    await tester.pumpAndSettle();

    // UI should update to show the new base unit and hide the editing field
    expect(find.text('Vỉ'), findsOneWidget);
    expect(find.byType(TextField), findsNothing);

    // Close the page
    await tester.tap(find.text('Lưu thay đổi'));
    await tester.pumpAndSettle();
  });

  testWidgets('e2e_e04_u01_fr01_02_duplicate: cannot create duplicate base unit', (tester) async {
    await setUpErpCatalogE2E(scenario: FakeCatalogScenario.setBaseUnitDuplicate);

    await tester.pumpWidget(buildTestRouter());
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('btn_readiness_checklist_banner')));
    await tester.pumpAndSettle();

    // Navigate to checklist
    await tester.tap(find.text('Thiết lập đơn vị'));
    await tester.pumpAndSettle();

    // Tap 'Thiết lập đơn vị cơ sở' to show the edit field
    expect(find.text('Thiết lập đơn vị cơ sở'), findsOneWidget);
    await tester.tap(find.text('Thiết lập đơn vị cơ sở'));
    await tester.pumpAndSettle();

    // Enter a new unit name 'trùng lặp' which will trigger duplicate scenario
    await tester.enterText(find.byType(TextField).first, 'trùng lặp');
    await tester.pumpAndSettle();

    await tester.tap(find.text('Lưu'));
    await tester.pumpAndSettle();

    // UI should NOT update to hide the editing field because of error
    expect(find.byType(TextField), findsOneWidget);
  });
}
