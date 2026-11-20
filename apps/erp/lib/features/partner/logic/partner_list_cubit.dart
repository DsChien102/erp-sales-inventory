import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/models/partner_enums.dart';
import '../data/models/partner_list_item.dart';
import '../data/partner_repository.dart';
import 'partner_list_state.dart';

final class PartnerListCubit extends Cubit<PartnerListState> {
  PartnerListCubit({required PartnerRepository repository})
    : _repository = repository,
      super(const PartnerListInitial());

  final PartnerRepository _repository;

  static const int pageSize = 20;

  int? _nextPage;
  String? _query;

  Future<void> fetchPartners({bool isRefresh = false, String? query}) async {
    if (isClosed) return;
    try {
      if (query != null) {
        _query = query.trim().isEmpty ? null : query.trim();
      }
      if (isRefresh) {
        _nextPage = 1;
      }

      final currentState = state;
      final currentItems = switch (currentState) {
        PartnerListLoaded(:final items) when !isRefresh => items,
        PartnerListLoading(:final items) when !isRefresh => items,
        _ => <PartnerListItemDto>[],
      };

      if (!isRefresh && currentState is PartnerListLoaded && currentState.hasReachedMax) {
        return;
      }

      emit(
        PartnerListLoading(
          items: isRefresh ? const [] : currentItems,
          isFirstLoad: isRefresh || currentItems.isEmpty,
          query: _query,
          partnerType: currentState.partnerType,
          roleFilter: currentState.roleFilter,
          status: currentState.status,
          updatedTimeFilter: currentState.updatedTimeFilter,
          sortOption: currentState.sortOption,
        ),
      );

      final page = _nextPage ?? 1;

      // Map Role Filter to query param
      PartnerRoleType? apiRole;
      if (currentState.roleFilter == PartnerRoleFilter.customer) {
        apiRole = PartnerRoleType.customer;
      } else if (currentState.roleFilter == PartnerRoleFilter.supplier) {
        apiRole = PartnerRoleType.supplier;
      }

      // Map Sort Option
      String sortParam = 'updated_at_desc';
      switch (currentState.sortOption) {
        case PartnerSortOption.updatedAtDesc:
          sortParam = 'updated_at_desc';
          break;
        case PartnerSortOption.updatedAtAsc:
          sortParam = 'updated_at_asc';
          break;
        case PartnerSortOption.nameAsc:
          sortParam = 'display_name_asc';
          break;
        case PartnerSortOption.nameDesc:
          sortParam = 'display_name_desc';
          break;
      }

      final result = await _repository.search(
        query: _query,
        partnerType: currentState.partnerType,
        role: apiRole,
        requireBothRoles: currentState.roleFilter == PartnerRoleFilter.both,
        requireAnyRole: true,
        status: currentState.status,
        updatedWithinDays: currentState.updatedTimeFilter?.days,
        page: page,
        limit: pageSize,
        sort: sortParam,
      );
      if (isClosed) return;

      final pageItems = result.items.where((item) => item.roles.isNotEmpty).toList(growable: false);
      final newItems = isRefresh ? pageItems : [...currentItems, ...pageItems];
      final hasReachedMax = result.items.length < pageSize || result.items.isEmpty;
      _nextPage = hasReachedMax ? null : page + 1;

      emit(
        PartnerListLoaded(
          items: newItems,
          total: result.total,
          hasReachedMax: hasReachedMax,
          query: _query,
          partnerType: currentState.partnerType,
          roleFilter: currentState.roleFilter,
          status: currentState.status,
          updatedTimeFilter: currentState.updatedTimeFilter,
          sortOption: currentState.sortOption,
        ),
      );
    } catch (error) {
      if (isClosed) return;
      emit(
        PartnerListError(
          error.toString(),
          query: state.query,
          partnerType: state.partnerType,
          roleFilter: state.roleFilter,
          status: state.status,
          updatedTimeFilter: state.updatedTimeFilter,
          sortOption: state.sortOption,
        ),
      );
    }
  }

  void searchByKeyword(String keyword) {
    fetchPartners(isRefresh: true, query: keyword);
  }

  void applyFilters({
    PartnerType? partnerType,
    PartnerRoleFilter? roleFilter,
    PartnerStatus? status,
    PartnerUpdatedTimeFilter? updatedTimeFilter,
    PartnerSortOption? sortOption,
    bool clearType = false,
    bool clearRole = false,
    bool clearStatus = false,
    bool clearUpdatedTime = false,
  }) {
    emit(
      PartnerListLoading(
        items: const [],
        isFirstLoad: true,
        query: _query,
        partnerType: clearType ? null : (partnerType ?? state.partnerType),
        roleFilter: clearRole ? null : (roleFilter ?? state.roleFilter),
        status: clearStatus ? null : (status ?? state.status),
        updatedTimeFilter: clearUpdatedTime ? null : (updatedTimeFilter ?? state.updatedTimeFilter),
        sortOption: sortOption ?? state.sortOption,
      ),
    );
    fetchPartners(isRefresh: true);
  }

  void clearFilters() {
    emit(
      PartnerListLoading(
        items: const [],
        isFirstLoad: true,
        query: _query,
        partnerType: null,
        roleFilter: null,
        status: null,
        updatedTimeFilter: null,
        sortOption: PartnerSortOption.updatedAtDesc,
      ),
    );
    fetchPartners(isRefresh: true);
  }

  void removeFilter(String filterType) {
    bool clearType = filterType == 'partnerType';
    bool clearRole = filterType == 'roleFilter';
    bool clearStatus = filterType == 'status';
    bool clearUpdatedTime = filterType == 'updatedTime';

    applyFilters(
      partnerType: clearType ? null : state.partnerType,
      roleFilter: clearRole ? null : state.roleFilter,
      status: clearStatus ? null : state.status,
      updatedTimeFilter: clearUpdatedTime ? null : state.updatedTimeFilter,
      sortOption: state.sortOption,
      clearType: clearType,
      clearRole: clearRole,
      clearStatus: clearStatus,
      clearUpdatedTime: clearUpdatedTime,
    );
  }
}
