import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vet45_partner_application/application.dart';
import 'package:vet45_partner_domain/domain.dart';
import 'package:vet45_shared_application/application.dart';

import 'partner_list_state.dart';

final class PartnerListCubit extends Cubit<PartnerListState> {
  PartnerListCubit({
    required IPartnerModule partnerModule,
    required IExecutionContext executionContext,
  })  : _partnerModule = partnerModule,
        _executionContext = executionContext,
        super(const PartnerListInitial());

  final IPartnerModule _partnerModule;
  final IExecutionContext _executionContext;

  static const int _pageSize = 20;

  int? _nextPage;
  String? _query;

  Future<void> fetchPartners({bool isRefresh = false, String? query}) async {
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
          sortOption: currentState.sortOption,
        ),
      );

      final tenantId = await _executionContext.requireTenantId();
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
          sortParam = 'name_asc';
          break;
        case PartnerSortOption.nameDesc:
          sortParam = 'name_desc';
          break;
        case PartnerSortOption.roleAsc:
          sortParam = 'role_asc';
          break;
        case PartnerSortOption.roleDesc:
          sortParam = 'role_desc';
          break;
      }

      final result = await _partnerModule.executeQueryAsync(
        SearchPartnersQuery(
          tenantId: tenantId,
          query: _query,
          partnerType: currentState.partnerType,
          role: apiRole,
          status: currentState.status ?? PartnerStatus.active,
          page: page,
          limit: _pageSize,
          sort: sortParam,
        ),
      );

      List<PartnerListItemDto> fetchedItems = result.items;

      // Local filter for "both" roles
      if (currentState.roleFilter == PartnerRoleFilter.both) {
        fetchedItems = fetchedItems.where((item) {
          return item.roles.contains(PartnerRoleType.customer) &&
              item.roles.contains(PartnerRoleType.supplier);
        }).toList();
      }

      final newItems = isRefresh ? fetchedItems : [...currentItems, ...fetchedItems];
      final hasReachedMax = result.items.length < _pageSize || result.items.isEmpty;
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
          sortOption: currentState.sortOption,
        ),
      );
    } catch (error) {
      emit(PartnerListError(
        error.toString(),
        query: state.query,
        partnerType: state.partnerType,
        roleFilter: state.roleFilter,
        status: state.status,
        sortOption: state.sortOption,
      ));
    }
  }

  void searchByKeyword(String keyword) {
    fetchPartners(isRefresh: true, query: keyword);
  }

  void applyFilters({
    PartnerType? partnerType,
    PartnerRoleFilter? roleFilter,
    PartnerStatus? status,
    PartnerSortOption? sortOption,
    bool clearType = false,
    bool clearRole = false,
    bool clearStatus = false,
  }) {
    emit(PartnerListLoading(
      items: const [],
      isFirstLoad: true,
      query: _query,
      partnerType: clearType ? null : (partnerType ?? state.partnerType),
      roleFilter: clearRole ? null : (roleFilter ?? state.roleFilter),
      status: clearStatus ? null : (status ?? state.status),
      sortOption: sortOption ?? state.sortOption,
    ));
    fetchPartners(isRefresh: true);
  }

  void clearFilters() {
    emit(PartnerListLoading(
      items: const [],
      isFirstLoad: true,
      query: _query,
      partnerType: null,
      roleFilter: null,
      status: null,
      sortOption: PartnerSortOption.updatedAtDesc,
    ));
    fetchPartners(isRefresh: true);
  }

  void removeFilter(String filterType) {
    bool clearType = filterType == 'partnerType';
    bool clearRole = filterType == 'roleFilter';
    bool clearStatus = filterType == 'status';

    applyFilters(
      partnerType: clearType ? null : state.partnerType,
      roleFilter: clearRole ? null : state.roleFilter,
      status: clearStatus ? null : state.status,
      sortOption: state.sortOption,
      clearType: clearType,
      clearRole: clearRole,
      clearStatus: clearStatus,
    );
  }
}
