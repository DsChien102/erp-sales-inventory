import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/invitation_repository.dart';
import '../data/member_repository.dart';
import '../data/models/tenant_invitation.dart';
import '../data/models/tenant_member.dart';
import 'iam_load_status.dart';
import 'iam_role_label_mapper.dart';
import 'role_ui_model.dart';
import 'roles_state.dart';

final class RolesCubit extends Cubit<RolesState> {
  RolesCubit({
    required InvitationRepository invitations,
    required MemberRepository members,
  }) : _invitations = invitations,
       _members = members,
       super(const RolesState());

  final InvitationRepository _invitations;
  final MemberRepository _members;

  Future<void> load() async {
    emit(state.copyWith(status: IamLoadStatus.loading, clearFailure: true));
    try {
      final roles = await _invitations.listAssignableRoles();
      final members = await _activeMembers();
      if (isClosed) return;
      emit(
        state.copyWith(
          status: IamLoadStatus.success,
          roles: _catalog(roles: roles, members: members),
          clearFailure: true,
        ),
      );
    } catch (_) {
      if (isClosed) return;
      emit(
        state.copyWith(
          status: IamLoadStatus.failure,
          roles: const [],
          failure: rolesLoadErrorMessage,
        ),
      );
    }
  }

  Future<List<TenantMember>> _activeMembers() async {
    final members = <TenantMember>[];
    String? cursor;
    do {
      final page = await _members.listMembers(
        status: 'active',
        cursor: cursor,
        limit: 100,
      );
      members.addAll(page.items);
      cursor = page.nextCursor;
    } while (cursor != null && cursor.isNotEmpty);
    return members;
  }
}

List<RoleUiModel> buildRoleCatalog({
  required List<AssignableInvitationRole> roles,
  required List<TenantMember> members,
}) {
  return _catalog(roles: roles, members: members);
}

List<RoleUiModel> _catalog({
  required List<AssignableInvitationRole> roles,
  required List<TenantMember> members,
}) {
  final result = <RoleUiModel>[];
  for (final role in roles) {
    final code = IamRoleLabelMapper.toRoleCode(role.label);
    if (code.isEmpty) continue;
    final holders = members.where((member) {
      if (member.roleId == role.roleId) return true;
      final memberCode = IamRoleLabelMapper.toRoleCode(
        member.roleLabel.isNotEmpty ? member.roleLabel : member.roleId,
      );
      return memberCode == code;
    });
    final names = holders
        .map((member) {
          if (member.displayName.trim().isNotEmpty) return member.displayName.trim();
          if (member.email.trim().isNotEmpty) return member.email.trim();
          return member.userId;
        })
        .toList(growable: false);
    result.add(
      RoleUiModel(
        id: code,
        title: IamRoleLabelMapper.toDisplayLabel(code),
        description: IamRoleLabelMapper.description(code),
        isCurrent: names.isNotEmpty,
        memberNames: names,
      ),
    );
  }
  return result;
}
