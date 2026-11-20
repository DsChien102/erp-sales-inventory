import 'package:flutter_test/flutter_test.dart';
import '../../support/fake_iam_backend.dart';
import '../../support/iam_test_session.dart';
import 'package:erp/features/iam/presentation.dart';
import '../../support/iam_fixtures.dart';

final class FakeInvitationRoleOptionsSource implements InvitationRoleOptionsSource {
  FakeInvitationRoleOptionsSource(this.options);

  final List<InvitationRoleOption> options;
  int calls = 0;
  String? lastTenantId;

  @override
  Future<List<InvitationRoleOption>> load(String tenantId) async {
    calls += 1;
    lastTenantId = tenantId;
    return options;
  }
}

void main() {
  test('submit sends CreateInvitationCommand with exact roleId and key', () async {
    final module = FakeIamBackend(scenario: FakeIamScenario.inviteOk);
    final cubit = OrganizationInviteMemberCubit(
      session: testSessionController(),
      invitations: FakeInvitationRepository(module),
      roleOptionsSource: FakeInvitationRoleOptionsSource(
        const [InvitationRoleOption(roleId: 'role-staff', label: 'Nhân viên')],
      ),
      keyFactory: FakeIdempotencyKeyFactory(),
    );
    await cubit.loadRoleOptions();
    cubit.emailChanged('staff@example.com');
    cubit.roleSelected('role-staff');
    await cubit.submit();
    final command = module.commandsOf<CreateInvitationCommand>().single;
    expect(command.inviteeEmail, 'staff@example.com');
    expect(command.initialRoleId, 'role-staff');
    expect(command.idempotencyKey, 'create-invitation-test-idempotency-key');
    expect(cubit.state.createdInvitation, isNotNull);
    await cubit.close();
  });

  test('double submit issues one command', () async {
    final module = FakeIamBackend(scenario: FakeIamScenario.inviteOk);
    final cubit = OrganizationInviteMemberCubit(
      session: testSessionController(),
      invitations: FakeInvitationRepository(module),
      roleOptionsSource: FakeInvitationRoleOptionsSource(
        const [InvitationRoleOption(roleId: 'role-staff', label: 'Nhân viên')],
      ),
      keyFactory: FakeIdempotencyKeyFactory(),
    );
    await cubit.loadRoleOptions();
    cubit.emailChanged('staff@example.com');
    cubit.roleSelected('role-staff');
    await Future.wait([cubit.submit(), cubit.submit()]);
    expect(module.commandsOf<CreateInvitationCommand>(), hasLength(1));
    await cubit.close();
  });

  test('delivery failed is create success with warning', () async {
    final cubit = OrganizationInviteMemberCubit(
      session: testSessionController(),
      invitations: FakeInvitationRepository(
        FakeIamBackend(scenario: FakeIamScenario.inviteDeliveryFailed),
      ),
      roleOptionsSource: FakeInvitationRoleOptionsSource(
        const [InvitationRoleOption(roleId: 'role-staff', label: 'Nhân viên')],
      ),
      keyFactory: FakeIdempotencyKeyFactory(),
    );
    await cubit.loadRoleOptions();
    cubit.emailChanged('staff@example.com');
    cubit.roleSelected('role-staff');
    await cubit.submit();
    expect(cubit.state.createdInvitation, isNotNull);
    expect(cubit.state.deliveryWarning, isTrue);
    expect(cubit.state.failure, isNull);
    await cubit.close();
  });

  test('conflict keeps form without created invitation', () async {
    final cubit = OrganizationInviteMemberCubit(
      session: testSessionController(),
      invitations: FakeInvitationRepository(
        FakeIamBackend(
          scenario: FakeIamScenario.inviteDuplicateMembership,
        ),
      ),
      roleOptionsSource: FakeInvitationRoleOptionsSource(
        const [InvitationRoleOption(roleId: 'role-staff', label: 'Nhân viên')],
      ),
      keyFactory: FakeIdempotencyKeyFactory(),
    );
    await cubit.loadRoleOptions();
    cubit.emailChanged('staff@example.com');
    cubit.roleSelected('role-staff');
    await cubit.submit();
    expect(cubit.state.createdInvitation, isNull);
    expect(cubit.state.failure, isNull);
    expect(cubit.state.emailError, 'Thành viên đã tồn tại trong tổ chức.');
    expect(cubit.state.email.trim(), 'staff@example.com');
    await cubit.close();
  });
}
