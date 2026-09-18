import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vet45_iam_application/application.dart';
import 'package:vet45_shared_application/application.dart';

import '../mappers/platform_tenant_ui_mapper.dart';
import 'platform_tenant_detail_state.dart';

final class PlatformTenantDetailCubit extends Cubit<PlatformTenantDetailState> {
  PlatformTenantDetailCubit({
    required IIamModule iamModule,
    required this.tenantId,
  }) : _iamModule = iamModule,
       super(const PlatformTenantDetailState());

  final IIamModule _iamModule;
  final String tenantId;

  int get _expectedVersion {
    final raw = state.organization?.dataVersion;
    if (raw == null) return 1;
    return int.tryParse(raw.replaceFirst(RegExp(r'^[vV]'), '')) ?? 1;
  }

  Future<void> load() async {
    if (isClosed) return;
    emit(
      state.copyWith(
        status: PlatformTenantDetailStatus.loading,
        clearError: true,
      ),
    );

    try {
      final detail = await _iamModule.executeQueryAsync<PlatformTenantDetailDto>(
        GetPlatformTenantQuery(tenantId: tenantId),
      );
      if (isClosed) return;
      emit(
        state.copyWith(
          status: PlatformTenantDetailStatus.success,
          organization: PlatformTenantUiMapper.fromDetail(detail),
          clearError: true,
        ),
      );
    } on ApplicationException catch (e) {
      if (isClosed) return;
      final unauthorized = e.message.contains('PLATFORM_PERMISSION_DENIED');
      emit(
        state.copyWith(
          status: unauthorized
              ? PlatformTenantDetailStatus.unauthorized
              : PlatformTenantDetailStatus.failure,
          errorMessage: e.message,
        ),
      );
    } catch (e) {
      if (isClosed) return;
      emit(
        state.copyWith(
          status: PlatformTenantDetailStatus.failure,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  Future<bool> suspend({required String reason}) async {
    if (isClosed) return false;
    final trimmed = reason.trim();
    if (trimmed.isEmpty) {
      emit(
        state.copyWith(
          actionInProgress: false,
          errorMessage: 'Vui lòng nhập lý do tạm ngừng.',
        ),
      );
      return false;
    }
    emit(state.copyWith(actionInProgress: true, clearError: true));
    try {
      await _iamModule.executeCommandAsync(
        SuspendPlatformTenantCommand(
          tenantId: tenantId,
          reason: trimmed,
          expectedVersion: _expectedVersion,
          idempotencyKey: 'suspend-$tenantId-${DateTime.now().microsecondsSinceEpoch}',
        ),
      );
      await load();
      return true;
    } on ApplicationException catch (e) {
      if (!isClosed) {
        emit(state.copyWith(actionInProgress: false, errorMessage: e.message));
      }
      return false;
    } catch (e) {
      if (!isClosed) {
        emit(
          state.copyWith(actionInProgress: false, errorMessage: e.toString()),
        );
      }
      return false;
    } finally {
      if (!isClosed) emit(state.copyWith(actionInProgress: false));
    }
  }

  Future<bool> closeOrganization({required String reason}) async {
    if (isClosed) return false;
    final trimmed = reason.trim();
    if (trimmed.isEmpty) {
      emit(
        state.copyWith(
          actionInProgress: false,
          errorMessage: 'Vui lòng nhập lý do đóng tổ chức.',
        ),
      );
      return false;
    }
    emit(state.copyWith(actionInProgress: true, clearError: true));
    try {
      await _iamModule.executeCommandAsync(
        ClosePlatformTenantCommand(
          tenantId: tenantId,
          reason: trimmed,
          expectedVersion: _expectedVersion,
          idempotencyKey: 'close-$tenantId-${DateTime.now().microsecondsSinceEpoch}',
        ),
      );
      await load();
      return true;
    } on ApplicationException catch (e) {
      if (!isClosed) {
        emit(state.copyWith(actionInProgress: false, errorMessage: e.message));
      }
      return false;
    } catch (e) {
      if (!isClosed) {
        emit(
          state.copyWith(actionInProgress: false, errorMessage: e.toString()),
        );
      }
      return false;
    } finally {
      if (!isClosed) emit(state.copyWith(actionInProgress: false));
    }
  }

  Future<bool> restore() async {
    if (isClosed) return false;
    emit(state.copyWith(actionInProgress: true, clearError: true));
    try {
      await _iamModule.executeCommandAsync(
        RestorePlatformTenantCommand(
          tenantId: tenantId,
          expectedVersion: _expectedVersion,
          idempotencyKey: 'restore-$tenantId-${DateTime.now().microsecondsSinceEpoch}',
        ),
      );
      await load();
      return true;
    } on ApplicationException catch (e) {
      if (!isClosed) {
        emit(state.copyWith(actionInProgress: false, errorMessage: e.message));
      }
      return false;
    } catch (e) {
      if (!isClosed) {
        emit(
          state.copyWith(actionInProgress: false, errorMessage: e.toString()),
        );
      }
      return false;
    } finally {
      if (!isClosed) emit(state.copyWith(actionInProgress: false));
    }
  }

  Future<bool> transferOwnership({
    required String newOwnerUserId,
    required String idempotencyKey,
  }) async {
    if (isClosed) return false;
    emit(state.copyWith(actionInProgress: true, clearError: true));
    try {
      await _iamModule.executeCommandAsync(
        TransferPlatformTenantOwnershipCommand(
          tenantId: tenantId,
          newOwnerUserId: newOwnerUserId,
          expectedVersion: _expectedVersion,
          idempotencyKey: idempotencyKey,
        ),
      );
      await load();
      return true;
    } on ApplicationException catch (e) {
      if (!isClosed) {
        emit(state.copyWith(actionInProgress: false, errorMessage: e.message));
      }
      return false;
    } catch (e) {
      if (!isClosed) {
        emit(
          state.copyWith(actionInProgress: false, errorMessage: e.toString()),
        );
      }
      return false;
    } finally {
      if (!isClosed) emit(state.copyWith(actionInProgress: false));
    }
  }
}
