import 'package:erp/core/iam/iam_load_status.dart';
import 'package:erp/core/iam/iam_ui_failure.dart';
import 'package:erp/core/iam/iam_ui_failure_mapper.dart';
import 'package:erp/core/iam/idempotency_key_factory.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vet45_iam_application/application.dart';

import '../data/models/platform_tenant.dart';
import '../data/platform_tenant_repository.dart';
import 'change_owner_state.dart';

/// C5 / C6 — chọn Chủ sở hữu mới và chuyển quyền.
final class ChangeOwnerCubit extends Cubit<ChangeOwnerState> {
  ChangeOwnerCubit({
    required String tenantId,
    required PlatformTenantRepository tenants,
    IdempotencyKeyFactory keyFactory = const UuidIdempotencyKeyFactory(),
  }) : _tenantId = tenantId,
       _tenants = tenants,
       _keyFactory = keyFactory,
       super(const ChangeOwnerState());

  final String _tenantId;
  final PlatformTenantRepository _tenants;
  final IdempotencyKeyFactory _keyFactory;

  String? _key;
  String? _keyedUserId;

  Future<void> load() async {
    if (isClosed) return;
    emit(state.copyWith(status: IamLoadStatus.loading, clearFailure: true));
    try {
      final results = await Future.wait([
        _tenants.get(_tenantId),
        _tenants.listMembers(_tenantId),
      ]);
      if (isClosed) return;
      final detail = results[0] as PlatformTenantDetail;
      final next = state.copyWith(
        detail: detail,
        members: results[1] as List<PlatformTenantMember>,
      );
      emit(
        next.copyWith(
          status: next.candidates.isEmpty ? IamLoadStatus.empty : IamLoadStatus.success,
          // Người đang chọn có thể đã rời tổ chức sau khi tải lại.
          clearSelection: next.selected == null,
        ),
      );
    } catch (error) {
      if (isClosed) return;
      emit(
        state.copyWith(
          status: IamLoadStatus.failure,
          failure: IamUiFailureMapper.from(error),
        ),
      );
    }
  }

  void setQuery(String query) {
    if (isClosed || query == state.query) return;
    emit(state.copyWith(query: query));
  }

  /// Chọn lại cùng thành viên thì bỏ chọn.
  void toggle(String userId) {
    if (isClosed || state.isSubmitting) return;
    final isSelected = state.selectedUserId == userId;
    if (isSelected) {
      emit(state.copyWith(clearSelection: true));
    } else {
      emit(state.copyWith(selectedUserId: userId));
    }
  }

  /// Chuyển Owner cho người đang chọn. `true` khi máy chủ xác nhận.
  Future<bool> confirm() async {
    final detail = state.detail;
    final target = state.selected;
    if (isClosed || detail == null || target == null || state.isSubmitting) return false;

    // Khoá theo người nhận: đổi người nhận thì là một thao tác khác.
    if (_keyedUserId != target.userId || _key == null) {
      _key = _keyFactory.next('transfer-owner-platform-tenant-$_tenantId');
      _keyedUserId = target.userId;
    }
    emit(state.copyWith(isSubmitting: true, clearFailure: true));
    try {
      await _tenants.transferOwnership(
        _tenantId,
        newOwnerUserId: target.userId,
        expectedVersion: detail.version,
        idempotencyKey: _key!,
      );
      _key = null;
      _keyedUserId = null;
      if (isClosed) return true;
      emit(state.copyWith(isSubmitting: false, completed: true));
      return true;
    } catch (error) {
      if (isClosed) return false;
      final failure = _mapFailure(error);
      if (failure.requiresReload || failure.code == IamBlockedCodes.stateChanged) {
        _key = null;
        _keyedUserId = null;
      }
      emit(state.copyWith(isSubmitting: false, failure: failure));
      return false;
    }
  }

  void clearFailure() {
    if (isClosed || state.failure == null) return;
    emit(state.copyWith(clearFailure: true));
  }

  static IamUiFailure _mapFailure(Object error) {
    final failure = IamUiFailureMapper.from(error);
    if (failure.code == IamBlockedCodes.ownerTargetInvalid) {
      return IamUiFailure(code: failure.code, message: 'Không thể chọn thành viên này.');
    }
    return failure;
  }
}
