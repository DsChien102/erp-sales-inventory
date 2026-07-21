import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vet45_pricing_application/application.dart';
import 'package:vet45_pricing_domain/domain.dart';
import 'package:vet45_shared_application/application.dart';

import '../models/price_rule_list_filters.dart';
import 'price_rule_list_state.dart';

/// Cubit quản lý danh sách giá riêng (S2 — US-01 / SG-01).
final class PriceRuleListCubit extends Cubit<PriceRuleListState> {
  PriceRuleListCubit({
    required IPricingModule pricingModule,
    required IExecutionContext executionContext,
  }) : _pricingModule = pricingModule,
       _executionContext = executionContext,
       super(const PriceRuleListInitial());

  final IPricingModule _pricingModule;
  final IExecutionContext _executionContext;

  static const int _pageSize = 20;

  String? _nextCursor;
  String? _query;
  CustomerPriceRuleQuickFilter _quickFilter = CustomerPriceRuleQuickFilter.all;
  PriceRuleAdvancedFilter _advancedFilter = PriceRuleAdvancedFilter.empty;
  PriceRuleSortOption _sortOption = PriceRuleSortOption.updatedAtDesc;

  Future<void> fetchRules({
    bool isRefresh = false,
    String? query,
    CustomerPriceRuleQuickFilter? quickFilter,
  }) async {
    try {
      if (query != null) {
        _query = query.trim().isEmpty ? null : query.trim();
      }
      if (quickFilter != null) {
        _quickFilter = quickFilter;
      }
      if (isRefresh) {
        _nextCursor = null;
      }

      final currentState = state;
      final currentItems = switch (currentState) {
        PriceRuleListLoaded(:final items) when !isRefresh => items,
        PriceRuleListLoading(:final items) when !isRefresh => items,
        _ => <CustomerPriceRuleListItemDto>[],
      };

      if (!isRefresh &&
          currentState is PriceRuleListLoaded &&
          currentState.hasReachedMax) {
        return;
      }

      emit(
        PriceRuleListLoading(
          items: isRefresh ? const [] : currentItems,
          isFirstLoad: isRefresh || currentItems.isEmpty,
          query: _query,
          quickFilter: _quickFilter,
          advancedFilter: _advancedFilter,
          sortOption: _sortOption,
          canCreate: currentState.canCreate,
          canImport: currentState.canImport,
          totalCount: currentState.totalCount,
        ),
      );

      final tenantId = await _executionContext.requireTenantId();
      final statuses = _advancedFilter.status == null
          ? const <CustomerPriceRuleDerivedStatus>[]
          : [_advancedFilter.status!];
      final sources = _advancedFilter.source == null
          ? const <CustomerPriceRuleSourceType>[]
          : [_advancedFilter.source!];

      final result = await _pricingModule.executeQueryAsync(
        SearchCustomerPriceRulesQuery(
          tenantId: tenantId,
          q: _query,
          quickFilter: _quickFilter,
          statuses: statuses,
          sources: sources,
          businessDate: DateTime.now().toUtc(),
          cursor: _nextCursor,
          limit: _pageSize,
        ),
      );

      var pageItems = List<CustomerPriceRuleListItemDto>.of(result.page.items);
      pageItems = _applyClientFilters(pageItems);
      pageItems = _applySort(pageItems);

      final newItems = isRefresh
          ? pageItems
          : [...currentItems, ...pageItems];
      final hasReachedMax = !result.page.hasMore;
      _nextCursor = result.page.nextCursor;

      emit(
        PriceRuleListLoaded(
          items: newItems,
          totalCount: newItems.length,
          query: _query,
          quickFilter: _quickFilter,
          advancedFilter: _advancedFilter,
          sortOption: _sortOption,
          hasReachedMax: hasReachedMax,
          canCreate: result.availableActions.contains(
            PricingAvailableActions.createManual,
          ),
          canImport: result.availableActions.contains(
            PricingAvailableActions.import,
          ),
        ),
      );
    } catch (error) {
      emit(
        PriceRuleListError(
          message: error.toString(),
          items: state.items,
          query: _query,
          quickFilter: _quickFilter,
          advancedFilter: _advancedFilter,
          sortOption: _sortOption,
          canCreate: state.canCreate,
          canImport: state.canImport,
          totalCount: state.totalCount,
        ),
      );
    }
  }

  void search(String query) => fetchRules(isRefresh: true, query: query);

  void applyQuickFilter(CustomerPriceRuleQuickFilter filter) =>
      fetchRules(isRefresh: true, quickFilter: filter);

  void applyAdvancedFilter(PriceRuleAdvancedFilter filter) {
    _advancedFilter = filter;
    fetchRules(isRefresh: true);
  }

  void applySort(PriceRuleSortOption sort) {
    _sortOption = sort;
    fetchRules(isRefresh: true);
  }

  void refresh() => fetchRules(isRefresh: true);

  List<CustomerPriceRuleListItemDto> _applyClientFilters(
    List<CustomerPriceRuleListItemDto> items,
  ) {
    var result = items;
    final warning = _advancedFilter.warning;
    if (warning != null) {
      result = result.where((item) {
        final codes = item.validationOutcome.warningCodes;
        return switch (warning) {
          PriceRuleWarningFilter.belowFloor =>
            codes.contains('below_floor_price'),
          PriceRuleWarningFilter.duplicateRule =>
            codes.contains('duplicate_active_rule'),
          PriceRuleWarningFilter.dataError =>
            item.validationOutcome.blockingCodes.isNotEmpty,
        };
      }).toList();
    }

    final within = _advancedFilter.updatedWithin;
    if (within != null) {
      final days = within == PriceRuleUpdatedWithin.last7Days ? 7 : 30;
      final cutoff = DateTime.now().toUtc().subtract(Duration(days: days));
      result = result.where((item) => item.updatedAt.isAfter(cutoff)).toList();
    }

    // Status filter may already be sent to query; keep client fallback.
    final status = _advancedFilter.status;
    if (status != null) {
      result = result.where((item) => item.derivedStatus == status).toList();
    }

    return result;
  }

  List<CustomerPriceRuleListItemDto> _applySort(
    List<CustomerPriceRuleListItemDto> items,
  ) {
    final sorted = List<CustomerPriceRuleListItemDto>.of(items);
    int warningScore(CustomerPriceRuleListItemDto item) =>
        item.validationOutcome.warningCodes.isEmpty ? 1 : 0;

    sorted.sort((a, b) {
      return switch (_sortOption) {
        PriceRuleSortOption.updatedAtDesc =>
          b.updatedAt.compareTo(a.updatedAt),
        PriceRuleSortOption.updatedAtAsc => a.updatedAt.compareTo(b.updatedAt),
        PriceRuleSortOption.customerNameAsc =>
          a.customer.displayName.compareTo(b.customer.displayName),
        PriceRuleSortOption.customerNameDesc =>
          b.customer.displayName.compareTo(a.customer.displayName),
        PriceRuleSortOption.priceDesc =>
          b.price.amountMinor.compareTo(a.price.amountMinor),
        PriceRuleSortOption.priceAsc =>
          a.price.amountMinor.compareTo(b.price.amountMinor),
        PriceRuleSortOption.warningsFirst => () {
          final byWarning = warningScore(a).compareTo(warningScore(b));
          if (byWarning != 0) return byWarning;
          return b.updatedAt.compareTo(a.updatedAt);
        }(),
      };
    });
    return sorted;
  }
}
