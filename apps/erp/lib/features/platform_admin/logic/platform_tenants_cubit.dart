import 'dart:async';

import 'package:erp/core/iam/iam_load_status.dart';
import 'package:erp/core/iam/iam_ui_failure.dart';
import 'package:erp/core/iam/iam_ui_failure_mapper.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vet45_iam_application/application.dart';

import '../data/platform_tenant_repository.dart';
import 'platform_tenants_state.dart';

/// C1 — danh sách tổ chức của Platform Admin.
final class PlatformTenantsCubit extends Cubit<PlatformTenantsState> {
  PlatformTenantsCubit({
    required PlatformTenantRepository tenants,
    Duration searchDebounce = const Duration(milliseconds: 300),
  }) : _tenants = tenants,
       _searchDebounce = searchDebounce,
       super(const PlatformTenantsState());

  final PlatformTenantRepository _tenants;
  final Duration _searchDebounce;

  Timer? _searchTimer;

  /// Bỏ kết quả của yêu cầu cũ khi người dùng đổi tìm kiếm / chip giữa chừng.
  int _generation = 0;

  Future<void> load() async {
    if (isClosed) return;
    final generation = ++_generation;
    emit(
      state.copyWith(
        status: IamLoadStatus.loading,
        isLoadingMore: false,
        items: const [],
        clearCursor: true,
        clearFailure: true,
      ),
    );
    try {
      final page = await _tenants.search(
        query: state.query,
        status: state.filter.wire,
      );
      if (isClosed || generation != _generation) return;
      emit(
        state.copyWith(
          status: page.items.isEmpty ? IamLoadStatus.empty : IamLoadStatus.success,
          items: page.items,
          nextCursor: page.nextCursor,
          clearCursor: page.nextCursor == null,
        ),
      );
    } catch (error) {
      if (isClosed || generation != _generation) return;
      final failure = IamUiFailureMapper.from(error);
      emit(
        state.copyWith(
          status: _isUnauthorized(failure) ? IamLoadStatus.unauthorized : IamLoadStatus.failure,
          failure: failure,
        ),
      );
    }
  }

  Future<void> loadMore() async {
    final cursor = state.nextCursor;
    if (isClosed || cursor == null || state.isLoadingMore) return;
    if (state.status != IamLoadStatus.success) return;
    final generation = _generation;
    emit(state.copyWith(isLoadingMore: true));
    try {
      final page = await _tenants.search(
        query: state.query,
        status: state.filter.wire,
        cursor: cursor,
      );
      if (isClosed || generation != _generation) return;
      emit(
        state.copyWith(
          items: [...state.items, ...page.items],
          nextCursor: page.nextCursor,
          clearCursor: page.nextCursor == null,
          isLoadingMore: false,
        ),
      );
    } catch (error) {
      if (isClosed || generation != _generation) return;
      emit(state.copyWith(isLoadingMore: false, failure: IamUiFailureMapper.from(error)));
    }
  }

  /// Gõ tìm kiếm: chờ [_searchDebounce] rồi tải lại từ đầu.
  void setQuery(String query) {
    if (isClosed || query == state.query) return;
    emit(state.copyWith(query: query));
    _searchTimer?.cancel();
    _searchTimer = Timer(_searchDebounce, () => unawaited(load()));
  }

  void setFilter(PlatformTenantFilter filter) {
    if (isClosed || filter == state.filter) return;
    _searchTimer?.cancel();
    emit(state.copyWith(filter: filter));
    unawaited(load());
  }

  /// "Xóa tìm kiếm" / "Xóa bộ lọc" ở trạng thái không có kết quả.
  void clearFilters() {
    if (isClosed) return;
    _searchTimer?.cancel();
    emit(state.copyWith(query: '', filter: PlatformTenantFilter.all));
    unawaited(load());
  }

  @override
  Future<void> close() {
    _searchTimer?.cancel();
    return super.close();
  }

  static bool _isUnauthorized(IamUiFailure failure) {
    return failure.code == IamBlockedCodes.platformPermissionDenied ||
        failure.code == IamBlockedCodes.permissionDenied;
  }
}
