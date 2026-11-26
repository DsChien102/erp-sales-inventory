import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:erp/core/errors/app_exception.dart';
import 'package:erp/core/iam/iam_codes.dart';

import '../data/member_repository.dart';
import '../data/models/tenant_member.dart';
import 'iam_load_status.dart';
import 'iam_ui_failure_mapper.dart';
import 'organization_member_detail_state.dart';

final class OrganizationMemberDetailCubit
    extends Cubit<OrganizationMemberDetailState> {
  OrganizationMemberDetailCubit({
    required String membershipId,
    required MemberRepository members,
  }) : _membershipId = membershipId,
       _members = members,
       super(const OrganizationMemberDetailState());

  final String _membershipId;
  final MemberRepository _members;

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
      run: (before) => _members.deactivate(
        _membershipId,
        expectedVersion: before.version,
      ),
    );
  }

  Future<void> reactivate() async {
    if (isClosed || state.isSubmitting || !state.canReactivate) return;
    await _mutate(
      mutation: MembershipMutation.reactivate,
      successMessage: 'Đã kích hoạt lại thành viên.',
      expectedStatus: MembershipStatus.active,
      run: (before) => _members.reactivate(
        _membershipId,
        expectedVersion: before.version,
      ),
    );
  }

  Future<void> remove() async {
    if (isClosed || state.isSubmitting || !state.canRemove) return;
    await _mutate(
      mutation: MembershipMutation.remove,
      successMessage: 'Đã loại thành viên khỏi tổ chức.',
      expectedStatus: MembershipStatus.removed,
      run: (before) => _members.remove(
        _membershipId,
        expectedVersion: before.version,
      ),
    );
  }

  /// Trả `true` chỉ khi đã gán vai trò và tải lại thành công.
  Future<bool> changeRole(String newRoleCode) async {
    if (isClosed || state.isSubmitting || !state.canChangeRole) return false;
    emit(
      state.copyWith(
        isSubmitting: true,
        activeMutation: MembershipMutation.changeRole,
        clearFailure: true,
        clearSuccessMessage: true,
      ),
    );
    try {
      final member = state.member!;
      await _members.assignRole(userId: member.userId, role: newRoleCode);
      final updated = await _fetchDetail();
      if (isClosed) return false;
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
      return true;
    } catch (error) {
      await _handleMutationError(error);
      return false;
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
    required Future<TenantMemberDetail> Function(TenantMemberDetail before) run,
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
      final updated = await run(before);
      if (isClosed) return;
      // Defense: never apply unexpected local mutation shape.
      if (updated.status != expectedStatus) {
        emit(
          state.copyWith(
            isSubmitting: false,
            clearMutation: true,
            failure: IamUiFailureMapper.from(
              const AppException(IamBlockedCodes.systemError),
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

  Future<TenantMemberDetail> _fetchDetail() {
    return _members.getMember(_membershipId);
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
