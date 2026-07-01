import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vet45_partner_application/application.dart';
import 'package:vet45_partner_domain/domain.dart';
import 'package:vet45_shared_application/application.dart';

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
        clearErrorMessage: true,
      ),
    );

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
        ),
      );

      emit(
        state.copyWith(
          status: PartnerListStatus.success,
          partners: result.items
              .map(PartnerUiMapper.toListItem)
              .toList(growable: false),
          clearErrorMessage: true,
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          status: PartnerListStatus.failure,
          errorMessage: partnerErrorMessage(error),
        ),
      );
    }
  }

  void search(String query) {
    emit(state.copyWith(searchQuery: query));
    load();
  }

  Future<PartnerFilterCounts> fetchFilterCounts() async {
    final tenantId = await _executionContext.requireTenantId();
    final result = await _partnerModule.executeQueryAsync(
      SearchPartnersQuery(
        tenantId: tenantId,
        criteria: PartnerSearchCriteria(
          keyword: state.searchQuery.trim().isEmpty
              ? null
              : state.searchQuery.trim(),
          statuses: {
            PartnerStatus.active,
            PartnerStatus.inactive,
          },
        ),
        limit: 500,
      ),
    );

    return PartnerUiMapper.toFilterCounts(result.items);
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
}
