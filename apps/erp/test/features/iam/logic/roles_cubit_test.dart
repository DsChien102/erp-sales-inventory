import 'package:erp/core/errors/app_exception.dart';
import 'package:erp/core/supabase/supabase_rpc.dart';
import 'package:erp/features/iam/data/invitation_repository.dart';
import 'package:erp/features/iam/data/member_repository.dart';
import 'package:erp/features/iam/data/models/cursor_page.dart';
import 'package:erp/features/iam/data/models/tenant_invitation.dart';
import 'package:erp/features/iam/data/models/tenant_member.dart';
import 'package:erp/features/iam/logic/iam_load_status.dart';
import 'package:erp/features/iam/logic/roles_cubit.dart';
import 'package:erp/features/iam/logic/roles_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase/supabase.dart';

void main() {
  test('counts active members by role id and walks the cursor', () async {
    final invitations = _ScriptedInvitations(
      roles: const [
        AssignableInvitationRole(roleId: 'role-staff', label: 'Nhân viên bán hàng'),
        AssignableInvitationRole(roleId: 'role-warehouse', label: 'Thủ kho'),
      ],
    );
    final members = _ScriptedMembers([
      CursorPage(
        items: [
          _member(id: 'm1', name: 'An', roleId: 'role-staff', roleLabel: 'Nhân viên bán hàng'),
          _member(id: 'm2', name: 'Bình', roleId: 'other', roleLabel: 'Thủ kho'),
        ],
        nextCursor: 'page-2',
      ),
      CursorPage(
        items: [
          _member(id: 'm3', name: 'Chi', roleId: 'role-staff', roleLabel: ''),
        ],
      ),
    ]);
    final cubit = RolesCubit(invitations: invitations, members: members);

    await cubit.load();

    expect(cubit.state.status, IamLoadStatus.success);
    expect(members.statuses, ['active', 'active']);
    expect(members.cursors, [null, 'page-2']);
    final staff = cubit.state.roles.singleWhere((role) => role.id == 'staff');
    final warehouse = cubit.state.roles.singleWhere((role) => role.id == 'warehouse');
    expect(staff.memberNames, ['An', 'Chi']);
    expect(staff.isCurrent, isTrue);
    expect(warehouse.memberNames, ['Bình']);
    expect(staff.description, 'Bán hàng và chăm sóc khách hàng');
    await cubit.close();
  });

  test('a load failure uses the US-07.1 message', () async {
    final cubit = RolesCubit(
      invitations: _ScriptedInvitations(error: const AppException('down')),
      members: _ScriptedMembers(const []),
    );

    await cubit.load();

    expect(cubit.state.status, IamLoadStatus.failure);
    expect(cubit.state.failure, rolesLoadErrorMessage);
    expect(cubit.state.roles, isEmpty);
    await cubit.close();
  });
}

TenantMember _member({
  required String id,
  required String name,
  required String roleId,
  required String roleLabel,
}) {
  return TenantMember(
    membershipId: id,
    userId: id,
    displayName: name,
    email: '$id@example.com',
    roleId: roleId,
    roleLabel: roleLabel,
    isOwner: false,
    status: 'active',
    joinedAt: DateTime.utc(2026, 1, 1),
    version: 1,
  );
}

SupabaseRpc get _rpc => SupabaseRpc(
  SupabaseClient(
    'http://127.0.0.1',
    'anon',
    authOptions: const AuthClientOptions(autoRefreshToken: false),
  ),
);

final class _ScriptedInvitations extends InvitationRepository {
  _ScriptedInvitations({this.roles = const [], this.error})
    : super(rpc: _rpc, tenantId: () async => 'org-001');

  final List<AssignableInvitationRole> roles;
  final Object? error;

  @override
  Future<List<AssignableInvitationRole>> listAssignableRoles() async {
    final failure = error;
    if (failure != null) throw failure;
    return roles;
  }
}

final class _ScriptedMembers extends MemberRepository {
  _ScriptedMembers(this.pages) : super(rpc: _rpc, tenantId: () async => 'org-001');

  final List<CursorPage<TenantMember>> pages;
  final statuses = <String?>[];
  final cursors = <String?>[];

  @override
  Future<CursorPage<TenantMember>> listMembers({
    String? search,
    String? status,
    String? cursor,
    int limit = 20,
  }) async {
    statuses.add(status);
    cursors.add(cursor);
    final index = cursors.length - 1;
    return pages[index];
  }
}
