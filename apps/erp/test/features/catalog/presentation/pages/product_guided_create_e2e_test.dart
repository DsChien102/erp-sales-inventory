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
}
