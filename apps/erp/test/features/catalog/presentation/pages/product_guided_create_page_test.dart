import 'package:erp/features/catalog/presentation/pages/product_control_center_page.dart';
import 'package:erp/features/catalog/presentation/pages/product_guided_create_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:vet45_catalog_application/application.dart';
import 'package:vet45_catalog_application/testing.dart';
import 'package:vet45_shared_application/application.dart';
import 'package:vet45_design_system/design_system.dart';

final class _FakeExecutionContext implements IExecutionContext {
  @override
  String get correlationId => 'test-correlation';

  @override
  Future<String> requireTenantId() async => 'tenant-1';

  @override
  Future<String> requireUserId() async => 'user-1';
}

void main() {
  final getIt = GetIt.instance;

  setUp(() async {
    await getIt.reset();
  });

  Widget buildTestableWidget({required FakeCatalogModule catalogModule}) {
    getIt
      ..registerSingleton<ICatalogModule>(catalogModule)
      ..registerSingleton<IExecutionContext>(_FakeExecutionContext());

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

  Future<void> enterGuidedName(WidgetTester tester, String value) async {
    await tester.enterText(find.byKey(const Key('input_guided_name')), value);
    await tester.pump();
  }

  Future<void> enterGuidedSku(WidgetTester tester, String value) async {
    await tester.enterText(find.byKey(const Key('input_guided_sku')), value);
    await tester.pump();
  }

  Future<void> tapSave(WidgetTester tester) async {
    await tester.tap(find.byKey(const Key('btn_guided_save')));
    await tester.pumpAndSettle();
  }

  testWidgets('wgt_e02_u01_fr01_01: guided create page renders', (tester) async {
    await tester.pumpWidget(
      buildTestableWidget(catalogModule: FakeCatalogModule()),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('wgt_e02_u01_fr01_01')), findsOneWidget);
    expect(find.text('Tạo nhanh sản phẩm'), findsOneWidget);
    expect(find.text('Lưu sản phẩm'), findsOneWidget);
  });

  testWidgets('initial stock uses Design System integer field', (tester) async {
    await tester.pumpWidget(
      buildTestableWidget(catalogModule: FakeCatalogModule()),
    );
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('3. Đơn vị cơ sở'));
    await tester.tap(find.text('3. Đơn vị cơ sở'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('input_guided_base_unit')), 'Hộp');
    await tester.pump();
    await tester.ensureVisible(find.text('4. Tồn kho khởi tạo'));
    await tester.tap(find.text('4. Tồn kho khởi tạo'));
    await tester.pumpAndSettle();

    final field = find.byKey(const Key('input_guided_initial_stock'));
    expect(field, findsOneWidget);
    expect(tester.widget(field), isA<VNumberField>());

    await tester.enterText(field, '-12abc.5');
    await tester.pump();
    expect(find.text('125'), findsOneWidget);
  });

  testWidgets('wgt_e02_u01_fr01_01: successful create navigates to PCC', (tester) async {
    await tester.pumpWidget(
      buildTestableWidget(
        catalogModule: FakeCatalogModule(scenario: FakeCatalogScenario.guidedCreateOk),
      ),
    );
    await tester.pumpAndSettle();

    await enterGuidedName(tester, 'Amoxicillin 500mg');
    await tapSave(tester);

    expect(find.text('Amoxicillin 500mg'), findsWidgets);
  });

  testWidgets('wgt_e02_u01_fr01_01: missing name shows validation error', (tester) async {
    await tester.pumpWidget(
      buildTestableWidget(catalogModule: FakeCatalogModule()),
    );
    await tester.pumpAndSettle();

    await tapSave(tester);

    expect(find.text('Vui lòng nhập tên nội bộ sản phẩm.'), findsOneWidget);
  });

  testWidgets('wgt_e02_u01_fr01_01: duplicate SKU opens existing product in PCC', (tester) async {
    await tester.pumpWidget(
      buildTestableWidget(
        catalogModule: FakeCatalogModule(scenario: FakeCatalogScenario.guidedCreateDupSku),
      ),
    );
    await tester.pumpAndSettle();

    await enterGuidedName(tester, 'Thuốc A');
    await enterGuidedSku(tester, 'SKU-001');
    await tapSave(tester);

    expect(find.byKey(const Key('btn_open_duplicate_product')), findsOneWidget);
    expect(find.textContaining('Existing Product'), findsOneWidget);

    await tester.tap(find.byKey(const Key('btn_open_duplicate_product')));
    await tester.pumpAndSettle();

    expect(find.text('Existing Product'), findsWidgets);
    expect(find.text('Thiếu dữ liệu'), findsOneWidget);
  });
}
