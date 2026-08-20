import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vet45_iam_application/application.dart';
import 'package:vet45_iam_domain/domain.dart';
import 'package:vet45_shared_application/application.dart';

import '../../shared/iam_load_status.dart';
import '../../shared/iam_ui_failure_mapper.dart';
import 'organization_member_detail_state.dart';

final class OrganizationMemberDetailCubit
    extends Cubit<OrganizationMemberDetailState> {
  OrganizationMemberDetailCubit({
    required String membershipId,
    required IIamModule iamModule,
    required IExecutionContext executionContext,
  }) : _membershipId = membershipId,
       _iamModule = iamModule,
       _executionContext = executionContext,
       super(const OrganizationMemberDetailState());

  final String _membershipId;
  final IIamModule _iamModule;
  final IExecutionContext _executionContext;

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
      final detail = await _fetchDetail();
      if (isClosed) return;
      emit(
        state.copyWith(
          status: IamLoadStatus.success,
          member: detail,
          clearFailure: true,
          clearSuccessMessage: true,
        ),
      );
    } catch (error) {
      if (isClosed) return;
      emit(
        state.copyWith(
          status: IamLoadStatus.failure,
          clearMember: true,
          failure: IamUiFailureMapper.from(error),
        ),
      );
    }
  }

  Future<void> deactivate() async {
    if (isClosed || state.isSubmitting || !state.canDeactivate) return;
    await _mutate(
      mutation: MembershipMutation.deactivate,
      successMessage: 'Đã tạm ngừng thành viên.',
      expectedStatus: MembershipStatus.inactive,
      run: (tenantId, before) => _iamModule
          .executeCommandAsync<TenantMemberDetailDto>(
            DeactivateMembershipCommand(
              tenantId: tenantId,
              membershipId: _membershipId,
              expectedVersion: before.version,
            ),
          ),
    );
  }

  Future<void> reactivate() async {
    if (isClosed || state.isSubmitting || !state.canReactivate) return;
    await _mutate(
      mutation: MembershipMutation.reactivate,
      successMessage: 'Đã kích hoạt lại thành viên.',
      expectedStatus: MembershipStatus.active,
      run: (tenantId, before) => _iamModule
          .executeCommandAsync<TenantMemberDetailDto>(
            ReactivateMembershipCommand(
              tenantId: tenantId,
              membershipId: _membershipId,
              expectedVersion: before.version,
            ),
          ),
    );
  }

  Future<void> remove() async {
    if (isClosed || state.isSubmitting || !state.canRemove) return;
    await _mutate(
      mutation: MembershipMutation.remove,
      successMessage: 'Đã loại thành viên khỏi tổ chức.',
      expectedStatus: MembershipStatus.removed,
      run: (tenantId, before) => _iamModule
          .executeCommandAsync<TenantMemberDetailDto>(
            RemoveMembershipCommand(
              tenantId: tenantId,
              membershipId: _membershipId,
              expectedVersion: before.version,
            ),
          ),
    );
  }

  Future<void> changeRole(String newRoleCode) async {
    if (isClosed || state.isSubmitting || !state.canChangeRole) return;
    emit(
      state.copyWith(
        isSubmitting: true,
        activeMutation: MembershipMutation.changeRole,
        clearFailure: true,
        clearSuccessMessage: true,
      ),
    );
    try {
      final tenantId = await _executionContext.requireTenantId();
      final member = state.member!;
      await _iamModule.executeCommandAsync<void>(
        AssignMemberRoleCommand(
          tenantId: tenantId,
          userId: member.userId,
          role: newRoleCode,
        ),
      );
      final updated = await _fetchDetail();
      if (isClosed) return;
      emit(
        state.copyWith(
          isSubmitting: false,
          clearMutation: true,
          status: IamLoadStatus.success,
          member: updated,
          successMessage: 'Đã thay đổi vai trò thành công.',
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
      ),
    );
  }

  Future<void> _mutate({
    required MembershipMutation mutation,
    required String successMessage,
    required MembershipStatus expectedStatus,
    required Future<TenantMemberDetailDto> Function(
      String tenantId,
      TenantMemberDetailDto before,
    ) run,
  }) async {
    final before = state.member!;
    emit(
      state.copyWith(
        isSubmitting: true,
        activeMutation: mutation,
        clearFailure: true,
        clearSuccessMessage: true,
      ),
    );
    try {
      final tenantId = await _executionContext.requireTenantId();
      final updated = await run(tenantId, before);
      if (isClosed) return;
      // Defense: never apply unexpected local mutation shape.
      if (updated.status != expectedStatus) {
        emit(
          state.copyWith(
            isSubmitting: false,
            clearMutation: true,
            failure: IamUiFailureMapper.from(
              const IamBlockedException(IamBlockedCodes.systemError),
            ),
          ),
        );
        return;
      }
      emit(
        state.copyWith(
          isSubmitting: false,
          clearMutation: true,
          status: IamLoadStatus.success,
          member: updated,
          successMessage: successMessage,
          clearFailure: true,
        ),
      );
    } catch (error) {
      await _handleMutationError(error);
    }
  }

  Future<TenantMemberDetailDto> _fetchDetail() async {
    final tenantId = await _executionContext.requireTenantId();
    return _iamModule.executeQueryAsync<TenantMemberDetailDto>(
      GetTenantMemberQuery(
        tenantId: tenantId,
        membershipId: _membershipId,
      ),
    );
  }

  Future<void> _handleMutationError(Object error) async {
    if (isClosed) return;
    final failure = IamUiFailureMapper.from(error);
    final shouldReload = failure.requiresReload ||
        failure.code == IamBlockedCodes.stateChanged ||
        failure.code == IamBlockedCodes.membershipRemoved;
    if (shouldReload) {
      try {
        final detail = await _fetchDetail();
        if (isClosed) return;
        emit(
          state.copyWith(
            isSubmitting: false,
            clearMutation: true,
            status: IamLoadStatus.success,
            member: detail,
            failure: failure,
            clearSuccessMessage: true,
          ),
        );
        return;
      } catch (_) {
        // Fall through.
      }
    }
    if (isClosed) return;
    emit(
      state.copyWith(
        isSubmitting: false,
        clearMutation: true,
        failure: failure,
        clearSuccessMessage: true,
      ),
    );
  }
}
