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
    if (isClosed) return;
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
      if (isClosed) return;

      final aggregatedPage = <CustomerPriceRuleListItemDto>[];
      var hasMore = true;
      var pagesThisCall = 0;
      final maxPages = _needsClientOnlyFiltering ? 5 : 1;
      CustomerPriceRuleSearchResultDto? lastResult;

      while (pagesThisCall < maxPages && hasMore) {
        lastResult = await _pricingModule.executeQueryAsync(
          _buildSearchQuery(tenantId: tenantId, cursor: _nextCursor),
        );
        if (isClosed) return;
        final pageResult = lastResult!;

        var batch = _applyClientOnlyFilters(pageResult.page.items);
        batch = _applySort(batch);
        aggregatedPage.addAll(batch);

        hasMore = pageResult.page.hasMore;
        _nextCursor = pageResult.page.nextCursor;
        pagesThisCall++;

        if (!_needsClientOnlyFiltering) {
          break;
        }
        if (!isRefresh && batch.isNotEmpty) {
          break;
        }
        if (isRefresh && aggregatedPage.length >= _pageSize) {
          break;
        }
      }

      final newItems = isRefresh
          ? aggregatedPage
          : [...currentItems, ...aggregatedPage];
      final hasReachedMax = !hasMore;
      final availableActions = lastResult?.availableActions ?? const <String>[];

      emit(
        PriceRuleListLoaded(
          items: newItems,
          totalCount: newItems.length,
          query: _query,
          quickFilter: _quickFilter,
          advancedFilter: _advancedFilter,
          sortOption: _sortOption,
          hasReachedMax: hasReachedMax,
          canCreate: availableActions.contains(
            PricingAvailableActions.createManual,
          ),
          canImport: availableActions.contains(PricingAvailableActions.import),
        ),
      );
    } on PricingBlockedException catch (e) {
      if (isClosed) return;
      if (e.code == PricingBlockedCodes.noPermission) {
        emit(
          PriceRuleListNoPermission(
            query: _query,
            quickFilter: _quickFilter,
            advancedFilter: _advancedFilter,
            sortOption: _sortOption,
          ),
        );
        return;
      }
      emit(
        PriceRuleListError(
          message: _messageForBlocked(e),
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
    } on ApplicationException catch (e) {
      if (isClosed) return;
      emit(
        PriceRuleListError(
          message: e.message,
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
    } catch (error) {
      if (isClosed) return;
      emit(
        PriceRuleListError(
          message: 'Không thể tải dữ liệu. Vui lòng thử lại.',
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

  void applyQuickFilter(CustomerPriceRuleQuickFilter filter) {
    _quickFilter = filter;
    switch (filter) {
      case CustomerPriceRuleQuickFilter.applying:
        _advancedFilter = _advancedFilter.copyWith(
          status: CustomerPriceRuleDerivedStatus.applying,
          warning: _advancedFilter.warning == PriceRuleWarningFilter.belowFloor
              ? null
              : _advancedFilter.warning,
        );
      case CustomerPriceRuleQuickFilter.belowFloor:
        _advancedFilter = _advancedFilter.copyWith(
          warning: PriceRuleWarningFilter.belowFloor,
          status: _advancedFilter.status == CustomerPriceRuleDerivedStatus.applying
              ? null
              : _advancedFilter.status,
        );
      case CustomerPriceRuleQuickFilter.all:
        _advancedFilter = _advancedFilter.copyWith(
          status: _advancedFilter.status == CustomerPriceRuleDerivedStatus.applying
              ? null
              : _advancedFilter.status,
          warning: _advancedFilter.warning == PriceRuleWarningFilter.belowFloor
              ? null
              : _advancedFilter.warning,
        );
    }
    fetchRules(isRefresh: true);
  }

  void applyAdvancedFilter(PriceRuleAdvancedFilter filter) {
    _advancedFilter = filter;
    if (filter.warning == PriceRuleWarningFilter.belowFloor) {
      _quickFilter = CustomerPriceRuleQuickFilter.belowFloor;
    } else if (filter.status == CustomerPriceRuleDerivedStatus.applying) {
      _quickFilter = CustomerPriceRuleQuickFilter.applying;
    } else {
      _quickFilter = CustomerPriceRuleQuickFilter.all;
    }
    fetchRules(isRefresh: true);
  }

  void applySort(PriceRuleSortOption sort) {
    _sortOption = sort;
    fetchRules(isRefresh: true);
  }

  void refresh() => fetchRules(isRefresh: true);

  String _messageForBlocked(PricingBlockedException e) => switch (e.code) {
    PricingBlockedCodes.validationError =>
      e.message ?? 'Dữ liệu tìm kiếm không hợp lệ.',
    PricingBlockedCodes.systemError =>
      'Không thể tải dữ liệu. Vui lòng thử lại.',
    _ => e.message ?? 'Không thể tải dữ liệu. Vui lòng thử lại.',
  };

  bool get _needsClientOnlyFiltering =>
      _advancedFilter.warning == PriceRuleWarningFilter.duplicateRule ||
      _advancedFilter.warning == PriceRuleWarningFilter.dataError ||
      _advancedFilter.updatedWithin != null;

  SearchCustomerPriceRulesQuery _buildSearchQuery({
    required String tenantId,
    String? cursor,
  }) {
    return SearchCustomerPriceRulesQuery(
      tenantId: tenantId,
      q: _query,
      quickFilter: _resolveQuickFilter(),
      statuses: _resolveStatuses(),
      sources: _resolveSources(),
      businessDate: DateTime.now().toUtc(),
      cursor: cursor,
      limit: _pageSize,
    );
  }

  CustomerPriceRuleQuickFilter _resolveQuickFilter() {
    if (_advancedFilter.warning == PriceRuleWarningFilter.belowFloor) {
      return CustomerPriceRuleQuickFilter.belowFloor;
    }
    if (_advancedFilter.status == CustomerPriceRuleDerivedStatus.applying) {
      return CustomerPriceRuleQuickFilter.applying;
    }
    return _quickFilter;
  }

  List<CustomerPriceRuleDerivedStatus> _resolveStatuses() {
    final statuses = <CustomerPriceRuleDerivedStatus>[];
    final advancedStatus = _advancedFilter.status;
    if (advancedStatus != null) {
      statuses.add(advancedStatus);
    }
    return statuses;
  }

  List<CustomerPriceRuleSourceType> _resolveSources() {
    final source = _advancedFilter.source;
    if (source == null) {
      return const [];
    }
    return [source];
  }

  /// V1 RPC chưa hỗ trợ duplicate/data_error warning và updated-date range (US-01 Q-02).
  List<CustomerPriceRuleListItemDto> _applyClientOnlyFilters(
    List<CustomerPriceRuleListItemDto> items,
  ) {
    var result = items;
    final warning = _advancedFilter.warning;
    if (warning == PriceRuleWarningFilter.duplicateRule ||
        warning == PriceRuleWarningFilter.dataError) {
      final activeWarning = warning!;
      result = result.where((item) {
        final codes = item.validationOutcome.warningCodes;
        return switch (activeWarning) {
          PriceRuleWarningFilter.duplicateRule => codes.contains(
            'duplicate_active_rule',
          ),
          PriceRuleWarningFilter.dataError =>
            item.validationOutcome.blockingCodes.isNotEmpty,
          PriceRuleWarningFilter.belowFloor => true,
        };
      }).toList();
    }

    final within = _advancedFilter.updatedWithin;
    if (within != null) {
      final days = within == PriceRuleUpdatedWithin.last7Days ? 7 : 30;
      final cutoff = DateTime.now().toUtc().subtract(Duration(days: days));
      result = result.where((item) => item.updatedAt.isAfter(cutoff)).toList();
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
        PriceRuleSortOption.updatedAtDesc => b.updatedAt.compareTo(a.updatedAt),
        PriceRuleSortOption.updatedAtAsc => a.updatedAt.compareTo(b.updatedAt),
        PriceRuleSortOption.customerNameAsc => a.customer.displayName.compareTo(
          b.customer.displayName,
        ),
        PriceRuleSortOption.customerNameDesc =>
          b.customer.displayName.compareTo(a.customer.displayName),
        PriceRuleSortOption.priceDesc => b.price.amountMinor.compareTo(
          a.price.amountMinor,
        ),
        PriceRuleSortOption.priceAsc => a.price.amountMinor.compareTo(
          b.price.amountMinor,
        ),
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
