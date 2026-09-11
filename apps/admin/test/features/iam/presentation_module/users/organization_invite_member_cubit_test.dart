import 'package:flutter_test/flutter_test.dart';
import 'package:vet45_iam_application/testing.dart';
import 'package:admin/features/iam/presentation.dart';
import 'package:admin/features/iam/testing.dart';
import 'package:vet45_shared_testing/shared_testing.dart';

final class FakeInvitationRoleOptionsSource
    implements InvitationRoleOptionsSource {
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
  test('submit sends CreateInvitationCommand with exact roleId and key',
      () async {
    final module = RecordingIamModule(
      FakeIamModule(scenario: FakeIamScenario.inviteOk),
    );
    final cubit = OrganizationInviteMemberCubit(
      iamModule: module,
      executionContext: FakeExecutionContext(tenantId: 'org-001'),
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
    final module = RecordingIamModule(
      FakeIamModule(scenario: FakeIamScenario.inviteOk),
    );
    final cubit = OrganizationInviteMemberCubit(
      iamModule: module,
      executionContext: FakeExecutionContext(tenantId: 'org-001'),
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
      iamModule: FakeIamModule(scenario: FakeIamScenario.inviteDeliveryFailed),
      executionContext: FakeExecutionContext(tenantId: 'org-001'),
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
      iamModule: FakeIamModule(
        scenario: FakeIamScenario.inviteDuplicateMembership,
      ),
      executionContext: FakeExecutionContext(tenantId: 'org-001'),
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
    expect(cubit.state.failure?.code, IamBlockedCodes.duplicateMembership);
    expect(cubit.state.email.trim(), 'staff@example.com');
    await cubit.close();
  });
}
