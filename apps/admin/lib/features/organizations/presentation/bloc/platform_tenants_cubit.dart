import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vet45_iam_application/application.dart';
import 'package:vet45_iam_presentation/presentation.dart';
import 'package:vet45_shared_application/application.dart';

import '../mappers/platform_tenant_ui_mapper.dart';
import 'platform_tenants_state.dart';

final class PlatformTenantsCubit extends Cubit<PlatformTenantsState> {
  PlatformTenantsCubit({
    required IIamModule iamModule,
    PlatformTenantsState? initialState,
  }) : _iamModule = iamModule,
       super(initialState ?? const PlatformTenantsState());

  final IIamModule _iamModule;

  Future<void> load({String? query}) async {
    if (isClosed) return;
    final nextQuery = query ?? state.searchQuery;
    emit(
      state.copyWith(
        status: PlatformTenantsStatus.loading,
        searchQuery: nextQuery,
        clearError: true,
      ),
    );

    try {
      final summaries = await _iamModule
          .executeQueryAsync<List<PlatformTenantSummaryDto>>(
            SearchPlatformTenantsQuery(
              query: nextQuery.trim().isEmpty ? null : nextQuery.trim(),
            ),
          );
      if (isClosed) return;

      final tenants = <OrganizationUiModel>[];
      for (final summary in summaries) {
        try {
          final detail = await _iamModule
              .executeQueryAsync<PlatformTenantDetailDto>(
                GetPlatformTenantQuery(tenantId: summary.tenantId),
              );
          tenants.add(PlatformTenantUiMapper.fromDetail(detail));
        } catch (_) {
          tenants.add(PlatformTenantUiMapper.fromSummary(summary));
        }
      }
      if (isClosed) return;

      emit(
        state.copyWith(
          status: PlatformTenantsStatus.success,
          tenants: tenants,
          clearError: true,
        ),
      );
    } on ApplicationException catch (e) {
      if (isClosed) return;
      final message = e.message;
      final unauthorized =
          message.contains('PLATFORM_PERMISSION_DENIED') ||
          message.contains('403') ||
          message.contains('permission');
      emit(
        state.copyWith(
          status: unauthorized
              ? PlatformTenantsStatus.unauthorized
              : PlatformTenantsStatus.failure,
          errorMessage: message,
        ),
      );
    } catch (e) {
      if (isClosed) return;
      emit(
        state.copyWith(
          status: PlatformTenantsStatus.failure,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  void setSearchQuery(String query) {
    emit(state.copyWith(searchQuery: query));
  }

  void setFilterCriteria(OrganizationFilterCriteria criteria) {
    emit(state.copyWith(filterCriteria: criteria));
  }

  void setStatusFilter(OrganizationStatus status) {
    emit(
      state.copyWith(
        filterCriteria: state.filterCriteria.copyWith(status: status),
      ),
    );
  }

  void clearFilters() {
    emit(
      state.copyWith(
        searchQuery: '',
        filterCriteria: const OrganizationFilterCriteria(),
      ),
    );
  }
}
