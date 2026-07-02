import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vet45_partner_application/application.dart';
import 'package:vet45_partner_domain/domain.dart';
import 'package:vet45_shared_application/application.dart';

import '../constants/partner_list_constants.dart';
import '../mappers/partner_ui_mapper.dart';
import '../models/partner_filter_counts.dart';
import '../utils/partner_presentation_errors.dart';
import 'partner_list_state.dart';

class PartnerListCubit extends Cubit<PartnerListState> {
  PartnerListCubit({
    required IPartnerModule partnerModule,
    required IExecutionContext executionContext,
  })  : _partnerModule = partnerModule,
        _executionContext = executionContext,
        super(const PartnerListState()) {
    load();
  }

  final IPartnerModule _partnerModule;
  final IExecutionContext _executionContext;

  Future<void> load() async {
    emit(
      state.copyWith(
        status: PartnerListStatus.loading,
        isLoadingMore: false,
        clearErrorMessage: true,
      ),
    );

    await _fetchPage(reset: true);
  }

  Future<void> loadMore() async {
    if (!state.hasMore ||
        state.isLoadingMore ||
        state.status == PartnerListStatus.loading) {
      return;
    }

    emit(state.copyWith(isLoadingMore: true));
    await _fetchPage(reset: false);
  }

  Future<void> _fetchPage({required bool reset}) async {
    try {
      final tenantId = await _executionContext.requireTenantId();
      final criteria = PartnerUiMapper.toSearchCriteria(
        searchQuery: state.searchQuery,
        filterRole: state.filterRole,
        filterProfileType: state.filterProfileType,
        filterStatus: state.filterStatus,
      );

      final result = await _partnerModule.executeQueryAsync(
        SearchPartnersQuery(
          tenantId: tenantId,
          criteria: criteria,
          limit: PartnerListConstants.pageSize,
          offset: reset ? 0 : state.partners.length,
        ),
      );

      final sortedItems = result.items.toList();
      sortedItems.sort((a, b) {
        if (a.status == PartnerStatus.active && b.status != PartnerStatus.active) return -1;
        if (a.status != PartnerStatus.active && b.status == PartnerStatus.active) return 1;
        return b.updatedAt.compareTo(a.updatedAt);
      });
      final mappedItems = sortedItems.map(PartnerUiMapper.toListItem).toList();
      final partners = reset
          ? mappedItems
          : [...state.partners, ...mappedItems];
      _sortPartners(partners);

      emit(
        state.copyWith(
          status: PartnerListStatus.success,
          partners: partners,
          totalCount: result.totalCount,
          isLoadingMore: false,
          clearErrorMessage: true,
        ),
      );
    } catch (error) {
      if (reset) {
        emit(
          state.copyWith(
            status: PartnerListStatus.failure,
            isLoadingMore: false,
            errorMessage: partnerErrorMessage(error),
          ),
        );
      } else {
        emit(state.copyWith(isLoadingMore: false));
      }
    }
  }

  void search(String query) {
    emit(state.copyWith(searchQuery: query));
    load();
  }

  Future<PartnerFilterCounts> fetchFilterCounts() async {
    final baseCriteria = PartnerSearchCriteria(
      keyword: state.searchQuery.trim().isEmpty
          ? null
          : state.searchQuery.trim(),
      statuses: {
        PartnerStatus.active,
        PartnerStatus.inactive,
      },
    );

    final results = await Future.wait([
      _countPartners(baseCriteria),
      _countPartners(
        PartnerSearchCriteria(
          keyword: baseCriteria.keyword,
          statuses: baseCriteria.statuses,
          roleFilter: PartnerRoleFilter.customer,
        ),
      ),
      _countPartners(
        PartnerSearchCriteria(
          keyword: baseCriteria.keyword,
          statuses: baseCriteria.statuses,
          roleFilter: PartnerRoleFilter.supplier,
        ),
      ),
      _countPartners(
        PartnerSearchCriteria(
          keyword: baseCriteria.keyword,
          statuses: baseCriteria.statuses,
          roleFilter: PartnerRoleFilter.both,
        ),
      ),
      _countPartners(
        PartnerSearchCriteria(
          keyword: baseCriteria.keyword,
          statuses: baseCriteria.statuses,
          entityType: EntityType.individual,
        ),
      ),
      _countPartners(
        PartnerSearchCriteria(
          keyword: baseCriteria.keyword,
          statuses: baseCriteria.statuses,
          entityType: EntityType.company,
        ),
      ),
      _countPartners(
        PartnerSearchCriteria(
          keyword: baseCriteria.keyword,
          statuses: baseCriteria.statuses,
          entityType: EntityType.householdBusiness,
        ),
      ),
      _countPartners(
        PartnerSearchCriteria(
          keyword: baseCriteria.keyword,
          statuses: {PartnerStatus.active},
        ),
      ),
      _countPartners(
        PartnerSearchCriteria(
          keyword: baseCriteria.keyword,
          statuses: {PartnerStatus.inactive},
        ),
      ),
    ]);

    return PartnerFilterCounts(
      total: results[0],
      customer: results[1],
      supplier: results[2],
      both: results[3],
      individual: results[4],
      company: results[5],
      household: results[6],
      active: results[7],
      inactive: results[8],
    );
  }

  Future<int> _countPartners(PartnerSearchCriteria criteria) async {
    final tenantId = await _executionContext.requireTenantId();
    final result = await _partnerModule.executeQueryAsync(
      SearchPartnersQuery(
        tenantId: tenantId,
        criteria: criteria,
        limit: 1,
      ),
    );
    return result.totalCount;
  }

  void updateFilter({
    String? role,
    String? profileType,
    String? status,
  }) {
    emit(
      state.copyWith(
        filterRole: role,
        filterProfileType: profileType,
        filterStatus: status,
        clearRole: role == null,
        clearProfileType: profileType == null,
        clearStatus: status == null,
      ),
    );
    load();
  }

  void clearFilters() {
    emit(
      state.copyWith(
        clearRole: true,
        clearProfileType: true,
        clearStatus: true,
      ),
    );
    load();
  }

  void _sortPartners(List<PartnerItemModel> partners) {
    partners.sort((a, b) {
      if (a.status == 'Đang hoạt động' && b.status != 'Đang hoạt động') {
        return -1;
      }
      if (a.status != 'Đang hoạt động' && b.status == 'Đang hoạt động') {
        return 1;
      }
      return 0;
    });
  }
}
