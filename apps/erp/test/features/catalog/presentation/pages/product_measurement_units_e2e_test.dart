import 'package:erp/core/di/injection.dart';
import 'package:erp/features/catalog/presentation/pages/product_control_center_page.dart';
import 'package:erp/features/catalog/presentation/pages/product_measurement_units_page.dart';
import 'package:erp/features/catalog/presentation/pages/product_readiness_checklist_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:vet45_catalog_application/testing.dart';
import 'package:vet45_catalog_presentation/presentation.dart';

import '../../catalog_e2e_harness.dart';

Future<void> _tapWhenVisible(WidgetTester tester, Finder finder) async {
  await tester.scrollUntilVisible(
    finder,
    120,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

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
            return ProductReadinessChecklistPage(
              readinessView: args.readinessView,
              product: args.product,
            );
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

  testWidgets('e2e_e04_u01_fr03_01: base unit search dropdown only shows on match', (
    tester,
  ) async {
    await setUpErpCatalogE2E(scenario: FakeCatalogScenario.unitDependenciesLocked);

    await tester.pumpWidget(buildMeasurementUnitsRouter(productWithoutBaseUnit()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Thiết lập đơn vị cơ sở'));
    await tester.pumpAndSettle();

    final inputFinder = find.byKey(const Key('input_base_unit_name'));
    await tester.tap(inputFinder);
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('dropdown_tenant_measurement_unit_matches')), findsNothing);

    await tester.enterText(inputFinder, 'Hộ');
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('dropdown_tenant_measurement_unit_matches')), findsOneWidget);
    expect(find.text('Hộp'), findsOneWidget);

    await tester.tap(find.byKey(const Key('dropdown_tenant_measurement_unit_item_unit-hop')));
    await tester.pumpAndSettle();

    expect(find.widgetWithText(TextField, 'Hộp'), findsOneWidget);
    expect(find.byKey(const Key('dropdown_tenant_measurement_unit_matches')), findsNothing);
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

  group('EPIC-04 / US-02 — Đơn vị quy đổi', () {
    testWidgets('e2e_e04_u02_fr01_01: add new conversion unit on product with base unit', (
      tester,
    ) async {
      await setUpErpCatalogE2E();

      await tester.pumpWidget(buildMeasurementUnitsRouter(productWithBaseUnit()));
      await tester.pumpAndSettle();

      expect(find.text('Hộp'), findsWidgets);
      expect(find.byKey(const Key('btn_add_conversion_unit')), findsOneWidget);

      await tester.tap(find.byKey(const Key('btn_add_conversion_unit')));
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('input_conversion_unit_name')), 'chai');
      await tester.pump();
      await tester.enterText(find.byKey(const Key('input_conversion_unit_rate')), '5');
      await tester.pump();

      await _tapWhenVisible(tester, find.byKey(const Key('btn_submit_conversion_unit')));

      expect(find.textContaining('1 chai = 5'), findsOneWidget);
      expect(find.byKey(const Key('btn_add_conversion_unit')), findsOneWidget);
    });

    testWidgets('e2e_e04_u02_fr01_01b: conversion unit search dropdown only shows on match', (
      tester,
    ) async {
      await setUpErpCatalogE2E();

      await tester.pumpWidget(buildMeasurementUnitsRouter(productWithBaseUnit()));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('btn_add_conversion_unit')));
      await tester.pumpAndSettle();

      final inputFinder = find.byKey(const Key('input_conversion_unit_name'));
      await tester.tap(inputFinder);
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('dropdown_conversion_unit_matches')), findsNothing);

      await tester.enterText(inputFinder, 'Lọ');
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('dropdown_conversion_unit_matches')), findsOneWidget);
      expect(
        find.byKey(const Key('dropdown_tenant_measurement_unit_item_unit-lo')),
        findsOneWidget,
      );

      await tester.enterText(inputFinder, 'Hộ');
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('dropdown_conversion_unit_matches')), findsOneWidget);
      expect(find.textContaining('Hộp (đơn vị cơ sở)'), findsOneWidget);
    });

    testWidgets('e2e_e04_u02_fr01_02: product without base unit shows gating message', (
      tester,
    ) async {
      await setUpErpCatalogE2E();

      await tester.pumpWidget(buildMeasurementUnitsRouter(productWithoutBaseUnit()));
      await tester.pumpAndSettle();

      expect(
        find.text('Cần đặt đơn vị cơ sở trước khi thêm đơn vị quy đổi.'),
        findsOneWidget,
      );
      expect(find.byKey(const Key('btn_add_conversion_unit')), findsNothing);
    });

    testWidgets('e2e_e04_u02_fr01_03: invalid conversion rate keeps add form open', (
      tester,
    ) async {
      await setUpErpCatalogE2E();

      await tester.pumpWidget(buildMeasurementUnitsRouter(productWithBaseUnit()));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('btn_add_conversion_unit')));
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('input_conversion_unit_name')), 'chai');
      await tester.pump();
      await tester.enterText(find.byKey(const Key('input_conversion_unit_rate')), '0');
      await tester.pump();

      await _tapWhenVisible(tester, find.byKey(const Key('btn_submit_conversion_unit')));

      expect(find.byKey(const Key('btn_submit_conversion_unit')), findsOneWidget);
      expect(find.byKey(const Key('input_conversion_unit_rate')), findsOneWidget);
    });

    testWidgets('e2e_e04_u02_fr01_04: duplicate conversion unit name shows error', (
      tester,
    ) async {
      await setUpErpCatalogE2E();

      await tester.pumpWidget(buildMeasurementUnitsRouter(productWithBaseUnit()));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('btn_add_conversion_unit')));
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('input_conversion_unit_name')), 'Vỉ');
      await tester.pump();
      await tester.enterText(find.byKey(const Key('input_conversion_unit_rate')), '10');
      await tester.pump();

      await _tapWhenVisible(tester, find.byKey(const Key('btn_submit_conversion_unit')));

      expect(find.byKey(const Key('btn_submit_conversion_unit')), findsOneWidget);
      expect(find.textContaining('Vỉ = 10'), findsOneWidget);
    });

    testWidgets('e2e_e04_u02_fr03_01: deactivate active conversion unit', (tester) async {
      await setUpErpCatalogE2E();

      await tester.pumpWidget(buildMeasurementUnitsRouter(productWithBaseUnit()));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('conversion_unit_item_product-1-unit-vi')), findsOneWidget);

      await tester.longPress(
        find.byKey(const Key('btn_expand_conversion_unit_product-1-unit-vi')),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('btn_toggle_conversion_unit_product-1-unit-vi')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('btn_confirm_deactivate_conversion_unit')));
      await tester.pumpAndSettle();

      expect(
        find.descendant(
          of: find.byKey(const Key('conversion_unit_item_product-1-unit-vi')),
          matching: find.text('Đã tắt'),
        ),
        findsOneWidget,
      );

      final nameTexts = tester
          .widgetList<Text>(
            find.descendant(
              of: find.byKey(const Key('conversion_unit_item_product-1-unit-vi')),
              matching: find.text('Vỉ'),
            ),
          )
          .toList();
      expect(nameTexts, isNotEmpty);
      expect(nameTexts.first.style?.decoration, isNot(TextDecoration.lineThrough));
    });

    testWidgets('e2e_e04_u02_fr04_01: reactivate inactive conversion unit', (tester) async {
      await setUpErpCatalogE2E();

      await tester.pumpWidget(buildMeasurementUnitsRouter(productWithBaseUnit()));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('conversion_unit_item_product-1-unit-thung')), findsOneWidget);
      expect(
        find.descendant(
          of: find.byKey(const Key('conversion_unit_item_product-1-unit-thung')),
          matching: find.text('Đã tắt'),
        ),
        findsOneWidget,
      );

      await tester.longPress(
        find.byKey(const Key('btn_expand_conversion_unit_product-1-unit-thung')),
      );
      await tester.pumpAndSettle();

      expect(find.text('Bật đơn vị'), findsOneWidget);

      await tester.tap(find.byKey(const Key('btn_toggle_conversion_unit_product-1-unit-thung')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('btn_confirm_reactivate_conversion_unit')));
      await tester.pumpAndSettle();

      expect(
        find.descendant(
          of: find.byKey(const Key('conversion_unit_item_product-1-unit-thung')),
          matching: find.text('100 x Hộp'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byKey(const Key('conversion_unit_item_product-1-unit-thung')),
          matching: find.text('Đã tắt'),
        ),
        findsNothing,
      );

      final nameTexts = tester
          .widgetList<Text>(
            find.descendant(
              of: find.byKey(const Key('conversion_unit_item_product-1-unit-thung')),
              matching: find.text('Thùng'),
            ),
          )
          .toList();
      expect(nameTexts, isNotEmpty);
      expect(nameTexts.first.style?.decoration, isNot(TextDecoration.lineThrough));
    });
  });
}
