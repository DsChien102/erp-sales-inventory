import 'package:erp/core/di/injection.dart';
import 'package:erp/features/catalog/presentation/pages/product_control_center_page.dart';
import 'package:erp/features/catalog/presentation/pages/product_custom_field_group_edit_page.dart';
import 'package:erp/features/catalog/presentation/pages/product_readiness_checklist_page.dart';
import 'package:erp/features/catalog/presentation/utils/resolve_priority_custom_field_group.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:vet45_catalog_application/application.dart';
import 'package:vet45_catalog_presentation/presentation.dart';
import 'package:vet45_design_system/design_system.dart';
import 'package:vet45_shared_application/application.dart';

import '../../catalog_e2e_harness.dart';

Finder _customFieldInput(String label) {
  return find.byWidgetPredicate((widget) => widget is VTextField && widget.label == label);
}

Future<void> _enterCustomFieldText(
  WidgetTester tester,
  String label,
  String value,
) async {
  final field = _customFieldInput(label);
  await tester.ensureVisible(field);
  await tester.enterText(
    find.descendant(of: field, matching: find.byType(TextField)),
    value,
  );
  await tester.pump();
}

Widget _buildChecklistRouter({
  required ProductReadinessViewDto readinessView,
  required ProductListItemModel product,
  List<CustomFieldGroupCardDto> customFieldGroupCards = const [],
}) {
  final router = GoRouter(
    initialLocation: '/products/items/pcc/checklist',
    routes: [
      GoRoute(
        path: '/products/items/pcc/checklist',
        builder: (context, state) => ProductReadinessChecklistPage(
          readinessView: readinessView,
          product: product,
          customFieldGroupCards: customFieldGroupCards,
        ),
      ),
      GoRoute(
        path: '/products/items/pcc/custom-fields/edit',
        builder: (context, state) {
          final args = state.extra as ProductCustomFieldGroupEditRouteArgs;
          return Scaffold(
            body: Text(
              'custom-fields-edit:${args.groupId}',
              key: const Key('custom_fields_edit_opened'),
            ),
          );
        },
      ),
      GoRoute(
        path: '/products/items/pcc/stock',
        builder: (context, state) => const Scaffold(
          body: Text('stock-opened', key: Key('stock_opened')),
        ),
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

  testWidgets('e2e_e02_u03_fr01_01: post-create PCC shows readiness blockers', (tester) async {
    await setUpErpCatalogE2E();

    await tester.pumpWidget(buildCatalogPostCreateRouter());
    await tester.pumpAndSettle();

    await createMinimalProduct(tester, name: 'Thuốc A');

    expect(find.byKey(const Key('wgt_e02_u03_fr01_01')), findsOneWidget);
    expect(find.textContaining('Cần bổ sung'), findsOneWidget);
    expect(find.text('Thiếu dữ liệu'), findsOneWidget);
    expect(find.text('Tồn kho'), findsWidgets);
  });

  testWidgets('e2e_e02_u03_fr02_04: successful create navigates to PCC with product name', (
    tester,
  ) async {
    await setUpErpCatalogE2E();

    await tester.pumpWidget(buildCatalogPostCreateRouter());
    await tester.pumpAndSettle();

    await createMinimalProduct(tester, name: 'Amoxicillin 500mg');

    expect(find.byKey(const Key('wgt_e02_u03_fr01_01')), findsOneWidget);
    expect(find.text('Amoxicillin 500mg'), findsWidgets);
    expect(find.byKey(const Key('wgt_e02_u01_fr01_01')), findsNothing);
  });

  testWidgets('e2e_e02_u03_fr02_04: failed create stays on guided create form', (tester) async {
    await setUpErpCatalogE2E();

    await tester.pumpWidget(buildCatalogPostCreateRouter());
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('btn_guided_save')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('wgt_e02_u01_fr01_01')), findsOneWidget);
    expect(find.byKey(const Key('wgt_e02_u03_fr01_01')), findsNothing);
    expect(find.text('Vui lòng nhập tên nội bộ sản phẩm.'), findsOneWidget);
  });

  testWidgets('e2e_e02_u03_fr03_01: checklist shows base unit blocker and CTA', (tester) async {
    await setUpErpCatalogE2E(scenario: FakeCatalogScenario.readinessManyBlockers);

    await tester.pumpWidget(buildCatalogPostCreateRouter());
    await tester.pumpAndSettle();

    await createMinimalProduct(tester, name: 'Thuốc B');

    expect(find.byKey(const Key('btn_readiness_checklist_banner')), findsOneWidget);
    await tester.tap(find.byKey(const Key('btn_readiness_checklist_banner')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('wgt_e02_u03_checklist')), findsOneWidget);
    expect(find.text('Thiếu đơn vị cơ sở'), findsOneWidget);
    expect(find.text('Thiết lập đơn vị'), findsOneWidget);
  });

  testWidgets('e2e_e02_u03_fr04_01: readiness refresh drops base unit blocker after create', (
    tester,
  ) async {
    await setUpErpCatalogE2E(scenario: FakeCatalogScenario.readinessRefreshAfterUnit);

    await tester.pumpWidget(buildCatalogPostCreateRouter());
    await tester.pumpAndSettle();

    await createMinimalProduct(tester, name: 'Thuốc C', baseUnit: 'Lọ');

    expect(find.byKey(const Key('btn_readiness_checklist_banner')), findsOneWidget);
    await tester.tap(find.byKey(const Key('btn_readiness_checklist_banner')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('wgt_e02_u03_checklist')), findsOneWidget);
    expect(find.text('Thiếu đơn vị cơ sở'), findsNothing);
    expect(find.text('Thiếu khung giá bán'), findsOneWidget);
  });

  testWidgets('e2e_e02_u03_fr01_05: ready to sell product shows success badge without banner', (
    tester,
  ) async {
    await setUpErpCatalogE2E(scenario: FakeCatalogScenario.readinessReadyToSell);

    await tester.pumpWidget(buildCatalogPostCreateRouter());
    await tester.pumpAndSettle();

    await createMinimalProduct(tester, name: 'Thuốc D', baseUnit: 'Lọ');

    expect(find.byKey(const Key('wgt_e02_u03_fr01_01')), findsOneWidget);
    expect(find.text('Sẵn sàng bán'), findsOneWidget);
    expect(find.text('Thiếu tồn kho'), findsNothing);
    expect(find.text('Thiếu khung giá bán'), findsNothing);
    expect(find.text('Thiếu giá'), findsNothing);
  });

  testWidgets(
    'e2e_e02_u03_checklist_cf: custom fields open without base unit; stock still blocked',
    (tester) async {
      await setUpErpCatalogE2E();

      final readinessView = FakeProductReadinessBuilder.build(
        productId: 'product-cf-1',
        productName: 'Thuốc CF',
        hasBaseUnit: false,
        hasImages: true,
        hasStock: false,
        hasBasePrice: false,
        hasPriceBand: false,
        hasRequiredCustomFields: false,
      );
      const product = ProductListItemModel(
        id: 'product-cf-1',
        name: 'Thuốc CF',
        businessStatus: ProductBusinessStatus.active,
        readinessStatus: ProductReadinessStatus.needsReview,
      );
      const cards = [
        CustomFieldGroupCardDto(
          groupId: 'group-complete',
          name: 'Đã đủ',
          sortOrder: 1,
          hasRequiredMissing: false,
        ),
        CustomFieldGroupCardDto(
          groupId: 'group-missing',
          name: 'Thiếu required',
          sortOrder: 2,
          hasRequiredMissing: true,
        ),
      ];

      await tester.pumpWidget(
        _buildChecklistRouter(
          readinessView: readinessView,
          product: product,
          customFieldGroupCards: cards,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Thiếu đơn vị cơ sở'), findsOneWidget);
      expect(find.text('Thiếu thông tin bổ sung bắt buộc'), findsOneWidget);

      await tester.tap(find.text('Cập nhật trường'));
      await tester.pumpAndSettle();

      expect(find.text('custom-fields-edit:group-missing'), findsOneWidget);
      expect(find.text('Vui lòng thiết lập đơn vị cơ sở trước.'), findsNothing);

      await tester.pumpWidget(
        _buildChecklistRouter(
          readinessView: readinessView,
          product: product,
          customFieldGroupCards: cards,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Nhập tồn kho'));
      await tester.pumpAndSettle();

      expect(find.text('Vui lòng thiết lập đơn vị cơ sở trước.'), findsOneWidget);
      expect(find.byKey(const Key('stock_opened')), findsNothing);
    },
  );

  testWidgets(
    'e2e_e02_u03_checklist_cf_priority: after save still banners and opens next required group',
    (tester) async {
      await setUpErpCatalogE2E(scenario: FakeCatalogScenario.e2eCfValuesMultiRequired);

      final product = productWithBaseUnit();
      final router = GoRouter(
        initialLocation: '/products/items/pcc',
        routes: [
          GoRoute(
            path: '/products/items/pcc',
            builder: (context, state) => ProductControlCenterPage(product: product),
          ),
          GoRoute(
            path: '/products/items/pcc/checklist',
            builder: (context, state) {
              final args = state.extra as ProductReadinessChecklistRouteArgs;
              return ProductReadinessChecklistPage(
                readinessView: args.readinessView,
                product: args.product,
                customFieldGroupCards: args.customFieldGroupCards,
              );
            },
          ),
          GoRoute(
            path: '/products/items/pcc/custom-fields/edit',
            builder: (context, state) {
              final args = state.extra as ProductCustomFieldGroupEditRouteArgs;
              return ProductCustomFieldGroupEditPage(args: args);
            },
          ),
        ],
      );

      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 800));

      expect(find.textContaining('Cần bổ sung'), findsOneWidget);

      await tester.tap(find.byKey(const Key('btn_readiness_checklist_banner')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 800));
      expect(find.byKey(const Key('wgt_e02_u03_checklist')), findsOneWidget);

      await tester.tap(find.text('Cập nhật trường'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 800));
      expect(_customFieldInput('Thành phần'), findsOneWidget);
      expect(_customFieldInput('Bảo quản'), findsNothing);

      await _enterCustomFieldText(tester, 'Thành phần', 'Vitamin A, D, E');
      await tester.tap(find.text('Lưu thay đổi'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 800));

      // Pop về PCC: banner bổ sung vẫn còn vì còn nhóm required thứ 2.
      expect(find.byKey(const Key('wgt_e02_u03_fr01_01')), findsOneWidget);
      expect(find.textContaining('Cần bổ sung'), findsOneWidget);
      expect(find.text('Sẵn sàng bán'), findsNothing);

      final tenantId = await getIt.get<IExecutionContext>().requireTenantId();
      final pcc = await getIt.get<ICatalogModule>().executeQueryAsync(
        GetProductControlCenterQuery(tenantId: tenantId, productId: product.id),
      );
      final nextGroupId = resolvePriorityCustomFieldGroupId(pcc.customFieldGroupCards);
      final storageGroup = pcc.customFieldGroupCards.firstWhere(
        (group) => group.name == 'Quy cách & bảo quản',
      );
      expect(storageGroup.hasRequiredMissing, isTrue);
      expect(nextGroupId, storageGroup.groupId);

      await tester.tap(find.byKey(const Key('btn_readiness_checklist_banner')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 800));
      await tester.tap(find.text('Cập nhật trường'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 800));

      expect(_customFieldInput('Thành phần'), findsNothing);
      expect(_customFieldInput('Bảo quản'), findsOneWidget);
    },
  );
}
