import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:erp/core/iam/iam_codes.dart';

import '../../../core/session/session_controller.dart';
import '../data/invitation_repository.dart';
import 'iam_load_status.dart';
import 'iam_ui_failure.dart';
import 'iam_ui_failure_mapper.dart';
import 'idempotency_key_factory.dart';
import 'invitation_role_options.dart';
import 'organization_invite_member_state.dart';

final class OrganizationInviteMemberCubit
    extends Cubit<OrganizationInviteMemberState> {
  OrganizationInviteMemberCubit({
    required SessionController session,
    required InvitationRepository invitations,
    required InvitationRoleOptionsSource roleOptionsSource,
    required IdempotencyKeyFactory keyFactory,
  }) : _session = session,
       _invitations = invitations,
       _roleOptionsSource = roleOptionsSource,
       _keyFactory = keyFactory,
       super(const OrganizationInviteMemberState());

  final SessionController _session;
  final InvitationRepository _invitations;
  final InvitationRoleOptionsSource _roleOptionsSource;
  final IdempotencyKeyFactory _keyFactory;

  String? _idempotencyKey;
  String? _keyPayload;

  Future<void> loadRoleOptions() async {
    if (isClosed) return;
    emit(
      state.copyWith(
        status: IamLoadStatus.loading,
        clearFailure: true,
      ),
    );
    try {
      final tenantId = await _session.requireTenantId();
      final options = await _roleOptionsSource.load(tenantId);
      if (isClosed) return;
      final preferred = options.isEmpty ? null : options.first.roleId;
      emit(
        state.copyWith(
          status: IamLoadStatus.success,
          roleOptions: options,
          selectedRoleId: state.selectedRoleId ?? preferred,
          clearFailure: true,
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

  void emailChanged(String value) {
    if (isClosed) return;
    _invalidateKeyIfPayloadChanged(
      email: value.trim(),
      roleId: state.selectedRoleId,
    );
    emit(
      state.copyWith(
        email: value,
        clearFailure: true,
        clearCreated: true,
        deliveryWarning: false,
      ),
    );
  }

  void roleSelected(String roleId) {
    if (isClosed) return;
    _invalidateKeyIfPayloadChanged(
      email: state.email.trim(),
      roleId: roleId,
    );
    emit(
      state.copyWith(
        selectedRoleId: roleId,
        clearFailure: true,
        clearCreated: true,
        deliveryWarning: false,
      ),
    );
  }

  Future<void> submit() async {
    if (isClosed || state.isSubmitting) return;

    final email = state.email.trim();
    final roleId = state.selectedRoleId;
    if (email.isEmpty || !email.contains('@') || roleId == null) {
      emit(
        state.copyWith(
          failure: const IamUiFailure(
            code: IamBlockedCodes.validationError,
            message: 'Vui lòng nhập email và chọn vai trò.',
          ),
        ),
      );
      return;
    }

    emit(
      state.copyWith(
        isSubmitting: true,
        clearFailure: true,
        clearCreated: true,
        deliveryWarning: false,
      ),
    );

    try {
      final tenantId = await _session.requireTenantId();
      final payload = '$tenantId|$email|$roleId';
      final key = _ensureIdempotencyKey(payload);
      final created = await _invitations.create(
        email: email,
        roleCode: roleId,
        idempotencyKey: key,
      );
      if (isClosed) return;
      emit(
        state.copyWith(
          isSubmitting: false,
          createdInvitation: created,
          deliveryWarning: created.deliveryStatus == 'failed',
          clearFailure: true,
        ),
      );
    } catch (error) {
      if (isClosed) return;
      emit(
        state.copyWith(
          isSubmitting: false,
          failure: IamUiFailureMapper.from(error),
        ),
      );
    }
  }

  void clearResult() {
    if (isClosed) return;
    emit(
      state.copyWith(
        clearCreated: true,
        clearFailure: true,
        deliveryWarning: false,
      ),
    );
  }

  String _ensureIdempotencyKey(String payload) {
    if (_idempotencyKey != null && _keyPayload == payload) {
      return _idempotencyKey!;
    }
    _keyPayload = payload;
    _idempotencyKey = _keyFactory.next('create-invitation');
    return _idempotencyKey!;
  }

  void _invalidateKeyIfPayloadChanged({
    required String email,
    required String? roleId,
  }) {
    if (_keyPayload == null) return;
    // Payload includes tenantId; invalidate whenever email/role change.
    _idempotencyKey = null;
    _keyPayload = null;
  }
}
