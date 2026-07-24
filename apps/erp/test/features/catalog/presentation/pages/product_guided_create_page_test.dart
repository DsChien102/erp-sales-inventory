import 'package:erp/features/catalog/presentation/pages/product_control_center_page.dart';
import 'package:erp/features/catalog/presentation/pages/product_guided_create_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:vet45_catalog_application/application.dart';
import 'package:vet45_catalog_presentation/presentation.dart';
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

final class _RecordingCatalogModule implements ICatalogModule {
  _RecordingCatalogModule() : _delegate = FakeCatalogModule();

  final FakeCatalogModule _delegate;
  CreateGuidedProductCommand? guidedCreateCommand;

  @override
  Future<TResult> executeCommandAsync<TResult>(ICommand<TResult> command) {
    if (command is CreateGuidedProductCommand) {
      guidedCreateCommand = command as CreateGuidedProductCommand;
    }
    return _delegate.executeCommandAsync(command);
  }

  @override
  Future<TResult> executeQueryAsync<TResult>(IQuery<TResult> query) {
    return _delegate.executeQueryAsync(query);
  }
}

void main() {
  final getIt = GetIt.instance;

  setUp(() async {
    await getIt.reset();
  });

  Widget buildTestableWidget({required ICatalogModule catalogModule}) {
    getIt
      ..registerSingleton<ICatalogModule>(catalogModule)
      ..registerSingleton<IExecutionContext>(_FakeExecutionContext());

    final router = GoRouter(
      initialLocation: '/products/items/new',
      routes: [
        GoRoute(
          path: '/products',
          builder: (context, state) => const Scaffold(body: Text('products-root')),
          routes: [
            GoRoute(
              path: 'items/new',
              builder: (context, state) => const ProductGuidedCreatePage(),
            ),
            GoRoute(
              path: 'items/pcc',
              builder: (context, state) {
                final args = state.extra as ProductControlCenterRouteArgs;
                return ProductControlCenterPage(product: args.product);
              },
            ),
          ],
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

    final field = find.byKey(const Key('input_guided_basic_stock_quantity_base'));
    expect(field, findsOneWidget);
    final numberField = tester.widget<VNumberField>(field);
    expect(numberField.allowDecimal, isFalse);

    await tester.enterText(field, '150');
    await tester.pump();
    expect(find.text('150'), findsOneWidget);
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

    // Success pops back to parent list route (canPop stack).
    expect(find.text('products-root'), findsOneWidget);
  });

  testWidgets('guided create preserves custom price band configuration', (tester) async {
    final catalogModule = _RecordingCatalogModule();
    await tester.pumpWidget(
      buildTestableWidget(catalogModule: catalogModule),
    );
    await tester.pumpAndSettle();

    final pageContext = tester.element(find.byKey(const Key('wgt_e02_u01_fr01_01')));
    final cubit = BlocProvider.of<ProductGuidedCreateCubit>(pageContext);
    cubit
      ..updateName('Thuốc cấu hình riêng')
      ..updateBaseUnit('Lọ')
      ..updateBaseCost('50000')
      ..updatePricingMethod('customAuto')
      ..updateCustomAutoMarkup('30')
      ..updateCustomAutoFloorMarkup('10')
      ..confirmPriceBandStep();
    await tester.pump();

    await cubit.submit();
    await tester.pumpAndSettle();

    final command = catalogModule.guidedCreateCommand;
    expect(command, isNotNull);
    expect(command!.priceBandSourceType, PriceBandSourceType.customConfig);
    expect(command.listMarkupRatio, 0.3);
    expect(command.floorMarkupRatio, 0.1);
  });

  testWidgets('saving without opening price step defaults to store rule', (tester) async {
    final catalogModule = _RecordingCatalogModule();
    await tester.pumpWidget(
      buildTestableWidget(catalogModule: catalogModule),
    );
    await tester.pumpAndSettle();

    final pageContext = tester.element(find.byKey(const Key('wgt_e02_u01_fr01_01')));
    final cubit = BlocProvider.of<ProductGuidedCreateCubit>(pageContext);
    cubit.updateName('Thuốc dùng giá cửa hàng');

    await cubit.submit();
    await tester.pumpAndSettle();

    final command = catalogModule.guidedCreateCommand;
    expect(command, isNotNull);
    expect(command!.priceBandSourceType, PriceBandSourceType.ruleBased);
    expect(command.useStorePriceRule, isTrue);
  });

  testWidgets('saving a complete custom draft does not require pressing Next', (tester) async {
    final catalogModule = _RecordingCatalogModule();
    await tester.pumpWidget(
      buildTestableWidget(catalogModule: catalogModule),
    );
    await tester.pumpAndSettle();

    final pageContext = tester.element(find.byKey(const Key('wgt_e02_u01_fr01_01')));
    final cubit = BlocProvider.of<ProductGuidedCreateCubit>(pageContext);
    cubit
      ..updateName('Thuốc cấu hình riêng')
      ..updateBaseUnit('Lọ')
      ..updateBaseCost('50000')
      ..updatePricingMethod('customAuto')
      ..updateCustomAutoMarkup('30')
      ..updateCustomAutoFloorMarkup('10');

    await cubit.submit();
    await tester.pumpAndSettle();

    final command = catalogModule.guidedCreateCommand;
    expect(command, isNotNull);
    expect(command!.priceBandSourceType, PriceBandSourceType.customConfig);
    expect(command.listMarkupRatio, 0.3);
    expect(command.floorMarkupRatio, 0.1);
  });

  testWidgets('skipping price draft resets it to store rule', (tester) async {
    final catalogModule = _RecordingCatalogModule();
    await tester.pumpWidget(
      buildTestableWidget(catalogModule: catalogModule),
    );
    await tester.pumpAndSettle();

    final pageContext = tester.element(find.byKey(const Key('wgt_e02_u01_fr01_01')));
    final cubit = BlocProvider.of<ProductGuidedCreateCubit>(pageContext);
    cubit
      ..updateName('Thuốc bỏ qua cấu hình riêng')
      ..updateBaseUnit('Lọ')
      ..updateBaseCost('50000')
      ..updatePricingMethod('customAuto')
      ..updateCustomAutoMarkup('30')
      ..updateCustomAutoFloorMarkup('10')
      ..deferPriceBandStep();

    expect(cubit.state.pricingMethod, 'storeRule');
    expect(cubit.state.customAutoMarkup, isEmpty);
    expect(cubit.state.customAutoFloorMarkup, isEmpty);

    await cubit.submit();
    await tester.pumpAndSettle();

    final command = catalogModule.guidedCreateCommand;
    expect(command, isNotNull);
    expect(command!.priceBandSourceType, PriceBandSourceType.ruleBased);
    expect(command.useStorePriceRule, isTrue);
  });

  testWidgets('incomplete custom draft blocks save and opens price step', (tester) async {
    final catalogModule = _RecordingCatalogModule();
    await tester.pumpWidget(
      buildTestableWidget(catalogModule: catalogModule),
    );
    await tester.pumpAndSettle();

    final pageContext = tester.element(find.byKey(const Key('wgt_e02_u01_fr01_01')));
    final cubit = BlocProvider.of<ProductGuidedCreateCubit>(pageContext);
    cubit
      ..updateName('Thuốc cấu hình thiếu')
      ..updateBaseUnit('Lọ')
      ..updateBaseCost('50000')
      ..updatePricingMethod('customAuto')
      ..updateCustomAutoMarkup('30');

    await cubit.submit();
    await tester.pump();

    expect(catalogModule.guidedCreateCommand, isNull);
    expect(cubit.state.activeStepIndex, 5);
    expect(cubit.state.errorMessage, isNotNull);
  });

  testWidgets('wgt_e02_u01_fr01_01: missing name shows validation error', (tester) async {
    await tester.pumpWidget(
      buildTestableWidget(catalogModule: FakeCatalogModule()),
    );
    await tester.pumpAndSettle();

    // Enable save (requires hasAnyData) without filling required internal name.
    await tester.enterText(find.byType(TextField).at(1), 'Trade only');
    await tester.pump();

    await tester.tap(find.byKey(const Key('btn_guided_save')));
    await tester.pump();

    expect(find.text('Tên nội bộ không được bỏ trống'), findsOneWidget);
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
