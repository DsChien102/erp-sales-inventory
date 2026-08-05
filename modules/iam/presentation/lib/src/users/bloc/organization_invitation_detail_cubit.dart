import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vet45_iam_application/application.dart';
import 'package:vet45_shared_application/application.dart';

import '../../shared/iam_load_status.dart';
import '../../shared/iam_ui_failure.dart';
import '../../shared/iam_ui_failure_mapper.dart';
import '../../shared/idempotency_key_factory.dart';
import 'organization_invitation_detail_state.dart';

final class OrganizationInvitationDetailCubit
    extends Cubit<OrganizationInvitationDetailState> {
  OrganizationInvitationDetailCubit({
    required String invitationId,
    required IIamModule iamModule,
    required IExecutionContext executionContext,
    required IdempotencyKeyFactory keyFactory,
  }) : _invitationId = invitationId,
       _iamModule = iamModule,
       _executionContext = executionContext,
       _keyFactory = keyFactory,
       super(const OrganizationInvitationDetailState());

  final String _invitationId;
  final IIamModule _iamModule;
  final IExecutionContext _executionContext;
  final IdempotencyKeyFactory _keyFactory;

  Future<void> load() async {
    if (isClosed) return;
    emit(
      state.copyWith(
        status: IamLoadStatus.loading,
        clearFailure: true,
        clearSuccessMessage: true,
        deliveryWarning: false,
      ),
    );
    try {
      final detail = await _fetchDetail();
      if (isClosed) return;
      emit(
        state.copyWith(
          status: IamLoadStatus.success,
          invitation: detail,
          clearFailure: true,
          clearSuccessMessage: true,
          deliveryWarning: false,
        ),
      );
    } catch (error) {
      if (isClosed) return;
      emit(
        state.copyWith(
          status: IamLoadStatus.failure,
          clearInvitation: true,
          failure: IamUiFailureMapper.from(error),
        ),
      );
    }
  }

  Future<void> resend() async {
    if (isClosed || state.isSubmitting || !state.canMutate) return;
    final before = state.invitation!;
    emit(
      state.copyWith(
        isSubmitting: true,
        activeMutation: InvitationMutation.resend,
        clearFailure: true,
        clearSuccessMessage: true,
        deliveryWarning: false,
      ),
    );
    try {
      final tenantId = await _executionContext.requireTenantId();
      final updated = await _iamModule
          .executeCommandAsync<InvitationDetailDto>(
            ResendInvitationCommand(
              tenantId: tenantId,
              invitationId: _invitationId,
              expectedVersion: before.version,
              idempotencyKey: _keyFactory.next('resend-invitation'),
            ),
          );
      if (isClosed) return;
      final deliveryFailed = updated.deliveryStatus == 'failed';
      emit(
        state.copyWith(
          isSubmitting: false,
          clearMutation: true,
          invitation: updated,
          status: IamLoadStatus.success,
          deliveryWarning: deliveryFailed,
          successMessage: deliveryFailed
              ? 'Lời mời vẫn còn hiệu lực nhưng gửi email thất bại.'
              : 'Đã gửi lại lời mời.',
          clearFailure: true,
        ),
      );
    } catch (error) {
      await _handleMutationError(error);
    }
  }

  Future<void> revoke({required String reason}) async {
    if (isClosed || state.isSubmitting || !state.canMutate) return;
    final trimmed = reason.trim();
    if (trimmed.isEmpty) {
      emit(
        state.copyWith(
          failure: const IamUiFailure(
            code: IamBlockedCodes.validationError,
            message: 'Vui lòng nhập lý do thu hồi.',
          ),
          clearSuccessMessage: true,
          deliveryWarning: false,
        ),
      );
      return;
    }

    final before = state.invitation!;
    emit(
      state.copyWith(
        isSubmitting: true,
        activeMutation: InvitationMutation.revoke,
        clearFailure: true,
        clearSuccessMessage: true,
        deliveryWarning: false,
      ),
    );
    try {
      final tenantId = await _executionContext.requireTenantId();
      final updated = await _iamModule
          .executeCommandAsync<InvitationDetailDto>(
            RevokeInvitationCommand(
              tenantId: tenantId,
              invitationId: _invitationId,
              expectedVersion: before.version,
              reason: trimmed,
              idempotencyKey: _keyFactory.next('revoke-invitation'),
            ),
          );
      if (isClosed) return;
      emit(
        state.copyWith(
          isSubmitting: false,
          clearMutation: true,
          invitation: updated,
          status: IamLoadStatus.success,
          successMessage: 'Đã thu hồi lời mời.',
          deliveryWarning: false,
          clearFailure: true,
        ),
      );
    } catch (error) {
      await _handleMutationError(error);
    }
  }

  void clearFeedback() {
    if (isClosed) return;
    emit(
      state.copyWith(
        clearFailure: true,
        clearSuccessMessage: true,
        deliveryWarning: false,
      ),
    );
  }

  Future<InvitationDetailDto> _fetchDetail() async {
    final tenantId = await _executionContext.requireTenantId();
    return _iamModule.executeQueryAsync<InvitationDetailDto>(
      GetInvitationQuery(
        tenantId: tenantId,
        invitationId: _invitationId,
      ),
    );
  }

  Future<void> _handleMutationError(Object error) async {
    if (isClosed) return;
    final failure = IamUiFailureMapper.from(error);
    if (failure.requiresReload ||
        failure.code == IamBlockedCodes.stateChanged) {
      try {
        final detail = await _fetchDetail();
        if (isClosed) return;
        emit(
          state.copyWith(
            isSubmitting: false,
            clearMutation: true,
            status: IamLoadStatus.success,
            invitation: detail,
            failure: failure,
            clearSuccessMessage: true,
            deliveryWarning: false,
          ),
        );
        return;
      } catch (_) {
        // Fall through to plain failure emit.
      }
    }
    if (isClosed) return;
    emit(
      state.copyWith(
        isSubmitting: false,
        clearMutation: true,
        failure: failure,
        clearSuccessMessage: true,
        deliveryWarning: false,
      ),
    );
  }
}
