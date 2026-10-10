import 'package:erp/core/iam/iam_load_status.dart';
import 'package:erp/core/iam/iam_ui_failure.dart';
import 'package:erp/core/iam/iam_ui_failure_mapper.dart';
import 'package:erp/core/iam/idempotency_key_factory.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vet45_iam_application/application.dart';

import '../data/models/platform_tenant.dart';
import '../data/platform_tenant_repository.dart';
import 'platform_tenant_detail_state.dart';

/// C2 — chi tiết tổ chức và 3 thao tác vòng đời (C4).
final class PlatformTenantDetailCubit extends Cubit<PlatformTenantDetailState> {
  PlatformTenantDetailCubit({
    required String tenantId,
    required PlatformTenantRepository tenants,
    IdempotencyKeyFactory keyFactory = const UuidIdempotencyKeyFactory(),
  }) : _tenantId = tenantId,
       _tenants = tenants,
       _keyFactory = keyFactory,
       super(const PlatformTenantDetailState());

  final String _tenantId;
  final PlatformTenantRepository _tenants;
  final IdempotencyKeyFactory _keyFactory;

  final Map<PlatformTenantAction, String> _keys = {};

  Future<void> load() async {
    if (isClosed) return;
    emit(
      state.copyWith(
        status: IamLoadStatus.loading,
        clearFailure: true,
        clearSuccessMessage: true,
      ),
    );
    try {
      final (detail, members) = await _fetch();
      if (isClosed) return;
      emit(
        state.copyWith(
          status: IamLoadStatus.success,
          detail: detail,
          members: members,
          clearFailure: true,
        ),
      );
    } catch (error) {
      if (isClosed) return;
      final failure = IamUiFailureMapper.from(error);
      emit(
        state.copyWith(
          status: _isUnauthorized(failure) ? IamLoadStatus.unauthorized : IamLoadStatus.failure,
          clearDetail: true,
          failure: failure,
        ),
      );
    }
  }

  /// Gọi mỗi lần mở sheet xác nhận: một khoá cho cả lần mở, dùng lại khi bấm
  /// lại sau lỗi mạng (không tạo thao tác thứ hai).
  void beginAction(PlatformTenantAction action) {
    _keys[action] = _keyFactory.next('${action.name}-platform-tenant-$_tenantId');
  }

  Future<bool> suspend({required String reason}) {
    return _run(
      PlatformTenantAction.suspend,
      successMessage: 'Đã tạm ngừng tổ chức thành công.',
      requiresReason: reason,
      call: (version, key, trimmed) => _tenants.suspend(
        _tenantId,
        reason: trimmed!,
        expectedVersion: version,
        idempotencyKey: key,
      ),
    );
  }

  Future<bool> restore() {
    return _run(
      PlatformTenantAction.restore,
      successMessage: 'Đã khôi phục tổ chức thành công.',
      call: (version, key, _) => _tenants.restore(
        _tenantId,
        expectedVersion: version,
        idempotencyKey: key,
      ),
    );
  }

  Future<bool> closeOrganization({required String reason}) {
    return _run(
      PlatformTenantAction.close,
      successMessage: 'Đã đóng tổ chức.',
      requiresReason: reason,
      call: (version, key, trimmed) => _tenants.close(
        _tenantId,
        reason: trimmed!,
        expectedVersion: version,
        idempotencyKey: key,
      ),
    );
  }

  /// UI đã hiện thông báo thì xoá để không hiện lại khi dựng lại.
  void clearFeedback() {
    if (isClosed) return;
    emit(state.copyWith(clearFailure: true, clearSuccessMessage: true));
  }

  Future<bool> _run(
    PlatformTenantAction action, {
    required String successMessage,
    required Future<void> Function(int version, String key, String? reason) call,
    String? requiresReason,
  }) async {
    final detail = state.detail;
    if (isClosed || detail == null || state.isSubmitting) return false;

    String? reason;
    if (requiresReason != null) {
      reason = requiresReason.trim();
      if (reason.isEmpty) {
        emit(
          state.copyWith(
            failure: const IamUiFailure(
              code: IamBlockedCodes.validationError,
              message: 'Vui lòng nhập lý do.',
            ),
            clearSuccessMessage: true,
          ),
        );
        return false;
      }
    }

    final key = _keys.putIfAbsent(
      action,
      () => _keyFactory.next('${action.name}-platform-tenant-$_tenantId'),
    );
    emit(
      state.copyWith(
        isSubmitting: true,
        clearFailure: true,
        clearSuccessMessage: true,
      ),
    );
    try {
      await call(detail.version, key, reason);
      _keys.remove(action);
      if (isClosed) return true;
      // Thao tác đã thành công ở máy chủ: lỗi tải lại không được báo là thao tác lỗi.
      try {
        final (fresh, members) = await _fetch();
        if (isClosed) return true;
        emit(
          state.copyWith(
            isSubmitting: false,
            status: IamLoadStatus.success,
            detail: fresh,
            members: members,
            successMessage: successMessage,
          ),
        );
      } catch (_) {
        if (isClosed) return true;
        emit(state.copyWith(isSubmitting: false, successMessage: successMessage));
      }
      return true;
    } catch (error) {
      if (isClosed) return false;
      final failure = IamUiFailureMapper.from(error);
      final stale = failure.requiresReload || failure.code == IamBlockedCodes.stateChanged;
      if (stale) _keys.remove(action);
      emit(state.copyWith(isSubmitting: false, failure: failure));
      if (stale) {
        // Lấy lại phiên bản mới để lần xác nhận sau không lỗi nữa.
        try {
          final (fresh, members) = await _fetch();
          if (isClosed) return false;
          emit(state.copyWith(detail: fresh, members: members));
        } catch (_) {}
      }
      return false;
    }
  }

  Future<(PlatformTenantDetail, List<PlatformTenantMember>)> _fetch() async {
    final results = await Future.wait([
      _tenants.get(_tenantId),
      _tenants.listMembers(_tenantId),
    ]);
    return (results[0] as PlatformTenantDetail, results[1] as List<PlatformTenantMember>);
  }

  static bool _isUnauthorized(IamUiFailure failure) {
    return failure.code == IamBlockedCodes.platformPermissionDenied ||
        failure.code == IamBlockedCodes.permissionDenied;
  }
}
