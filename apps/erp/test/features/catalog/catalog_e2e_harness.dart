import 'package:erp/core/di/injection.dart';
import 'package:erp/core/supabase/supabase_module.dart';
import 'package:erp/features/catalog/presentation/pages/product_catalog_tab_page.dart';
import 'package:erp/features/catalog/presentation/pages/product_control_center_page.dart';
import 'package:erp/features/catalog/presentation/pages/product_custom_field_group_edit_page.dart';
import 'package:erp/features/catalog/presentation/pages/product_guided_create_page.dart';
import 'package:erp/features/catalog/presentation/pages/product_manual_base_price_page.dart';
import 'package:erp/features/catalog/presentation/pages/product_measurement_units_page.dart';
import 'package:erp/features/catalog/presentation/pages/product_readiness_checklist_page.dart';
import 'package:erp/features/catalog/presentation/pages/product_images_maintenance_page.dart';
import 'package:erp/features/catalog/presentation/pages/product_profile_maintenance_page.dart';
import 'package:erp/features/catalog/presentation/pages/product_stock_adjustment_page.dart';
import 'package:erp/features/catalog/presentation/pages/settings/custom_field_group_detail_page.dart';
import 'package:erp/features/catalog/presentation/pages/settings/custom_field_groups_page.dart';
import 'package:erp/features/catalog/presentation/pages/settings/upsert_custom_field_group_page.dart';
import 'package:erp/features/catalog/presentation/pages/settings/upsert_custom_field_page.dart';
import 'package:erp/features/catalog/presentation/widgets/product_control_center_operational_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:erp/features/catalog/presentation/pages/product_price_bands_page.dart';
import 'package:erp/features/catalog/presentation/pages/edit_product_unit_price_band_page.dart';
import 'package:vet45_catalog_application/application.dart' hide ProductChangeHistoryPage;
import 'package:vet45_catalog_application/testing.dart';
import 'package:vet45_catalog_presentation/presentation.dart';

import 'package:erp/features/catalog/presentation/pages/product_change_history_page.dart';
import 'package:vet45_shared_application/application.dart';
import 'package:vet45_shared_testing/shared_testing.dart';

ProductListItemModel productWithBaseUnit() {
  return const ProductListItemModel(
    id: 'product-1',
    name: 'Amoxicillin 500mg',
    businessStatus: ProductBusinessStatus.active,
    readinessStatus: ProductReadinessStatus.ready,
    baseUnit: 'Hộp',
  );
}

ProductListItemModel productWithoutBaseUnit() {
  return const ProductListItemModel(
    id: 'product-6',
    name: 'Thuốc thiếu đơn vị',
    businessStatus: ProductBusinessStatus.active,
    readinessStatus: ProductReadinessStatus.needsReview,
  );
}

Widget buildMeasurementUnitsRouter(ProductListItemModel product) {
  final router = GoRouter(
    initialLocation: '/products/items/pcc/units',
    routes: [
      GoRoute(
        path: '/products/items/pcc/units',
        builder: (context, state) => ProductMeasurementUnitsPage(product: product),
      ),
    ],
  );

  return MaterialApp.router(routerConfig: router);
}

class FakeGoTrueClient extends Fake implements GoTrueClient {
  @override
  User? get currentUser => null;
}

class FakeSupabaseClient extends Fake implements SupabaseClient {
  @override
  GoTrueClient get auth => FakeGoTrueClient();
}

Future<void> setUpErpCatalogE2E({
  String scenario = FakeCatalogScenario.guidedCreateOk,
  IPermissionChecker? permissionChecker,
}) async {
  await getIt.reset();
  await initDependencies(supabaseModule: SupabaseModule(FakeSupabaseClient()));
  await getIt.unregister<ICatalogModule>();
  await getIt.unregister<IExecutionContext>();
  if (permissionChecker != null && getIt.isRegistered<IPermissionChecker>()) {
    await getIt.unregister<IPermissionChecker>();
    getIt.registerSingleton<IPermissionChecker>(permissionChecker);
  }
  getIt
    ..registerSingleton<ICatalogModule>(FakeCatalogModule(scenario: scenario))
    ..registerSingleton<IExecutionContext>(
      FakeExecutionContext(tenantId: 'tenant-1', userId: 'user-1'),
    );
}

class _GuidedCreateE2ELauncher extends StatefulWidget {
  const _GuidedCreateE2ELauncher();

  @override
  State<_GuidedCreateE2ELauncher> createState() => _GuidedCreateE2ELauncherState();
}

class _GuidedCreateE2ELauncherState extends State<_GuidedCreateE2ELauncher> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _openGuidedCreate());
  }

  Future<void> _openGuidedCreate() async {
    final createdProduct = await context.push<ProductListItemModel>('/products/items/new');
    if (!mounted) return;
    if (createdProduct != null) {
      context.go(
        '/products/items/pcc',
        extra: ProductControlCenterRouteArgs(product: createdProduct),
      );
    }
  }

  @override
  Widget build(BuildContext context) => const Scaffold(body: SizedBox.shrink());
}

Widget buildCatalogPostCreateRouter() {
  final router = GoRouter(
    initialLocation: '/products/items',
    routes: [
      GoRoute(
        path: '/products/items',
        builder: (context, state) => const _GuidedCreateE2ELauncher(),
      ),
      GoRoute(
        path: '/products/items/new',
        builder: (context, state) => const ProductGuidedCreatePage(),
      ),
      GoRoute(
        path: '/products/items/pcc',
        builder: (context, state) {
          final args = state.extra as ProductControlCenterRouteArgs;
          return ProductControlCenterPage(product: args.product);
        },
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
      GoRoute(
        path: '/products/items/pcc/stock',
        builder: (context, state) {
          final args = state.extra as ProductStockAdjustmentRouteArgs;
          return ProductStockAdjustmentPage(args: args);
        },
      ),
      GoRoute(
        path: '/products/items/pcc/manual-base-price',
        builder: (context, state) {
          final args = state.extra as ProductManualBasePriceRouteArgs;
          return ProductManualBasePricePage(
            product: args.product,
            basePriceCard: args.basePriceCard,
          );
        },
      ),
    ],
  );

  return MaterialApp.router(routerConfig: router);
}

/// Back-compat alias for US-01 E2E (same routes; checklist route unused).
Widget buildGuidedCreateRouter() => buildCatalogPostCreateRouter();

Widget buildCatalogDiscoveryRouter() {
  final router = GoRouter(
    initialLocation: '/products/items',
    routes: [
      GoRoute(
        path: '/products/items',
        builder: (context, state) => const ProductCatalogTabPage(),
      ),
      GoRoute(
        path: '/products/items/new',
        builder: (context, state) => const ProductGuidedCreatePage(),
      ),
      GoRoute(
        path: '/products/items/pcc',
        builder: (context, state) {
          final args = state.extra as ProductControlCenterRouteArgs;
          return ProductControlCenterPage(product: args.product);
        },
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
      GoRoute(
        path: '/products/items/pcc/stock',
        builder: (context, state) {
          final args = state.extra as ProductStockAdjustmentRouteArgs;
          return ProductStockAdjustmentPage(args: args);
        },
      ),
      GoRoute(
        path: '/products/items/pcc/manual-base-price',
        builder: (context, state) {
          final args = state.extra as ProductManualBasePriceRouteArgs;
          return ProductManualBasePricePage(
            product: args.product,
            basePriceCard: args.basePriceCard,
          );
        },
      ),
      GoRoute(
        path: '/products/items/pcc/price-bands',
        builder: (context, state) {
          final args = state.extra as ProductPriceBandsRouteArgs;
          return ProductPriceBandsPage(
            args: args,
          );
        },
      ),
      GoRoute(
        path: '/products/items/pcc/edit-price-band',
        builder: (context, state) {
          final args = state.extra as EditProductUnitPriceBandRouteArgs;
          return EditProductUnitPriceBandPage(
            args: args,
          );
        },
      ),
      GoRoute(
        path: '/products/items/pcc/profile-maintenance',
        builder: (context, state) {
          final product = state.extra as ProductListItemModel;
          return ProductProfileMaintenancePage(product: product);
        },
      ),
      GoRoute(
        path: '/products/items/pcc/images-maintenance',
        builder: (context, state) {
          final product = state.extra as ProductListItemModel;
          return ProductImagesMaintenancePage(product: product);
        },
      ),
      GoRoute(
        path: '/products/items/pcc/custom-fields/edit',
        builder: (context, state) {
          final args = state.extra as ProductCustomFieldGroupEditRouteArgs;
          return ProductCustomFieldGroupEditPage(args: args);
        },
      ),
      GoRoute(
        path: '/products/items/pcc/change-history',
        builder: (context, state) {
          final product = state.extra as ProductListItemModel;
          return ProductChangeHistoryPage(
            productId: product.id,
            productName: product.name,
          );
        },
      ),
    ],
  );

  return MaterialApp.router(routerConfig: router);
}

Widget buildCustomFieldSettingsRouter() {
  final router = GoRouter(
    initialLocation: '/more/product-settings/custom-fields',
    routes: [
      GoRoute(
        path: '/more/product-settings/custom-fields',
        builder: (context, state) => const CustomFieldGroupsPage(),
      ),
      GoRoute(
        path: '/more/product-settings/custom-fields/upsert-group',
        builder: (context, state) {
          final cubit = state.extra as CustomFieldConfigCubit?;
          if (cubit == null) {
            return const Scaffold(body: Center(child: CircularProgressIndicator()));
          }
          final groupId = state.uri.queryParameters['groupId'];
          return UpsertCustomFieldGroupPage(cubit: cubit, initialGroupId: groupId);
        },
      ),
      GoRoute(
        path: '/more/product-settings/custom-fields/:groupId',
        builder: (context, state) {
          final groupId = state.pathParameters['groupId']!;
          final cubit = state.extra as CustomFieldConfigCubit?;
          if (cubit == null) {
            return const Scaffold(body: Center(child: CircularProgressIndicator()));
          }
          return CustomFieldGroupDetailPage(groupId: groupId, cubit: cubit);
        },
      ),
      GoRoute(
        path: '/more/product-settings/custom-fields/:groupId/upsert-field',
        builder: (context, state) {
          final groupId = state.pathParameters['groupId']!;
          final cubit = state.extra as CustomFieldConfigCubit?;
          if (cubit == null) {
            return const Scaffold(body: Center(child: CircularProgressIndicator()));
          }
          final fieldId = state.uri.queryParameters['fieldId'];
          return UpsertCustomFieldPage(groupId: groupId, cubit: cubit, initialFieldId: fieldId);
        },
      ),
    ],
  );

  return MaterialApp.router(routerConfig: router);
}

Future<void> tapEditProfile(WidgetTester tester) async {
  final profileCard = find.widgetWithText(ProductControlCenterSectionCard, 'Hồ sơ sản phẩm');
  await tester.ensureVisible(profileCard);
  await tester.tap(profileCard);
  await tester.pumpAndSettle();
}

Future<void> tapEditImages(WidgetTester tester) async {
  final imagesCard = find.widgetWithText(ProductControlCenterSectionCard, 'Ảnh sản phẩm');
  await tester.ensureVisible(imagesCard);
  await tester.tap(imagesCard);
  await tester.pumpAndSettle();
}

Widget buildPccMaintenanceRouter(ProductListItemModel product) {
  final router = GoRouter(
    initialLocation: '/products/items/pcc',
    routes: [
      GoRoute(
        path: '/products/items/pcc',
        builder: (context, state) => ProductControlCenterPage(product: product),
      ),
      GoRoute(
        path: '/products/items/pcc/profile-maintenance',
        builder: (context, state) {
          final maintenanceProduct = state.extra as ProductListItemModel;
          return ProductProfileMaintenancePage(product: maintenanceProduct);
        },
      ),
      GoRoute(
        path: '/products/items/pcc/images-maintenance',
        builder: (context, state) {
          final maintenanceProduct = state.extra as ProductListItemModel;
          return ProductImagesMaintenancePage(product: maintenanceProduct);
        },
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
    ],
  );

  return MaterialApp.router(routerConfig: router);
}

Future<void> tapEditStock(WidgetTester tester) async {
  final stockCard = find.widgetWithText(ProductControlCenterSectionCard, 'Tồn kho');
  await tester.ensureVisible(stockCard);
  await tester.tap(find.descendant(of: stockCard, matching: find.text('Sửa')));
  await tester.pumpAndSettle();
}

Future<void> tapEditBasePrice(WidgetTester tester) async {
  final basePriceCard = find.widgetWithText(ProductControlCenterSectionCard, 'Giá cơ sở');
  await tester.ensureVisible(basePriceCard);
  await tester.tap(find.descendant(of: basePriceCard, matching: find.text('Sửa')));
  await tester.pumpAndSettle();
}

Future<void> tapEditPriceBand(WidgetTester tester) async {
  final priceBandCard = find.widgetWithText(ProductControlCenterSectionCard, 'Khung giá');
  await tester.ensureVisible(priceBandCard);
  await tester.tap(find.descendant(of: priceBandCard, matching: find.text('Sửa')));
  await tester.pumpAndSettle();
}

Future<void> tapEditCustomFieldGroup(WidgetTester tester, String groupName) async {
  final card = find.widgetWithText(ProductControlCenterSectionCard, groupName);
  await tester.ensureVisible(card);
  await tester.tap(find.descendant(of: card, matching: find.text('Sửa')));
  await tester.pumpAndSettle();
}

Future<void> openPriceBandEditor(WidgetTester tester) async {
  await tapEditPriceBand(tester);
  await tester.tap(find.text('Sửa'));
  await tester.pumpAndSettle();
}

Widget buildPccPriceBandRouter(ProductListItemModel product) {
  final router = GoRouter(
    initialLocation: '/products/items/pcc',
    routes: [
      GoRoute(
        path: '/products/items/pcc',
        builder: (context, state) => ProductControlCenterPage(product: product),
      ),
      GoRoute(
        path: '/products/items/pcc/price-bands',
        builder: (context, state) {
          final args = state.extra as ProductPriceBandsRouteArgs;
          return ProductPriceBandsPage(
            args: args,
          );
        },
      ),
      GoRoute(
        path: '/products/items/pcc/edit-price-band',
        builder: (context, state) {
          final args = state.extra as EditProductUnitPriceBandRouteArgs;
          return EditProductUnitPriceBandPage(
            args: args,
          );
        },
      ),
    ],
  );

  return MaterialApp.router(routerConfig: router);
}

Future<void> createMinimalProduct(
  WidgetTester tester, {
  String name = 'Amoxicillin 100ml',
  String? baseUnit,
}) async {
  await tester.enterText(find.byKey(const Key('input_guided_name')), name);
  await tester.pump();

  if (baseUnit != null) {
    final stepFinder = find.text('3. Đơn vị cơ sở');
    await tester.scrollUntilVisible(
      stepFinder,
      500,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(stepFinder);
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('input_guided_base_unit')),
      baseUnit,
    );
    await tester.pump();
  }

  await tester.tap(find.byKey(const Key('btn_guided_save')));
  await tester.pumpAndSettle();
}
