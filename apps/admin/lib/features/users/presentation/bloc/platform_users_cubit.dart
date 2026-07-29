import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vet45_iam_application/application.dart';
import 'package:vet45_shared_application/application.dart';

import 'platform_users_state.dart';

/// Loads and filters platform users via [IIamModule] (Admin / EP-01 US-01).
final class PlatformUsersCubit extends Cubit<PlatformUsersState> {
  PlatformUsersCubit({
    required IIamModule iamModule,
    PlatformUsersState? initialState,
  }) : _iamModule = iamModule,
       super(initialState ?? const PlatformUsersState());

  final IIamModule _iamModule;

  Future<void> load({String? query}) async {
    if (isClosed) return;
    final nextQuery = query ?? state.searchQuery;
    emit(
      state.copyWith(
        status: PlatformUsersStatus.loading,
        searchQuery: nextQuery,
        clearError: true,
      ),
    );

    try {
      final summaries = await _iamModule
          .executeQueryAsync<List<PlatformUserSummaryDto>>(
            SearchPlatformUsersQuery(
              query: nextQuery.trim().isEmpty ? null : nextQuery.trim(),
            ),
          );
      if (isClosed) return;

      final detailsById = <String, PlatformUserDetailDto>{};
      for (final summary in summaries) {
        try {
          final detail = await _iamModule
              .executeQueryAsync<PlatformUserDetailDto>(
                GetPlatformUserQuery(userId: summary.userId),
              );
          detailsById[summary.userId] = detail;
        } catch (_) {
          // Keep summary-only row when detail fetch fails.
        }
      }
      if (isClosed) return;

      emit(
        state.copyWith(
          status: PlatformUsersStatus.success,
          users: summaries,
          detailsById: detailsById,
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
              ? PlatformUsersStatus.unauthorized
              : PlatformUsersStatus.failure,
          errorMessage: message,
        ),
      );
    } catch (e) {
      if (isClosed) return;
      emit(
        state.copyWith(
          status: PlatformUsersStatus.failure,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  void setSearchQuery(String query) {
    emit(state.copyWith(searchQuery: query));
  }

  void setSelectedFilterIndex(int index) {
    emit(state.copyWith(selectedFilterIndex: index));
  }

  void applyAdvancedFilters({
    required int filterStatus,
    required int filterActivation,
    required int filterEmail,
  }) {
    var selectedFilterIndex = state.selectedFilterIndex;
    if (filterStatus == 0) {
      selectedFilterIndex = 0;
    } else if (filterStatus == 1) {
      selectedFilterIndex = 1;
    } else if (filterStatus == 2) {
      selectedFilterIndex = 3;
    }
    emit(
      state.copyWith(
        filterStatus: filterStatus,
        filterActivation: filterActivation,
        filterEmail: filterEmail,
        selectedFilterIndex: selectedFilterIndex,
      ),
    );
  }

  void resetFilters() {
    emit(
      state.copyWith(
        filterStatus: 0,
        filterActivation: 0,
        filterEmail: 0,
        selectedFilterIndex: 0,
        searchQuery: '',
      ),
    );
  }

  Future<void> resetFiltersAndLoad() async {
    if (isClosed) return;
    emit(
      state.copyWith(
        status: PlatformUsersStatus.loading,
        filterStatus: 0,
        filterActivation: 0,
        filterEmail: 0,
        selectedFilterIndex: 0,
        searchQuery: '',
        clearError: true,
      ),
    );

    try {
      final summaries = await _iamModule
          .executeQueryAsync<List<PlatformUserSummaryDto>>(
            SearchPlatformUsersQuery(),
          );
      if (isClosed) return;

      final detailsById = <String, PlatformUserDetailDto>{};
      for (final summary in summaries) {
        try {
          final detail = await _iamModule
              .executeQueryAsync<PlatformUserDetailDto>(
                GetPlatformUserQuery(userId: summary.userId),
              );
          detailsById[summary.userId] = detail;
        } catch (_) {}
      }
      if (isClosed) return;

      emit(
        state.copyWith(
          status: PlatformUsersStatus.success,
          users: summaries,
          detailsById: detailsById,
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
              ? PlatformUsersStatus.unauthorized
              : PlatformUsersStatus.failure,
          errorMessage: message,
        ),
      );
    } catch (e) {
      if (isClosed) return;
      emit(
        state.copyWith(
          status: PlatformUsersStatus.failure,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  void clearUnauthorized() {
    emit(
      state.copyWith(
        status: PlatformUsersStatus.success,
        clearError: true,
      ),
    );
  }

  void clearFailure() {
    emit(
      state.copyWith(
        status: PlatformUsersStatus.success,
        clearError: true,
      ),
    );
  }
}
