import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vet45_catalog_application/application.dart';
import 'package:vet45_catalog_domain/domain.dart';
import 'package:vet45_shared_application/application.dart';

import 'product_list_state.dart';

class ProductListCubit extends Cubit<ProductListState> {
  ProductListCubit({
    required IModuleMediator mediator,
    required IExecutionContext executionContext,
  }) : _mediator = mediator,
       _executionContext = executionContext,
       super(const ProductListInitial());

  final IModuleMediator _mediator;
  final IExecutionContext _executionContext;

  static const int _pageSize = 20;

  int? globalTotalCount;

  Future<void> fetchProducts({
    ProductSearchCriteria? criteria,
    bool isRefresh = false,
  }) async {
    if (!isRefresh && state is ProductListLoading) {
      return;
    }

    try {
      final tenantId = await _executionContext.requireTenantId();
      if (tenantId.isEmpty) {
        emit(const ProductListError('Missing tenant id'));
        return;
      }

      final currentCriteria =
          criteria ??
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

      final query = SearchProductsQuery(
        tenantId: tenantId,
        criteria: currentCriteria,
        limit: _pageSize,
        offset: isRefresh ? 0 : offset,
      );

      final result = await _mediator.executeQueryAsync(query);

      final isUnfilteredCatalogList =
          currentCriteria.keyword == null &&
          currentCriteria.readinessFilter == null &&
          currentCriteria.customFieldFilters.isEmpty &&
          currentCriteria.businessStatuses.length == 2 &&
          currentCriteria.businessStatuses.contains(ProductBusinessStatus.active) &&
          currentCriteria.businessStatuses.contains(ProductBusinessStatus.inactive) &&
          !currentCriteria.includeSoftDeleted;

      if (isUnfilteredCatalogList) {
        globalTotalCount = result.totalCount;
      }

      final newItems = isRefresh ? result.items : currentItems + result.items;
      final hasReachedMax = newItems.length >= result.totalCount || result.items.isEmpty;

      emit(
        ProductListLoaded(
          criteria: currentCriteria,
          items: newItems,
          totalCount: result.totalCount,
          hasReachedMax: hasReachedMax,
        ),
      );
    } catch (e) {
      emit(ProductListError(e.toString()));
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
