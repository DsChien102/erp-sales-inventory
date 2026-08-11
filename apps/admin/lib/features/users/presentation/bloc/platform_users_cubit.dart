import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vet45_iam_application/application.dart';
import 'package:vet45_iam_presentation/presentation.dart';

import 'platform_users_state.dart';

/// Loads platform users via [SearchPlatformUsersQuery] only (no detail fan-out).
final class PlatformUsersCubit extends Cubit<PlatformUsersState> {
  PlatformUsersCubit({
    required IIamModule iamModule,
    PlatformUsersState? initialState,
  }) : _iamModule = iamModule,
       super(initialState ?? const PlatformUsersState());

  final IIamModule _iamModule;

  Future<void> load({bool reset = true}) async {
    if (isClosed) return;
    if (reset) {
      emit(
        state.copyWith(
          status: IamLoadStatus.loading,
          clearFailure: true,
          clearNextCursor: true,
          isLoadingMore: false,
        ),
      );
    }

    try {
      final page = await _iamModule
          .executeQueryAsync<CursorPageDto<PlatformUserSummaryDto>>(
            SearchPlatformUsersQuery(
              query: state.searchQuery.trim().isEmpty
                  ? null
                  : state.searchQuery.trim(),
              status: state.statusFilter,
              cursor: reset ? null : state.nextCursor,
            ),
          );
      if (isClosed) return;

      final users = reset
          ? page.items
          : _dedupeAppend(state.users, page.items);

      emit(
        state.copyWith(
          status: users.isEmpty ? IamLoadStatus.empty : IamLoadStatus.success,
          users: users,
          nextCursor: page.nextCursor,
          clearNextCursor: page.nextCursor == null,
          isLoadingMore: false,
          clearFailure: true,
        ),
      );
    } catch (error) {
      if (isClosed) return;
      final failure = IamUiFailureMapper.from(error);
      emit(
        state.copyWith(
          status: failure.code == IamBlockedCodes.platformPermissionDenied
              ? IamLoadStatus.unauthorized
              : IamLoadStatus.failure,
          failure: failure,
          isLoadingMore: false,
        ),
      );
    }
  }

  Future<void> loadNextPage() async {
    if (isClosed || state.isLoadingMore || !state.hasMore) return;
    emit(state.copyWith(isLoadingMore: true, clearFailure: true));
    await load(reset: false);
  }

  Future<void> setSearchQuery(String value) async {
    if (isClosed) return;
    emit(state.copyWith(searchQuery: value));
    await load(reset: true);
  }

  Future<void> setStatusFilter(PlatformUserStatus? status) async {
    if (isClosed) return;
    emit(
      state.copyWith(
        statusFilter: status,
        clearStatusFilter: status == null,
      ),
    );
    await load(reset: true);
  }

  Future<void> refresh() => load(reset: true);

  Future<void> resetFiltersAndLoad() async {
    if (isClosed) return;
    emit(
      state.copyWith(
        searchQuery: '',
        clearStatusFilter: true,
        clearFailure: true,
      ),
    );
    await load(reset: true);
  }

  void clearUnauthorized() {
    if (isClosed) return;
    emit(
      state.copyWith(
        status: IamLoadStatus.success,
        clearFailure: true,
      ),
    );
  }

  void clearFailure() {
    if (isClosed) return;
    emit(state.copyWith(clearFailure: true));
  }

  List<PlatformUserSummaryDto> _dedupeAppend(
    List<PlatformUserSummaryDto> existing,
    List<PlatformUserSummaryDto> incoming,
  ) {
    final seen = existing.map((u) => u.userId).toSet();
    final out = List<PlatformUserSummaryDto>.of(existing);
    for (final item in incoming) {
      if (seen.add(item.userId)) {
        out.add(item);
      }
    }
    return out;
  }
}
