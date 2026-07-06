import 'package:erp/core/di/injection.dart';
import 'package:erp/core/supabase/supabase_module.dart';
import 'package:erp/features/catalog/presentation/pages/product_control_center_page.dart';
import 'package:erp/features/catalog/presentation/pages/product_guided_create_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vet45_catalog_application/application.dart';
import 'package:vet45_catalog_application/testing.dart';
import 'package:vet45_shared_application/application.dart';
import 'package:vet45_shared_testing/shared_testing.dart';

class _FakeGoTrueClient extends Fake implements GoTrueClient {
  @override
  User? get currentUser => null;
}

class _FakeSupabaseClient extends Fake implements SupabaseClient {
  @override
  GoTrueClient get auth => _FakeGoTrueClient();
}

Future<void> setUpErpCatalogE2E({String scenario = FakeCatalogScenario.guidedCreateOk}) async {
  await getIt.reset();
  await initDependencies(supabaseModule: SupabaseModule(_FakeSupabaseClient()));
  await getIt.unregister<ICatalogModule>();
  await getIt.unregister<IExecutionContext>();
  getIt
    ..registerSingleton<ICatalogModule>(FakeCatalogModule(scenario: scenario))
    ..registerSingleton<IExecutionContext>(
      FakeExecutionContext(tenantId: 'tenant-1', userId: 'user-1'),
    );
}

Widget buildGuidedCreateRouter() {
  final router = GoRouter(
    initialLocation: '/products/items/new',
    routes: [
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

  testWidgets('e2e_e02_u01_fr01_01: guided create via ERP DI navigates to PCC', (tester) async {
    await setUpErpCatalogE2E();

    expect(getIt.isRegistered<ICatalogModule>(), isTrue);
    expect(getIt<ICatalogModule>(), isA<FakeCatalogModule>());

    await tester.pumpWidget(buildGuidedCreateRouter());
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('wgt_e02_u01_fr01_01')), findsOneWidget);

    await tester.enterText(find.byKey(const Key('input_guided_name')), 'Amoxicillin 100ml');
    await tester.pump();
    await tester.tap(find.byKey(const Key('btn_guided_save')));
    await tester.pumpAndSettle();

    expect(find.text('Amoxicillin 100ml'), findsWidgets);
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
    await tester.enterText(find.byKey(const Key('input_guided_initial_stock')), '150');
    await tester.pump();

    // Open Step 5: Giá vốn cơ sở
    final step5Finder = find.text('5. Giá vốn cơ sở');
    await tester.ensureVisible(step5Finder);
    await tester.tap(step5Finder);
    await tester.pumpAndSettle();

    // Fill Base Cost
    await tester.enterText(find.byKey(const Key('input_guided_base_cost')), '5000');
    await tester.pump();

    // Save product
    await tester.tap(find.byKey(const Key('btn_guided_save')));
    await tester.pumpAndSettle();

    // Verify PCC is reached and shows the created product
    expect(find.text('Paracetamol 500mg'), findsWidgets);
    expect(find.text('Tồn (Hộp): 150'), findsOneWidget);
    expect(find.text('Giá niêm yết: 6.750 đ'), findsOneWidget);
    expect(find.text('Tồn kho: 150 Hộp'), findsOneWidget);
    expect(find.text('Giá vốn: 5.000 đ (Hộp)'), findsOneWidget);
    expect(find.text('Khung giá bán'), findsOneWidget);
    expect(
      find.text('Niêm yết: 6.750 đ · Sàn: 5.750 đ · Đơn vị: Hộp'),
      findsOneWidget,
    );
  });
}
