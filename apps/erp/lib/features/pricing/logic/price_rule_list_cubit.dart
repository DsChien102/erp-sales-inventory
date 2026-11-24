import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:c45_design_system/design_system.dart';

import '../../../core/errors/app_exception.dart';
import '../data/customer_price_rule_repository.dart';
import '../data/models.dart';
import '../data/pricing_errors.dart';
import 'price_rule_list_filters.dart';
import 'price_rule_list_state.dart';
import 'pricing_error_messages.dart';

/// Cubit quản lý danh sách giá riêng (S2 — US-01 / SG-01).
final class PriceRuleListCubit extends Cubit<PriceRuleListState> {
  PriceRuleListCubit({
    required CustomerPriceRuleRepository repository,
  }) : _repository = repository,
       super(const PriceRuleListInitial());

  final CustomerPriceRuleRepository _repository;

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
          totalCount: currentState.totalCount,
        ),
      );

      final result = await _repository.search(
        q: _query,
        quickFilter: _resolveQuickFilter(),
        statuses: _resolveStatuses(),
        sources: _resolveSources(),
        businessDate: VDateTime.currentBusinessDate(),
        cursor: _nextCursor,
        limit: _pageSize,
        sort: _sortOption,
        updatedWithin: _advancedFilter.updatedWithin,
      );
      if (isClosed) return;

      final newItems = isRefresh
          ? result.page.items
          : [...currentItems, ...result.page.items];
      final hasReachedMax = !result.page.hasMore;
      _nextCursor = result.page.nextCursor;
      final availableActions = result.availableActions;

      emit(
        PriceRuleListLoaded(
          items: newItems,
          totalCount: result.totalCount,
          query: _query,
          quickFilter: _quickFilter,
          advancedFilter: _advancedFilter,
          sortOption: _sortOption,
          hasReachedMax: hasReachedMax,
          canCreate: availableActions.contains(
            PricingAvailableActions.createManual,
          ),
        ),
      );
    } on AppException catch (e) {
      if (isClosed) return;
      if (e.code == PricingErrorCodes.noPermission) {
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
          totalCount: state.totalCount,
        ),
      );
    }
  }

  void search(String query) => fetchRules(isRefresh: true, query: query);

  void applyQuickFilter(CustomerPriceRuleQuickFilter filter) {
    _quickFilter = filter;
    if (filter == CustomerPriceRuleQuickFilter.belowFloor) {
      _advancedFilter = _advancedFilter.copyWith(
        warning: PriceRuleWarningFilter.belowFloor,
      );
    } else if (_advancedFilter.warning == PriceRuleWarningFilter.belowFloor) {
      _advancedFilter = _advancedFilter.copyWith(warning: null);
    }

    if (filter == CustomerPriceRuleQuickFilter.applying) {
      _advancedFilter = _advancedFilter.copyWith(
        status: CustomerPriceRuleDerivedStatus.applying,
      );
    } else if (_advancedFilter.status ==
        CustomerPriceRuleDerivedStatus.applying) {
      _advancedFilter = _advancedFilter.copyWith(status: null);
    }

    fetchRules(isRefresh: true);
  }

  void applyAdvancedFilter(PriceRuleAdvancedFilter filter) {
    final hadBelowFloorWarning =
        _advancedFilter.warning == PriceRuleWarningFilter.belowFloor;
    final hadApplyingStatus =
        _advancedFilter.status == CustomerPriceRuleDerivedStatus.applying;
    _advancedFilter = filter;
    if (filter.warning == PriceRuleWarningFilter.belowFloor) {
      _quickFilter = CustomerPriceRuleQuickFilter.belowFloor;
    } else if (hadBelowFloorWarning &&
        _quickFilter == CustomerPriceRuleQuickFilter.belowFloor) {
      _quickFilter = CustomerPriceRuleQuickFilter.all;
    }

    if (filter.status == CustomerPriceRuleDerivedStatus.applying) {
      _quickFilter = CustomerPriceRuleQuickFilter.applying;
    } else if (hadApplyingStatus &&
        _quickFilter == CustomerPriceRuleQuickFilter.applying) {
      _quickFilter = CustomerPriceRuleQuickFilter.all;
    }

    fetchRules(isRefresh: true);
  }

  void applySort(PriceRuleSortOption sort) {
    _sortOption = sort;
    fetchRules(isRefresh: true);
  }

  void refresh() => fetchRules(isRefresh: true);

  String _messageForBlocked(AppException e) => pricingErrorMessage(
    e,
    fallback: 'Không thể tải dữ liệu. Vui lòng thử lại.',
    overrides: const {
      PricingErrorCodes.validationError: 'Dữ liệu tìm kiếm không hợp lệ.',
      PricingErrorCodes.systemError: 'Không thể tải dữ liệu. Vui lòng thử lại.',
    },
  );

  CustomerPriceRuleQuickFilter _resolveQuickFilter() {
    if (_advancedFilter.warning == PriceRuleWarningFilter.belowFloor) {
      return CustomerPriceRuleQuickFilter.belowFloor;
    }
    return _quickFilter;
  }

  List<CustomerPriceRuleDerivedStatus> _resolveStatuses() {
    final statuses = <CustomerPriceRuleDerivedStatus>[];
    final advancedStatus = _advancedFilter.status;
    if (advancedStatus != null) {
      statuses.add(advancedStatus);
    } else if (_quickFilter == CustomerPriceRuleQuickFilter.applying) {
      statuses.add(CustomerPriceRuleDerivedStatus.applying);
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
}
