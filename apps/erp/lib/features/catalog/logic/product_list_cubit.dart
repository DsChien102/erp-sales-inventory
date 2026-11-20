import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/models.dart';
import '../data/product_repository.dart';
import 'catalog_error_messages.dart';
import 'product_list_state.dart';

class ProductListCubit extends Cubit<ProductListState> {
  ProductListCubit({
    required ProductRepository productRepository,
  })  : _productRepository = productRepository,
        super(const ProductListInitial());

  final ProductRepository _productRepository;

  static const int pageSize = 20;

  int? globalTotalCount;
  int? readyToSellCount;
  int? incompleteCount;
  int? inactiveCount;
  int? inStockCount;
  int? outOfStockCount;
  int? deletedCount;

  Future<void> fetchProducts({
    ProductSearchCriteria? criteria,
    bool isRefresh = false,
  }) async {
    if (!isRefresh && state is ProductListLoading) {
      return;
    }

    try {
      final currentCriteria = criteria ??
          (state is ProductListLoaded
              ? (state as ProductListLoaded).criteria
              : ProductSearchCriteria());

      final currentState = state;
      List<ProductListItemDto> currentItems = [];
      int offset = 0;

      if (!isRefresh && currentState is ProductListLoaded) {
        if (currentState.hasReachedMax && criteria == null) return;
        currentItems = currentState.items;
        offset = currentItems.length;
      }

      emit(
        ProductListLoading(
          criteria: currentCriteria,
          items: isRefresh ? [] : currentItems,
          isFirstLoad: isRefresh || currentItems.isEmpty,
        ),
      );

      final result = await _productRepository.search(
        criteria: currentCriteria,
        limit: pageSize,
        offset: isRefresh ? 0 : offset,
      );

      final isUnfilteredCatalogList = currentCriteria.keyword == null &&
          currentCriteria.readinessFilter == null &&
          currentCriteria.customFieldFilters.isEmpty &&
          currentCriteria.businessStatuses.length == 2 &&
          currentCriteria.businessStatuses.contains(ProductBusinessStatus.active) &&
          currentCriteria.businessStatuses.contains(ProductBusinessStatus.inactive) &&
          !currentCriteria.includeSoftDeleted;

      if (isUnfilteredCatalogList) {
        globalTotalCount = result.totalCount;
        readyToSellCount = result.readyToSellCount ?? readyToSellCount;
        incompleteCount = result.incompleteCount ?? incompleteCount;
        inactiveCount = result.inactiveCount ?? inactiveCount;
      }

      final isDeletedCriteria = currentCriteria.includeSoftDeleted &&
          currentCriteria.businessStatuses.length == 1 &&
          currentCriteria.businessStatuses.contains(ProductBusinessStatus.softDeleted);
      deletedCount = isDeletedCriteria ? result.totalCount : null;

      final newItems = isRefresh ? result.items : currentItems + result.items;
      final hasReachedMax = newItems.length >= result.totalCount || result.items.isEmpty;

      if (isUnfilteredCatalogList && hasReachedMax) {
        inStockCount = newItems
            .where((i) => i.stockQuantity != null && i.stockQuantity! > 0)
            .length;
        outOfStockCount = newItems
            .where((i) => i.stockQuantity != null && i.stockQuantity == 0)
            .length;
      }

      emit(
        ProductListLoaded(
          criteria: currentCriteria,
          items: newItems,
          totalCount: result.totalCount,
          hasReachedMax: hasReachedMax,
        ),
      );
    } catch (e) {
      emit(ProductListError(catalogErrorMessage(e)));
    }
  }

  void searchByKeyword(String keyword) {
    final currentCriteria = state is ProductListLoaded
        ? (state as ProductListLoaded).criteria
        : ProductSearchCriteria();

    final trimmed = keyword.trim();
    final newCriteria = ProductSearchCriteria(
      keyword: trimmed.isEmpty ? null : trimmed,
      businessStatuses: currentCriteria.businessStatuses,
      readinessFilter: currentCriteria.readinessFilter,
      includeSoftDeleted: currentCriteria.includeSoftDeleted,
      sortOrder: trimmed.isEmpty ? ProductSortOrder.updatedAtDesc : ProductSortOrder.relevanceDesc,
      customFieldFilters: currentCriteria.customFieldFilters,
    );
    fetchProducts(criteria: newCriteria, isRefresh: true);
  }
}
