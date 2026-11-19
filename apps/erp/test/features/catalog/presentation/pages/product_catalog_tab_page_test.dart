import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:erp/features/catalog/data/models.dart';
import 'package:erp/features/catalog/data/product_repository.dart';
import 'package:erp/features/catalog/presentation/pages/product_catalog_tab_page.dart';
import 'package:erp/features/catalog/presentation/widgets/product_list_item_tile.dart';
import 'package:erp/features/catalog/logic/product_list_cubit.dart';
import 'package:go_router/go_router.dart';

import '../../support/catalog_test_registry.dart';
import '../../support/fake_catalog_backend.dart';
import '../../support/fake_catalog_repositories.dart';
import '../../support/fake_catalog_scenario.dart';
import '../../support/recording_catalog_repositories.dart';

final class _FilterErrorProductRepository extends FakeProductRepository {
  _FilterErrorProductRepository({required super.backend});

  @override
  Future<List<CustomFieldFilterOptionDto>> listCustomFieldFilterOptions({
    int maxOptionsPerField = 50,
  }) async {
    throw Exception('Failed to load filter options');
  }
}

void main() {
  final getIt = GetIt.instance;

  setUp(() async {
    await getIt.reset();
  });

  Widget buildTestableWidget({String scenario = FakeCatalogScenario.searchEmpty}) {
    registerFakeCatalog(getIt, scenario: scenario);

    final router = GoRouter(
      initialLocation: '/products',
      routes: [
        GoRoute(
          path: '/products',
          builder: (context, state) => const ProductCatalogTabPage(),
        ),
      ],
    );

    return MaterialApp.router(
      routerConfig: router,
    );
  }

  testWidgets('wgt_e01_u01_fr01_01: Render product list page and search bar', (tester) async {
    await tester.pumpWidget(buildTestableWidget(scenario: FakeCatalogScenario.searchEmpty));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('wgt_e01_u01_fr01_01')), findsOneWidget);
    expect(
      find.text('Tìm tên, SKU, barcode, thông tin bổ sung...'),
      findsOneWidget,
    );
    expect(find.text('Chưa có sản phẩm nào được tạo'), findsOneWidget);
  });

  testWidgets('e2e_e01_u01_fr01_01: keyword search returns matching products', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildTestableWidget(scenario: FakeCatalogScenario.searchWithReadiness),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('input_product_search')), findsOneWidget);

    await tester.enterText(find.byKey(const Key('input_product_search')), 'amox');
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pumpAndSettle();

    expect(find.textContaining('Amoxicillin'), findsWidgets);
  });

  testWidgets('H2: filter options loading error is ignored and product list is still displayed', (
    tester,
  ) async {
    final backend = FakeCatalogBackend(scenario: FakeCatalogScenario.searchWithReadiness);
    final errorRepo = _FilterErrorProductRepository(backend: backend);
    getIt.registerSingleton<ProductRepository>(errorRepo);

    final router = GoRouter(
      initialLocation: '/products',
      routes: [
        GoRoute(
          path: '/products',
          builder: (context, state) => const ProductCatalogTabPage(),
        ),
      ],
    );

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    // Verify product list is still displayed despite filter loading error
    expect(find.textContaining('Amoxicillin'), findsWidgets);
  });

  group('B3', () {
    ProductSearchResultDto buildTestResult(ProductSearchCriteria _) {
      final items = [
        ProductListItemDto(
          id: 'p1',
          name: 'P1',
          businessStatus: ProductBusinessStatus.active,
          readinessSummary: const ReadinessSummaryDto(
            status: ReadinessStatus.readyToSell,
          ),
          stockQuantity: 10,
          updatedAt: DateTime(2026, 1, 1),
        ),
        ProductListItemDto(
          id: 'p2',
          name: 'P2',
          businessStatus: ProductBusinessStatus.active,
          readinessSummary: const ReadinessSummaryDto(
            status: ReadinessStatus.readyToSell,
          ),
          stockQuantity: 10,
          updatedAt: DateTime(2026, 1, 1),
        ),
        ProductListItemDto(
          id: 'p3',
          name: 'P3',
          businessStatus: ProductBusinessStatus.active,
          readinessSummary: const ReadinessSummaryDto(
            status: ReadinessStatus.readyToSell,
          ),
          stockQuantity: 10,
          updatedAt: DateTime(2026, 1, 1),
        ),
        ProductListItemDto(
          id: 'p4',
          name: 'P4',
          businessStatus: ProductBusinessStatus.active,
          readinessSummary: const ReadinessSummaryDto(
            status: ReadinessStatus.incomplete,
          ),
          stockQuantity: 10,
          updatedAt: DateTime(2026, 1, 1),
        ),
        ProductListItemDto(
          id: 'p5',
          name: 'P5',
          businessStatus: ProductBusinessStatus.active,
          readinessSummary: const ReadinessSummaryDto(
            status: ReadinessStatus.incomplete,
          ),
          stockQuantity: 0,
          updatedAt: DateTime(2026, 1, 1),
        ),
        ProductListItemDto(
          id: 'p6',
          name: 'P6',
          businessStatus: ProductBusinessStatus.inactive,
          readinessSummary: const ReadinessSummaryDto(
            status: ReadinessStatus.incomplete,
          ),
          stockQuantity: 0,
          updatedAt: DateTime(2026, 1, 1),
        ),
      ];

      return ProductSearchResultDto(
        items: items,
        totalCount: 6,
        readyToSellCount: 3,
        incompleteCount: 2,
        inactiveCount: 1,
      );
    }

    testWidgets('b3_chip_counts', (tester) async {
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final backend = registerFakeCatalog(getIt);
      final recordingRepo = RecordingProductRepository(
        backend: backend,
        respond: buildTestResult,
      );
      getIt.unregister<ProductRepository>();
      getIt.registerSingleton<ProductRepository>(recordingRepo);

      final router = GoRouter(
        initialLocation: '/products',
        routes: [
          GoRoute(
            path: '/products',
            builder: (context, state) => const ProductCatalogTabPage(),
          ),
        ],
      );

      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('Tất cả (6)'), findsOneWidget);
      expect(find.text('Sẵn sàng bán (3)'), findsOneWidget);
      expect(find.text('Thiếu dữ liệu (2)'), findsOneWidget);
      expect(find.text('Ngừng KD (1)'), findsOneWidget);
      expect(find.text('Còn hàng (4)'), findsOneWidget);
      expect(find.text('Hết hàng (2)'), findsOneWidget);
    });

    testWidgets('b3_chip_criteria', (tester) async {
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final backend = registerFakeCatalog(getIt);
      final recordingRepo = RecordingProductRepository(
        backend: backend,
        respond: buildTestResult,
      );
      getIt.unregister<ProductRepository>();
      getIt.registerSingleton<ProductRepository>(recordingRepo);

      final router = GoRouter(
        initialLocation: '/products',
        routes: [
          GoRoute(
            path: '/products',
            builder: (context, state) => const ProductCatalogTabPage(),
          ),
        ],
      );

      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Tap "Sẵn sàng bán"
      await tester.ensureVisible(find.text('Sẵn sàng bán (3)'));
      await tester.tap(find.text('Sẵn sàng bán (3)'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      var c = recordingRepo.criteria.last;
      expect(c.businessStatuses, {ProductBusinessStatus.active, ProductBusinessStatus.inactive});
      expect(c.readinessFilter, ProductReadinessFilter.readyToSell);
      expect(c.includeSoftDeleted, false);

      // Tap "Thiếu dữ liệu"
      await tester.ensureVisible(find.text('Thiếu dữ liệu (2)'));
      await tester.tap(find.text('Thiếu dữ liệu (2)'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      c = recordingRepo.criteria.last;
      expect(c.businessStatuses, {ProductBusinessStatus.active, ProductBusinessStatus.inactive});
      expect(c.readinessFilter, ProductReadinessFilter.incomplete);
      expect(c.includeSoftDeleted, false);

      // Tap "Ngừng KD"
      await tester.ensureVisible(find.text('Ngừng KD (1)'));
      await tester.tap(find.text('Ngừng KD (1)'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      c = recordingRepo.criteria.last;
      expect(c.businessStatuses, {ProductBusinessStatus.inactive});
      expect(c.readinessFilter, isNull);
      expect(c.includeSoftDeleted, false);

      // Tap "Còn hàng"
      await tester.ensureVisible(find.text('Còn hàng (4)'));
      await tester.tap(find.text('Còn hàng (4)'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      c = recordingRepo.criteria.last;
      expect(c.businessStatuses, {ProductBusinessStatus.active, ProductBusinessStatus.inactive});
      expect(c.readinessFilter, isNull);
      expect(c.includeSoftDeleted, false);

      // Tap "Hết hàng"
      await tester.ensureVisible(find.text('Hết hàng (2)'));
      await tester.tap(find.text('Hết hàng (2)'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      c = recordingRepo.criteria.last;
      expect(c.businessStatuses, {ProductBusinessStatus.active, ProductBusinessStatus.inactive});
      expect(c.readinessFilter, isNull);
      expect(c.includeSoftDeleted, false);

      // Tap "Tất cả"
      await tester.ensureVisible(find.text('Tất cả (6)'));
      await tester.tap(find.text('Tất cả (6)'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      c = recordingRepo.criteria.last;
      expect(c.businessStatuses, {ProductBusinessStatus.active, ProductBusinessStatus.inactive});
      expect(c.readinessFilter, isNull);
      expect(c.includeSoftDeleted, false);
    });
  });

  group('G2', () {
    ProductSearchResultDto respondWithDeleted(ProductSearchCriteria criteria) {
      if (criteria.includeSoftDeleted) {
        final items = [
          ProductListItemDto(
            id: 'pd1',
            name: 'Đã xóa 1',
            businessStatus: ProductBusinessStatus.softDeleted,
            readinessSummary: const ReadinessSummaryDto(
              status: ReadinessStatus.incomplete,
            ),
            updatedAt: DateTime(2026, 1, 1),
          ),
          ProductListItemDto(
            id: 'pd2',
            name: 'Đã xóa 2',
            businessStatus: ProductBusinessStatus.softDeleted,
            readinessSummary: const ReadinessSummaryDto(
              status: ReadinessStatus.incomplete,
            ),
            updatedAt: DateTime(2026, 1, 1),
          ),
        ];
        return ProductSearchResultDto(
          items: items,
          totalCount: 2,
        );
      }

      final items = [
        ProductListItemDto(
          id: 'p1',
          name: 'P1',
          businessStatus: ProductBusinessStatus.active,
          readinessSummary: const ReadinessSummaryDto(
            status: ReadinessStatus.readyToSell,
          ),
          stockQuantity: 10,
          updatedAt: DateTime(2026, 1, 1),
        ),
        ProductListItemDto(
          id: 'p2',
          name: 'P2',
          businessStatus: ProductBusinessStatus.active,
          readinessSummary: const ReadinessSummaryDto(
            status: ReadinessStatus.readyToSell,
          ),
          stockQuantity: 10,
          updatedAt: DateTime(2026, 1, 1),
        ),
        ProductListItemDto(
          id: 'p3',
          name: 'P3',
          businessStatus: ProductBusinessStatus.active,
          readinessSummary: const ReadinessSummaryDto(
            status: ReadinessStatus.readyToSell,
          ),
          stockQuantity: 10,
          updatedAt: DateTime(2026, 1, 1),
        ),
        ProductListItemDto(
          id: 'p4',
          name: 'P4',
          businessStatus: ProductBusinessStatus.active,
          readinessSummary: const ReadinessSummaryDto(
            status: ReadinessStatus.incomplete,
          ),
          stockQuantity: 10,
          updatedAt: DateTime(2026, 1, 1),
        ),
        ProductListItemDto(
          id: 'p5',
          name: 'P5',
          businessStatus: ProductBusinessStatus.active,
          readinessSummary: const ReadinessSummaryDto(
            status: ReadinessStatus.incomplete,
          ),
          stockQuantity: 0,
          updatedAt: DateTime(2026, 1, 1),
        ),
        ProductListItemDto(
          id: 'p6',
          name: 'P6',
          businessStatus: ProductBusinessStatus.inactive,
          readinessSummary: const ReadinessSummaryDto(
            status: ReadinessStatus.incomplete,
          ),
          stockQuantity: 0,
          updatedAt: DateTime(2026, 1, 1),
        ),
      ];

      return ProductSearchResultDto(
        items: items,
        totalCount: 6,
        readyToSellCount: 3,
        incompleteCount: 2,
        inactiveCount: 1,
      );
    }

    testWidgets('g2_deleted_chip_criteria_and_count', (tester) async {
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final backend = registerFakeCatalog(getIt);
      final recordingRepo = RecordingProductRepository(
        backend: backend,
        respond: respondWithDeleted,
      );
      getIt.unregister<ProductRepository>();
      getIt.registerSingleton<ProductRepository>(recordingRepo);

      final router = GoRouter(
        initialLocation: '/products',
        routes: [
          GoRoute(
            path: '/products',
            builder: (context, state) => const ProductCatalogTabPage(),
          ),
        ],
      );

      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('Đã xóa'), findsOneWidget);

      await tester.ensureVisible(find.text('Đã xóa'));
      await tester.tap(find.text('Đã xóa'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(
        recordingRepo.criteria.last.businessStatuses,
        {ProductBusinessStatus.softDeleted},
      );
      expect(recordingRepo.criteria.last.includeSoftDeleted, isTrue);
      expect(find.text('Đã xóa (2)'), findsOneWidget);
    });

    testWidgets('g2_deleted_count_cleared_on_other_chip', (tester) async {
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final backend = registerFakeCatalog(getIt);
      final recordingRepo = RecordingProductRepository(
        backend: backend,
        respond: respondWithDeleted,
      );
      getIt.unregister<ProductRepository>();
      getIt.registerSingleton<ProductRepository>(recordingRepo);

      final router = GoRouter(
        initialLocation: '/products',
        routes: [
          GoRoute(
            path: '/products',
            builder: (context, state) => const ProductCatalogTabPage(),
          ),
        ],
      );

      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      await tester.ensureVisible(find.text('Đã xóa'));
      await tester.tap(find.text('Đã xóa'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('Đã xóa (2)'), findsOneWidget);

      await tester.ensureVisible(find.text('Tất cả (6)'));
      await tester.tap(find.text('Tất cả (6)'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.textContaining('Đã xóa ('), findsNothing);
      expect(find.text('Đã xóa'), findsOneWidget);
    });

    testWidgets('g2_empty_deleted', (tester) async {
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final backend = registerFakeCatalog(getIt);
      final recordingRepo = RecordingProductRepository(
        backend: backend,
        respond: (criteria) {
          if (criteria.includeSoftDeleted) {
            return const ProductSearchResultDto(items: [], totalCount: 0);
          }
          return respondWithDeleted(criteria);
        },
      );
      getIt.unregister<ProductRepository>();
      getIt.registerSingleton<ProductRepository>(recordingRepo);

      final router = GoRouter(
        initialLocation: '/products',
        routes: [
          GoRoute(
            path: '/products',
            builder: (context, state) => const ProductCatalogTabPage(),
          ),
        ],
      );

      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      await tester.ensureVisible(find.text('Đã xóa'));
      await tester.tap(find.text('Đã xóa'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('Không có sản phẩm đã xóa.'), findsOneWidget);
      expect(find.text('Tạo sản phẩm'), findsNothing);
    });

    testWidgets('g2_empty_deleted_when_no_live_products', (tester) async {
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final backend = registerFakeCatalog(getIt);
      final recordingRepo = RecordingProductRepository(
        backend: backend,
        respond: (_) => const ProductSearchResultDto(items: [], totalCount: 0),
      );
      getIt.unregister<ProductRepository>();
      getIt.registerSingleton<ProductRepository>(recordingRepo);

      final router = GoRouter(
        initialLocation: '/products',
        routes: [
          GoRoute(
            path: '/products',
            builder: (context, state) => const ProductCatalogTabPage(),
          ),
        ],
      );

      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      await tester.ensureVisible(find.text('Đã xóa'));
      await tester.tap(find.text('Đã xóa'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('Không có sản phẩm đã xóa.'), findsOneWidget);
      expect(find.text('Chưa có sản phẩm nào được tạo'), findsNothing);
    });

    testWidgets('selectedId highlights the selected tile via VCard.isSelected', (tester) async {
      registerFakeCatalog(getIt, scenario: FakeCatalogScenario.searchWithReadiness);

      final router = GoRouter(
        initialLocation: '/products',
        routes: [
          GoRoute(
            path: '/products',
            builder: (context, state) => const ProductCatalogTabPage(
              selectedId: 'product-1',
            ),
          ),
        ],
      );

      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      final selectedTileFinder = find.byWidgetPredicate(
        (widget) => widget is ProductListItemTile && widget.item.id == 'product-1',
      );
      expect(selectedTileFinder, findsOneWidget);
      final tileWidget = tester.widget<ProductListItemTile>(selectedTileFinder);
      expect(tileWidget.isSelected, isTrue);

      final otherTileFinder = find.byWidgetPredicate(
        (widget) => widget is ProductListItemTile && widget.item.id != 'product-1',
      );
      expect(otherTileFinder, findsWidgets);
      final otherTile = tester.widget<ProductListItemTile>(otherTileFinder.first);
      expect(otherTile.isSelected, isFalse);
    });

    testWidgets('tab_page_with_cubit_does_not_fetch_or_close', (tester) async {
      final backend = registerFakeCatalog(getIt);
      final recordingRepo = RecordingProductRepository(
        backend: backend,
        respond: (_) => const ProductSearchResultDto(items: [], totalCount: 0),
      );
      getIt.unregister<ProductRepository>();
      getIt.registerSingleton<ProductRepository>(recordingRepo);

      final externalCubit = ProductListCubit(productRepository: recordingRepo);
      await externalCubit.fetchProducts();
      final criteriaCountBefore = recordingRepo.criteria.length;

      await tester.pumpWidget(
        MaterialApp(
          home: ProductCatalogTabPage(cubit: externalCubit),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Dựng trang không gọi fetch thêm (criteria không tăng)
      expect(recordingRepo.criteria.length, criteriaCountBefore);

      // Tháo trang
      await tester.pumpWidget(const MaterialApp(home: SizedBox()));
      await tester.pump();

      // Cubit không bị đóng vì không do trang sở hữu
      expect(externalCubit.isClosed, isFalse);
      await externalCubit.close();
    });
  });
}
