import 'package:erp/core/errors/app_exception.dart';
import 'package:erp/features/catalog/data/models.dart';
import 'package:erp/features/catalog/logic/catalog_error_messages.dart';
import 'package:erp/features/catalog/logic/product_list_cubit.dart';
import 'package:erp/features/catalog/logic/product_list_state.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fake_catalog_backend.dart';
import '../support/fake_catalog_repositories.dart';
import '../support/fake_catalog_scenario.dart';
import '../support/recording_catalog_repositories.dart';

class _PaginatedProductRepository extends FakeProductRepository {
  _PaginatedProductRepository({required super.backend});

  int searchCalls = 0;

  @override
  Future<ProductSearchResultDto> search({
    ProductSearchCriteria? criteria,
    int limit = 50,
    int offset = 0,
  }) async {
    searchCalls++;
    calls.add('search');
    final dummyItem = ProductListItemDto(
      id: 'prod-$offset',
      name: 'Thuốc $offset',
      sku: 'SKU$offset',
      businessStatus: ProductBusinessStatus.active,
      readinessSummary: const ReadinessSummaryDto(
        status: ReadinessStatus.readyToSell,
      ),
      stockQuantity: 10,
      updatedAt: DateTime.utc(2026, 11, 3),
    );

    if (offset == 0) {
      return ProductSearchResultDto(
        items: List.generate(limit, (i) => dummyItem),
        totalCount: limit + 5,
        readyToSellCount: limit + 5,
        incompleteCount: 0,
        inactiveCount: 0,
      );
    } else {
      return ProductSearchResultDto(
        items: List.generate(5, (i) => dummyItem),
        totalCount: limit + 5,
        readyToSellCount: limit + 5,
        incompleteCount: 0,
        inactiveCount: 0,
      );
    }
  }
}

void main() {
  group('ProductListCubit (H1)', () {
    test('fetches page 1 and page 2 with pagination and appends items', () async {
      final backend = FakeCatalogBackend(scenario: FakeCatalogScenario.guidedCreateOk);
      final repo = _PaginatedProductRepository(backend: backend);
      final cubit = ProductListCubit(productRepository: repo);

      // Page 1
      await cubit.fetchProducts();
      expect(cubit.state, isA<ProductListLoaded>());
      final state1 = cubit.state as ProductListLoaded;
      expect(state1.items.length, ProductListCubit.pageSize);
      expect(state1.hasReachedMax, isFalse);

      // Page 2 (with append)
      await cubit.fetchProducts();
      expect(cubit.state, isA<ProductListLoaded>());
      final state2 = cubit.state as ProductListLoaded;
      expect(state2.items.length, ProductListCubit.pageSize + 5);
      expect(state2.hasReachedMax, isTrue);
      expect(repo.searchCalls, 2);
    });

    test('counts groups and stock when catalog list is unfiltered', () async {
      final backend = FakeCatalogBackend(scenario: FakeCatalogScenario.guidedCreateOk);
      final repo = FakeProductRepository(backend: backend);
      final cubit = ProductListCubit(productRepository: repo);

      // Unfiltered list requires active and inactive statuses
      final unfilteredCriteria = ProductSearchCriteria(
        businessStatuses: {ProductBusinessStatus.active, ProductBusinessStatus.inactive},
      );

      await cubit.fetchProducts(criteria: unfilteredCriteria);

      expect(cubit.globalTotalCount, isNotNull);
      expect(cubit.readyToSellCount, isNotNull);
      expect(cubit.incompleteCount, isNotNull);
      expect(cubit.inactiveCount, isNotNull);
      expect(cubit.inStockCount, isNotNull);
      expect(cubit.outOfStockCount, isNotNull);
    });

    test('passes businessStatuses filter criteria to repository', () async {
      final backend = FakeCatalogBackend(scenario: FakeCatalogScenario.guidedCreateOk);
      final repo = FakeProductRepository(backend: backend);
      final cubit = ProductListCubit(productRepository: repo);

      final filterCriteria = ProductSearchCriteria(
        businessStatuses: {ProductBusinessStatus.active},
      );

      await cubit.fetchProducts(criteria: filterCriteria);

      expect(cubit.state, isA<ProductListLoaded>());
      final loaded = cubit.state as ProductListLoaded;
      expect(loaded.criteria.businessStatuses, {ProductBusinessStatus.active});
    });

    test('emits ProductListError with permission denied message on AppException', () async {
      final backend = FakeCatalogBackend(scenario: FakeCatalogScenario.scnContractE06U04PermissionDenied);
      final repo = FakeProductRepository(backend: backend);
      final cubit = ProductListCubit(productRepository: repo);

      await cubit.fetchProducts();

      expect(cubit.state, isA<ProductListError>());
      final errorState = cubit.state as ProductListError;
      expect(
        errorState.message,
        catalogErrorMessage(const AppException(AppErrorCode.noPermission, serverMessage: 'Permission denied')),
      );
    });

    test('g2_deleted_count_set_only_for_deleted_criteria', () async {
      final backend = FakeCatalogBackend(scenario: FakeCatalogScenario.guidedCreateOk);
      final repo = RecordingProductRepository(
        backend: backend,
        respond: (criteria) => const ProductSearchResultDto(
          items: [],
          totalCount: 2,
        ),
      );
      final cubit = ProductListCubit(productRepository: repo);

      await cubit.fetchProducts(
        criteria: ProductSearchCriteria(
          businessStatuses: {ProductBusinessStatus.softDeleted},
          includeSoftDeleted: true,
        ),
        isRefresh: true,
      );
      expect(cubit.deletedCount, 2);

      await cubit.fetchProducts(
        criteria: ProductSearchCriteria(
          businessStatuses: {ProductBusinessStatus.active, ProductBusinessStatus.inactive},
        ),
        isRefresh: true,
      );
      expect(cubit.deletedCount, isNull);
    });
  });
}
