import 'package:erp/core/supabase/supabase_rpc.dart';
import 'package:erp/features/iam/data/invitation_repository.dart';
import 'package:erp/features/iam/data/member_repository.dart';
import 'package:erp/features/iam/data/models/cursor_page.dart';
import 'package:erp/features/iam/data/models/tenant_member.dart';
import 'package:erp/features/iam/logic/organization_users_cubit.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase/supabase.dart';

void main() {
  test('Thủ kho keeps warehouse members and drops a label that only contains kho', () async {
    final members = _Members([
      _member(id: 'w', name: 'Thủ kho An', roleLabel: 'Thủ kho'),
      _member(id: 's', name: 'Nhân viên kho', roleLabel: 'Nhân viên kho'),
      _member(id: 'a', name: 'Kế toán Bình', roleLabel: 'Kế toán'),
    ]);
    final cubit = OrganizationUsersCubit(
      members: members,
      invitations: _Invitations(),
      searchDebounce: Duration.zero,
    );

    await cubit.applyMemberCriteria(role: 'Thủ kho');

    expect(cubit.state.members.map((member) => member.name), ['Thủ kho An']);
    expect(cubit.state.members.single.roleCode, 'warehouse');
    await cubit.close();
  });
}

TenantMember _member({
  required String id,
  required String name,
  required String roleLabel,
}) {
  return TenantMember(
    membershipId: id,
    userId: id,
    displayName: name,
    email: '$id@example.com',
    roleId: id,
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

final class _Members extends MemberRepository {
  _Members(this.items) : super(rpc: _rpc, tenantId: () async => 'org-001');

  final List<TenantMember> items;

  @override
  Future<CursorPage<TenantMember>> listMembers({
    String? search,
    String? status,
    String? cursor,
    int limit = 20,
  }) async {
    return CursorPage(items: items);
  }
}

final class _Invitations extends InvitationRepository {
  _Invitations() : super(rpc: _rpc, tenantId: () async => 'org-001');
}
