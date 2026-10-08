import 'package:flutter_test/flutter_test.dart';
import 'package:vet45_iam_application/testing.dart';
import 'package:vet45_iam_domain/domain.dart';
import 'package:erp/features/iam/presentation.dart';
import 'package:erp/features/iam/testing.dart';
import '../../support/iam_module_repositories.dart';

void main() {
  OrganizationMemberDetailCubit buildCubit({
    required IIamModule module,
    String membershipId = 'mem-staff-1',
  }) {
    return OrganizationMemberDetailCubit(
      membershipId: membershipId,
      members: IamModuleMemberRepository(module),
    );
  }

  test('load uses GetTenantMemberQuery by membershipId', () async {
    final module = RecordingIamModule(
      FakeIamModule(scenario: FakeIamScenario.memberDetailOk),
    );
    final cubit = buildCubit(module: module);
    await cubit.load();
    final query = module.queriesOf<GetTenantMemberQuery>().single;
    expect(query.membershipId, 'mem-staff-1');
    expect(cubit.state.member?.status, MembershipStatus.active);
    expect(cubit.state.canDeactivate, isTrue);
    expect(cubit.state.canRemove, isTrue);
    await cubit.close();
  });

  test('deactivate uses displayed version', () async {
    final module = RecordingIamModule(
      FakeIamModule(scenario: FakeIamScenario.memberDeactivateOk),
    );
    final cubit = buildCubit(module: module);
    await cubit.load();
    final before = cubit.state.member!;
    await cubit.deactivate();
    final command = module.commandsOf<DeactivateMembershipCommand>().single;
    expect(command.expectedVersion, before.version);
    expect(cubit.state.member!.status, MembershipStatus.inactive);
    expect(cubit.state.canReactivate, isTrue);
    await cubit.close();
  });

  test('reactivate restores active', () async {
    final cubit = buildCubit(
      module: FakeIamModule(scenario: FakeIamScenario.memberReactivateOk),
      membershipId: 'mem-inactive-1',
    );
    await cubit.load();
    expect(cubit.state.member!.status, MembershipStatus.inactive);
    await cubit.reactivate();
    expect(cubit.state.member!.status, MembershipStatus.active);
    await cubit.close();
  });

  test('remove sets removed and hides actions', () async {
    final cubit = buildCubit(
      module: FakeIamModule(scenario: FakeIamScenario.memberRemoveOk),
    );
    await cubit.load();
    await cubit.remove();
    expect(cubit.state.member!.status, MembershipStatus.removed);
    expect(cubit.state.hasLifecycleActions, isFalse);
    expect(cubit.state.isReadOnly, isTrue);
    await cubit.close();
  });

  test('sole owner hides destructive actions', () async {
    final cubit = buildCubit(
      module: FakeIamModule(scenario: FakeIamScenario.memberDetailOk),
      membershipId: 'mem-owner-1',
    );
    await cubit.load();
    expect(cubit.state.member!.isSoleOwner, isTrue);
    expect(cubit.state.canDeactivate, isFalse);
    expect(cubit.state.canRemove, isFalse);
    expect(cubit.state.hasLifecycleActions, isFalse);
    await cubit.close();
  });

  test('LAST_OWNER_PROTECTED does not local-mutate', () async {
    final module = RecordingIamModule(
      FakeIamModule(scenario: FakeIamScenario.memberLastOwnerProtected),
    );
    final cubit = buildCubit(module: module);
    await cubit.load();
    await cubit.deactivate();
    expect(cubit.state.failure?.code, IamBlockedCodes.lastOwnerProtected);
    expect(cubit.state.member!.status, MembershipStatus.active);
    expect(module.commandsOf<DeactivateMembershipCommand>(), hasLength(1));
    await cubit.close();
  });

  test('STATE_CHANGED reloads without applying local mutation', () async {
    final module = RecordingIamModule(
      FakeIamModule(scenario: FakeIamScenario.memberStateChanged),
    );
    final cubit = buildCubit(module: module);
    await cubit.load();
    final versionBefore = cubit.state.member!.version;
    await cubit.deactivate();
    expect(cubit.state.failure?.code, IamBlockedCodes.stateChanged);
    expect(cubit.state.member!.status, MembershipStatus.active);
    expect(cubit.state.member!.version, versionBefore);
    expect(module.queriesOf<GetTenantMemberQuery>().length, greaterThan(1));
    await cubit.close();
  });

  test('MEMBERSHIP_REMOVED reloads detail and keeps failure', () async {
    final module = RecordingIamModule(
      FakeIamModule(scenario: FakeIamScenario.memberRemovedTerminal),
    );
    final cubit = buildCubit(
      module: module,
      membershipId: 'mem-inactive-1',
    );
    await cubit.load();
    expect(cubit.state.member!.status, MembershipStatus.inactive);
    await cubit.reactivate();
    expect(cubit.state.failure?.code, IamBlockedCodes.membershipRemoved);
    expect(cubit.state.member!.status, MembershipStatus.inactive);
    expect(module.queriesOf<GetTenantMemberQuery>().length, greaterThan(1));
    await cubit.close();
  });

  test('forbidden keeps current member without mutation', () async {
    final cubit = buildCubit(
      module: FakeIamModule(scenario: FakeIamScenario.memberForbidden),
    );
    await cubit.load();
    await cubit.remove();
    expect(cubit.state.failure?.code, IamBlockedCodes.permissionDenied);
    expect(cubit.state.member!.status, MembershipStatus.active);
    await cubit.close();
  });
}
