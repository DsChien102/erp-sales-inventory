import 'package:erp/features/catalog/data/models.dart';
import 'package:erp/features/catalog/data/product_repository.dart';
import 'package:erp/features/catalog/logic/product_guided_create_cubit.dart';
import 'package:erp/features/catalog/presentation.dart';
import 'package:erp/features/catalog/presentation/pages/product_control_center_page.dart';
import 'package:erp/features/catalog/presentation/pages/product_guided_create_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

import '../../support/catalog_test_registry.dart';
import '../../support/fake_catalog_repositories.dart';
import '../../support/fake_catalog_scenario.dart';

final class _RecordingProductRepository extends FakeProductRepository {
  _RecordingProductRepository({required super.backend});

  CreateGuidedProductInput? guidedCreateCommand;

  @override
  Future<CreateGuidedProductResult> createGuided(CreateGuidedProductInput input) {
    guidedCreateCommand = input;
    return super.createGuided(input);
  }
}

void main() {
  final getIt = GetIt.instance;

  setUp(() async {
    await getIt.reset();
  });

  tearDown(() async {
    await getIt.reset();
  });

  Widget buildTestableWidget({
    String scenario = FakeCatalogScenario.guidedCreateOk,
    ProductRepository? repository,
  }) {
    registerFakeCatalog(getIt, scenario: scenario);
    if (repository != null) {
      getIt.unregister<ProductRepository>();
      getIt.registerSingleton<ProductRepository>(repository);
    }

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
              path: 'items/:productId',
              builder: (context, state) {
                final productId = state.pathParameters['productId']!;
                final initial = state.extra is ProductListItemModel
                    ? state.extra as ProductListItemModel
                    : (state.extra is ProductControlCenterRouteArgs
                        ? (state.extra as ProductControlCenterRouteArgs).product
                        : null);
                return ProductControlCenterPage(
                  productId: productId,
                  initialProduct: initial,
                );
              },
            ),
            GoRoute(
              path: 'items/:productId/view',
              builder: (context, state) {
                final productId = state.pathParameters['productId']!;
                final initial = state.extra is ProductListItemModel
                    ? state.extra as ProductListItemModel
                    : (state.extra is ProductControlCenterRouteArgs
                        ? (state.extra as ProductControlCenterRouteArgs).product
                        : null);
                return ProductControlCenterPage(
                  productId: productId,
                  initialProduct: initial,
                );
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
      buildTestableWidget(),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('wgt_e02_u01_fr01_01')), findsOneWidget);
    expect(find.text('Tạo nhanh sản phẩm'), findsOneWidget);
    expect(find.text('Lưu sản phẩm'), findsOneWidget);
  });

  testWidgets('wgt_e02_u01_fr01_01: successful create navigates to PCC', (tester) async {
    await tester.pumpWidget(
      buildTestableWidget(scenario: FakeCatalogScenario.guidedCreateOk),
    );
    await tester.pumpAndSettle();

    await enterGuidedName(tester, 'Amoxicillin 500mg');
    await tapSave(tester);

    // Success pops back to parent list route (canPop stack).
    expect(find.text('products-root'), findsOneWidget);
  });

  testWidgets('guided create preserves custom price band configuration', (tester) async {
    final backend = registerFakeCatalog(getIt);
    final recordingRepo = _RecordingProductRepository(backend: backend);
    await tester.pumpWidget(
      buildTestableWidget(repository: recordingRepo),
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

    final command = recordingRepo.guidedCreateCommand;
    expect(command, isNotNull);
    expect(command!.priceBandSourceType, PriceBandSourceType.customConfig);
    expect(command.listMarkupRatio, 0.3);
    expect(command.floorMarkupRatio, 0.1);
  });

  testWidgets('t93_sp03_manual_price_band_submits', (tester) async {
    final backend = registerFakeCatalog(getIt);
    final recordingRepo = _RecordingProductRepository(backend: backend);
    await tester.pumpWidget(
      buildTestableWidget(repository: recordingRepo),
    );
    await tester.pumpAndSettle();

    final pageContext = tester.element(find.byKey(const Key('wgt_e02_u01_fr01_01')));
    final cubit = BlocProvider.of<ProductGuidedCreateCubit>(pageContext);
    cubit
      ..updateName('Thuốc giá thủ công')
      ..updateBaseUnit('Lọ')
      ..updateBaseCost('50000')
      ..updatePricingMethod('manual')
      ..updateManualListPrice('80000')
      ..updateManualFloorPrice('60000')
      ..confirmPriceBandStep();
    await tester.pump();

    await cubit.submit();
    await tester.pumpAndSettle();

    final command = recordingRepo.guidedCreateCommand;
    expect(command, isNotNull);
    expect(command!.priceBandSourceType, PriceBandSourceType.manual);
    expect(command.useStorePriceRule, isFalse);
    expect(command.listBeforeVat, 80000);
    expect(command.floorBeforeVat, 60000);
  });

  testWidgets('saving without opening price step defaults to store rule', (tester) async {
    final backend = registerFakeCatalog(getIt);
    final recordingRepo = _RecordingProductRepository(backend: backend);
    await tester.pumpWidget(
      buildTestableWidget(repository: recordingRepo),
    );
    await tester.pumpAndSettle();

    final pageContext = tester.element(find.byKey(const Key('wgt_e02_u01_fr01_01')));
    final cubit = BlocProvider.of<ProductGuidedCreateCubit>(pageContext);
    cubit.updateName('Thuốc dùng giá cửa hàng');

    await cubit.submit();
    await tester.pumpAndSettle();

    final command = recordingRepo.guidedCreateCommand;
    expect(command, isNotNull);
    expect(command!.priceBandSourceType, PriceBandSourceType.ruleBased);
    expect(command.useStorePriceRule, isTrue);
  });

  testWidgets('saving a complete custom draft does not require pressing Next', (tester) async {
    final backend = registerFakeCatalog(getIt);
    final recordingRepo = _RecordingProductRepository(backend: backend);
    await tester.pumpWidget(
      buildTestableWidget(repository: recordingRepo),
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

    final command = recordingRepo.guidedCreateCommand;
    expect(command, isNotNull);
    expect(command!.priceBandSourceType, PriceBandSourceType.customConfig);
    expect(command.listMarkupRatio, 0.3);
    expect(command.floorMarkupRatio, 0.1);
  });

  testWidgets('skipping price draft resets it to store rule', (tester) async {
    final backend = registerFakeCatalog(getIt);
    final recordingRepo = _RecordingProductRepository(backend: backend);
    await tester.pumpWidget(
      buildTestableWidget(repository: recordingRepo),
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

    final command = recordingRepo.guidedCreateCommand;
    expect(command, isNotNull);
    expect(command!.priceBandSourceType, PriceBandSourceType.ruleBased);
    expect(command.useStorePriceRule, isTrue);
  });

  testWidgets('incomplete custom draft blocks save and opens price step', (tester) async {
    final backend = registerFakeCatalog(getIt);
    final recordingRepo = _RecordingProductRepository(backend: backend);
    await tester.pumpWidget(
      buildTestableWidget(repository: recordingRepo),
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

    expect(recordingRepo.guidedCreateCommand, isNull);
    expect(cubit.state.activeStepIndex, 4);
    expect(cubit.state.errorMessage, isNotNull);
  });

  testWidgets('wgt_e02_u01_fr01_01: missing name shows validation error', (tester) async {
    await tester.pumpWidget(
      buildTestableWidget(),
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
        scenario: FakeCatalogScenario.guidedCreateDupSku,
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

  testWidgets('guided_create_no_stock_step: no stock step or field in guided create', (
    tester,
  ) async {
    final backend = registerFakeCatalog(getIt);
    final recordingRepo = _RecordingProductRepository(backend: backend);
    await tester.pumpWidget(
      buildTestableWidget(repository: recordingRepo),
    );
    await tester.pumpAndSettle();

    expect(find.text('4. Tồn kho khởi tạo'), findsNothing);
    expect(find.textContaining('Tồn kho khởi tạo'), findsNothing);
    expect(find.byKey(const Key('input_guided_basic_stock_quantity_base')), findsNothing);

    await enterGuidedName(tester, 'Sản phẩm mới không tồn kho');
    await tapSave(tester);

    expect(recordingRepo.guidedCreateCommand, isNotNull);
  });
}
