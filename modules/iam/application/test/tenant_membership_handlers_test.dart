import 'package:test/test.dart';
import 'package:vet45_iam_application/application.dart';
import 'package:vet45_iam_domain/domain.dart';

class _RecordingAccessGateway implements IIamAccessGateway {
  String? listedTenantId;
  String? assignedRole;
  String? assignedUserId;
  String? switchedTenantId;

  @override
  Future<PrincipalAccessDto?> getSessionContext({String? tenantId}) async => PrincipalAccessDto(
    userId: 'user-1',
    tenantId: tenantId ?? 'tenant-1',
    role: 'owner',
    permissions: const [IamPermissions.membersRead],
  );

  @override
  Future<bool> hasPermission({
    required String tenantId,
    required String permission,
  }) async => true;

  @override
  Future<bool> isMember(String tenantId) async => true;

  @override
  Future<CursorPageDto<TenantMemberDto>> listTenantMembers({
    required String tenantId,
    String? search,
    String? status,
    String? cursor,
    int limit = 20,
  }) async {
    listedTenantId = tenantId;
    return CursorPageDto<TenantMemberDto>(
      items: [
        TenantMemberDto(
          membershipId: 'm-1',
          userId: 'user-1',
          displayName: 'User One',
          email: 'user1@example.com',
          roleId: 'role-owner',
          roleLabel: 'owner',
          isOwner: true,
          status: 'active',
          joinedAt: DateTime.utc(2026, 1, 1),
          version: 1,
        ),
      ],
    );
  }

  @override
  Future<List<TenantMembershipDto>> listUserTenants() async => const [];

  @override
  Future<List<AccessibleTenantDto>> listAccessibleTenants() async => const [];

  @override
  Future<TenantContextDto> switchTenantContext({
    required String targetTenantId,
  }) async => throw UnimplementedError('S2 BE');

  @override
  Future<TenantContextDto> getValidatedTenantContext({
    String? sessionTenantId,
  }) async => throw UnimplementedError('S3 BE');

  @override
  Future<void> assignMemberRole({
    required String tenantId,
    required String userId,
    required String role,
  }) async {
    assignedUserId = userId;
    assignedRole = role;
  }
}

class _RecordingSessionPort implements IIamSessionPort {
  String? establishedTenantId;

  @override
  SessionDto get snapshot => const SessionDto(isAuthenticated: true);

  @override
  Future<void> clear() async {}

  @override
  Future<void> establishAfterSignIn({
    String? tenantId,
    bool requireTenantContext = true,
  }) async {
    establishedTenantId = tenantId;
  }

  @override
  Future<void> restoreFromPersistedAuth({
    bool requireTenantContext = true,
  }) async {}
}

void main() {
  test('ListTenantMembersQueryHandler delegates to gateway', () async {
    final gateway = _RecordingAccessGateway();
    final handler = ListTenantMembersQueryHandler(accessGateway: gateway);

    final page = await handler.handle(
      ListTenantMembersQuery(tenantId: 'tenant-42'),
    );

    expect(gateway.listedTenantId, 'tenant-42');
    expect(page.items, hasLength(1));
    expect(page.items.first.roleLabel, 'owner');
  });

  test('AssignMemberRoleCommandHandler delegates to gateway', () async {
    final gateway = _RecordingAccessGateway();
    final handler = AssignMemberRoleCommandHandler(accessGateway: gateway);

    await handler.handle(
      AssignMemberRoleCommand(
        tenantId: 'tenant-1',
        userId: 'user-2',
        role: 'staff',
      ),
    );

    expect(gateway.assignedUserId, 'user-2');
    expect(gateway.assignedRole, 'staff');
  });

  test('SwitchActiveTenantCommandHandler switches session tenant', () async {
    final sessionPort = _RecordingSessionPort();
    final handler = SwitchActiveTenantCommandHandler(sessionPort: sessionPort);

    await handler.handle(
      SwitchActiveTenantCommand(tenantId: 'tenant-99'),
    );

    expect(sessionPort.establishedTenantId, 'tenant-99');
  });
}
