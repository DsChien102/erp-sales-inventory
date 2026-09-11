import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vet45_iam_application/application.dart';
import 'package:vet45_iam_domain/domain.dart';
import 'package:vet45_shared_application/application.dart';

import '../../shared/iam_load_status.dart';
import '../../shared/iam_ui_failure_mapper.dart';
import '../../shared/idempotency_key_factory.dart';
import 'tenant_readiness_state.dart';

final class TenantReadinessCubit extends Cubit<TenantReadinessState> {
  TenantReadinessCubit({
    required IIamModule iamModule,
    required IExecutionContext executionContext,
    required IdempotencyKeyFactory keyFactory,
  }) : _iamModule = iamModule,
       _executionContext = executionContext,
       _keyFactory = keyFactory,
       super(const TenantReadinessState());

  final IIamModule _iamModule;
  final IExecutionContext _executionContext;
  final IdempotencyKeyFactory _keyFactory;

  String? _activationKey;

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
      final tenantId = await _executionContext.requireTenantId();
      final readiness = await _iamModule.executeQueryAsync<TenantReadinessDto>(
        GetTenantReadinessQuery(tenantId: tenantId),
      );
      if (isClosed) return;
      emit(
        state.copyWith(
          status: IamLoadStatus.success,
          readiness: readiness,
          clearFailure: true,
        ),
      );
    } catch (error) {
      if (isClosed) return;
      emit(
        state.copyWith(
          status: IamLoadStatus.failure,
          clearReadiness: true,
          failure: IamUiFailureMapper.from(error),
        ),
      );
    }
  }

  Future<bool> activate() async {
    if (isClosed || state.isActivating) return false;
    final readiness = state.readiness;
    if (readiness == null) {
      emit(
        state.copyWith(
          failure: IamUiFailureMapper.from(
            const IamBlockedException(IamBlockedCodes.readinessBlocked),
          ),
          clearSuccessMessage: true,
        ),
      );
      return false;
    }

    if (readiness.status == TenantLifecycleStatus.active) {
      _activationKey = null;
      emit(
        state.copyWith(
          successMessage: 'Tổ chức đã được kích hoạt.',
          clearFailure: true,
        ),
      );
      return true;
    }

    if (!state.canStartActivation) {
      emit(
        state.copyWith(
          failure: IamUiFailureMapper.from(
            const IamBlockedException(IamBlockedCodes.readinessBlocked),
          ),
          clearSuccessMessage: true,
        ),
      );
      return false;
    }

    emit(
      state.copyWith(
        isActivating: true,
        clearFailure: true,
        clearSuccessMessage: true,
        clearActivation: true,
      ),
    );

    try {
      final tenantId = await _executionContext.requireTenantId();
      final key = _activationKey ??= _keyFactory.next('activate-tenant');
      final result = await _iamModule.executeCommandAsync<TenantActivationResultDto>(
        ActivateTenantCommand(
          tenantId: tenantId,
          expectedVersion: readiness.tenantVersion,
          idempotencyKey: key,
        ),
      );
      if (isClosed) return false;
      _activationKey = null;
      emit(
        state.copyWith(
          isActivating: false,
          activation: result,
          successMessage: 'Đã kích hoạt tổ chức.',
          clearFailure: true,
        ),
      );
      // Refresh tenant context for business home.
      await _iamModule.executeQueryAsync<TenantContextDto>(
        GetTenantContextQuery(bootstrapFromLastSelected: false),
      );
      return true;
    } catch (error) {
      return _handleActivateError(error);
    }
  }

  void clearFeedback() {
    if (isClosed) return;
    emit(
      state.copyWith(
        clearFailure: true,
        clearSuccessMessage: true,
      ),
    );
  }

  Future<bool> _handleActivateError(Object error) async {
    if (isClosed) return false;
    final failure = IamUiFailureMapper.from(error);

    if (failure.code == IamBlockedCodes.tenantStateInvalid) {
      _activationKey = null;
      emit(
        state.copyWith(
          isActivating: false,
          successMessage: 'Tổ chức đã được kích hoạt.',
          clearFailure: true,
        ),
      );
      return true;
    }

    if (failure.code == IamBlockedCodes.readinessBlocked ||
        failure.code == IamBlockedCodes.stateChanged) {
      try {
        final tenantId = await _executionContext.requireTenantId();
        final readiness = await _iamModule.executeQueryAsync<TenantReadinessDto>(
          GetTenantReadinessQuery(tenantId: tenantId),
        );
        if (isClosed) return false;
        if (failure.code == IamBlockedCodes.stateChanged) {
          _activationKey = null;
        }
        emit(
          state.copyWith(
            isActivating: false,
            status: IamLoadStatus.success,
            readiness: readiness,
            failure: failure,
            clearSuccessMessage: true,
            clearActivation: true,
          ),
        );
        return false;
      } catch (_) {
        // Fall through.
      }
    }

    if (isClosed) return false;
    emit(
      state.copyWith(
        isActivating: false,
        failure: failure,
        clearSuccessMessage: true,
      ),
    );
    return false;
  }
}
