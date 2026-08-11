import 'package:erp/features/auth/presentation/bloc/invitation_acceptance_cubit.dart';
import 'package:erp/features/auth/presentation/bloc/invitation_acceptance_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vet45_iam_application/testing.dart';
import 'package:vet45_iam_domain/domain.dart';
import 'package:vet45_iam_presentation/presentation.dart';
import 'package:vet45_iam_presentation/testing.dart';
import 'package:vet45_shared_application/application.dart';

void main() {
  InvitationAcceptanceCubit buildCubit({
    required IIamModule module,
    IdempotencyKeyFactory? keyFactory,
  }) {
    return InvitationAcceptanceCubit(
      iamModule: module,
      keyFactory: keyFactory ?? FakeIdempotencyKeyFactory(),
    );
  }

  test('inspectExistingAccount goes to existing login without exposing token', () async {
    final cubit = buildCubit(
      module: FakeIamModule(scenario: FakeIamScenario.inspectExistingAccount),
    );
    await cubit.inspect('opaque-secret-token');
    expect(cubit.state.step, InvitationAcceptanceStep.existingAccountLogin);
    expect(cubit.state.inspection?.accountExists, isTrue);
    expect(cubit.state.tokenPresent, isTrue);
    expect(cubit.state.toString(), isNot(contains('opaque-secret-token')));
    await cubit.close();
  });

  test('inspectNewAccount goes to registration', () async {
    final cubit = buildCubit(
      module: FakeIamModule(scenario: FakeIamScenario.inspectNewAccount),
    );
    await cubit.inspect('token-new');
    expect(cubit.state.step, InvitationAcceptanceStep.newAccountRegistration);
    expect(cubit.state.inspection?.accountExists, isFalse);
    await cubit.close();
  });

  test('inspectInvalidNoLeak stays on entry with a failure to toast', () async {
    final cubit = buildCubit(
      module: FakeIamModule(scenario: FakeIamScenario.inspectInvalidNoLeak),
    );
    await cubit.inspect('bad-token');
    // Invalid code keeps the user on the entry screen so they can re-enter;
    // the view surfaces state.failure as a toast.
    expect(cubit.state.step, InvitationAcceptanceStep.tokenEntry);
    expect(cubit.state.failure?.code, IamBlockedCodes.invitationTokenInvalid);
    expect(cubit.state.tokenPresent, isFalse);
    expect(cubit.state.toString(), isNot(contains('bad-token')));
    await cubit.close();
  });

  test('acceptExistingAccountOk signs in then accepts in order', () async {
    final keys = FakeIdempotencyKeyFactory();
    final module = RecordingIamModule(
      FakeIamModule(scenario: FakeIamScenario.acceptExistingAccountOk),
    );
    final cubit = buildCubit(module: module, keyFactory: keys);
    await cubit.inspect('tok-1');
    await cubit.loginAndAccept(password: 'secret');

    expect(cubit.state.step, InvitationAcceptanceStep.accepted);
    expect(cubit.state.acceptedMembership?.status, MembershipStatus.active);
    expect(cubit.state.tokenPresent, isFalse);

    expect(module.commandsOf<SignInCommand>(), hasLength(1));
    expect(module.commandsOf<SignInCommand>().single.requireTenantContext, isFalse);
    expect(module.commandsOf<AcceptInvitationCommand>(), hasLength(1));
    final accept = module.commandsOf<AcceptInvitationCommand>().single;
    expect(accept.idempotencyKey, 'accept-invitation-test-idempotency-key');

    expect(module.queriesOf<InspectInvitationTokenQuery>(), isNotEmpty);
    expect(module.queriesOf<GetCurrentSessionQuery>(), isNotEmpty);
    expect(module.queriesOf<GetTenantContextQuery>(), isNotEmpty);

    // Order: SignIn before Accept
    final signInIndex = module.commands.indexWhere((c) => c is SignInCommand);
    final acceptIndex = module.commands.indexWhere((c) => c is AcceptInvitationCommand);
    expect(signInIndex, lessThan(acceptIndex));
    await cubit.close();
  });

  test('registerAndAcceptOk registers without email in profile', () async {
    final module = RecordingIamModule(
      FakeIamModule(scenario: FakeIamScenario.registerAndAcceptOk),
    );
    final cubit = buildCubit(module: module);
    await cubit.inspect('tok-new');
    await cubit.registerAndAccept(
      givenName: 'An',
      familyName: 'Nguyen',
      password: 'password-1',
    );
    expect(cubit.state.step, InvitationAcceptanceStep.accepted);
    final command = module.commandsOf<RegisterFromInvitationCommand>().single;
    expect(command.profile.givenName, 'An');
    expect(command.profile.familyName, 'Nguyen');
    expect(command.credentialProof, 'password-1');
    expect(cubit.state.toString(), isNot(contains('password-1')));
    expect(cubit.state.toString(), isNot(contains('tok-new')));
    await cubit.close();
  });

  test('registerIdentityConflict switches to existing login', () async {
    final cubit = buildCubit(
      module: FakeIamModule(scenario: FakeIamScenario.registerIdentityConflict),
    );
    await cubit.inspect('tok');
    await cubit.registerAndAccept(
      givenName: 'A',
      familyName: 'B',
      password: 'x',
    );
    expect(cubit.state.step, InvitationAcceptanceStep.existingAccountLogin);
    expect(
      cubit.state.failure?.code,
      IamBlockedCodes.platformUserAlreadyExists,
    );
    expect(cubit.state.tokenPresent, isTrue);
    await cubit.close();
  });

  test('acceptEmailMismatch keeps locked-email login step', () async {
    final cubit = buildCubit(
      module: FakeIamModule(scenario: FakeIamScenario.acceptEmailMismatch),
    );
    await cubit.inspect('tok');
    await cubit.loginAndAccept(password: 'secret');
    expect(cubit.state.step, InvitationAcceptanceStep.existingAccountLogin);
    expect(
      cubit.state.failure?.code,
      IamBlockedCodes.invitationEmailMismatch,
    );
    expect(cubit.state.tokenPresent, isTrue);
    await cubit.close();
  });

  test('acceptExpired stays on entry with an expired failure', () async {
    final cubit = buildCubit(
      module: FakeIamModule(scenario: FakeIamScenario.acceptExpired),
    );
    await cubit.inspect('tok');
    expect(cubit.state.step, InvitationAcceptanceStep.tokenEntry);
    expect(cubit.state.failure?.code, IamBlockedCodes.invitationExpired);
    expect(cubit.state.tokenPresent, isFalse);
    await cubit.close();
  });

  test('acceptRotatedToken stays on entry as invalid', () async {
    final cubit = buildCubit(
      module: FakeIamModule(scenario: FakeIamScenario.acceptRotatedToken),
    );
    await cubit.inspect('old-token');
    expect(cubit.state.step, InvitationAcceptanceStep.tokenEntry);
    expect(cubit.state.failure?.code, IamBlockedCodes.invitationTokenInvalid);
    await cubit.close();
  });

  test('acceptDeclined stays on entry as already used', () async {
    final cubit = buildCubit(
      module: FakeIamModule(scenario: FakeIamScenario.acceptDeclined),
    );
    await cubit.inspect('tok');
    expect(cubit.state.step, InvitationAcceptanceStep.tokenEntry);
    expect(cubit.state.failure?.code, IamBlockedCodes.invitationAlreadyUsed);
    await cubit.close();
  });

  test('acceptConcurrent blocks terminal after accept', () async {
    final cubit = buildCubit(
      module: FakeIamModule(scenario: FakeIamScenario.acceptConcurrent),
    );
    await cubit.inspect('tok');
    await cubit.loginAndAccept(password: 'secret');
    expect(cubit.state.step, InvitationAcceptanceStep.blocked);
    expect(cubit.state.failure?.code, IamBlockedCodes.invitationAlreadyUsed);
    expect(cubit.state.tokenPresent, isFalse);
    await cubit.close();
  });

  test('acceptTenantSuspended keeps token for retry later', () async {
    final cubit = buildCubit(
      module: FakeIamModule(scenario: FakeIamScenario.acceptTenantSuspended),
    );
    await cubit.inspect('tok');
    await cubit.loginAndAccept(password: 'secret');
    expect(cubit.state.step, InvitationAcceptanceStep.blocked);
    expect(cubit.state.failure?.code, IamBlockedCodes.tenantSuspended);
    expect(cubit.state.tokenPresent, isTrue);
    await cubit.close();
  });

  test('acceptRetryAfterIdentityCreated accepts after login', () async {
    final cubit = buildCubit(
      module: FakeIamModule(
        scenario: FakeIamScenario.acceptRetryAfterIdentityCreated,
      ),
    );
    await cubit.inspect('tok');
    await cubit.loginAndAccept(password: 'secret');
    expect(cubit.state.step, InvitationAcceptanceStep.accepted);
    expect(cubit.state.acceptedMembership?.status, MembershipStatus.active);
    await cubit.close();
  });

  test('declineOk clears token; decline retry reuses stable key', () async {
    final module = RecordingIamModule(
      FakeIamModule(scenario: FakeIamScenario.declineOk),
    );
    final cubit = buildCubit(
      module: module,
      keyFactory: FakeIdempotencyKeyFactory(),
    );
    await cubit.inspect('tok');
    await cubit.decline();
    expect(cubit.state.step, InvitationAcceptanceStep.declined);
    expect(cubit.state.tokenPresent, isFalse);
    expect(
      module.commandsOf<DeclineInvitationCommand>().single.idempotencyKey,
      'decline-invitation-test-idempotency-key',
    );
    await cubit.close();

    final keys = FakeIdempotencyKeyFactory();
    final scriptedModule = RecordingIamModule(_FailThenSucceedDeclineModule());
    final scriptedCubit = buildCubit(module: scriptedModule, keyFactory: keys);
    await scriptedCubit.inspect('tok');
    await scriptedCubit.decline();
    expect(
      scriptedCubit.state.step,
      InvitationAcceptanceStep.existingAccountLogin,
    );
    expect(
      scriptedCubit.state.failure?.code,
      IamBlockedCodes.idempotencyConflict,
    );
    expect(keys.calls, 1);
    await scriptedCubit.decline();
    expect(scriptedCubit.state.step, InvitationAcceptanceStep.declined);
    expect(keys.calls, 1);
    final cmds = scriptedModule.commandsOf<DeclineInvitationCommand>().toList();
    expect(cmds, hasLength(2));
    expect(cmds[0].idempotencyKey, cmds[1].idempotencyKey);
    await scriptedCubit.close();
  });

  test('reset clears public state and private token', () async {
    final cubit = buildCubit(
      module: FakeIamModule(scenario: FakeIamScenario.inspectExistingAccount),
    );
    await cubit.inspect('opaque');
    cubit.reset();
    expect(cubit.state.step, InvitationAcceptanceStep.tokenEntry);
    expect(cubit.state.tokenPresent, isFalse);
    expect(cubit.state.inspection, isNull);
    await cubit.close();
  });
}

final class _FailThenSucceedDeclineModule implements IIamModule {
  bool _failedOnce = false;

  @override
  Future<TResult> executeCommandAsync<TResult>(ICommand<TResult> command) {
    if (command is DeclineInvitationCommand) {
      if (!_failedOnce) {
        _failedOnce = true;
        throw const IamBlockedException(IamBlockedCodes.idempotencyConflict);
      }
      return Future.value(
        InvitationDetailDto(
              invitationId: 'inv-1',
              inviteeEmail: 'invitee@example.com',
              initialRoleId: 'role-staff',
              initialRoleLabel: 'Staff',
              status: 'declined',
              expiresAt: DateTime.utc(2026, 8, 5),
              deliveryStatus: 'sent',
              deliveryCorrelationId: 'corr',
              version: 2,
              createdAt: DateTime.utc(2026, 7, 29),
              createdBy: 'lan-le',
              declinedAt: DateTime.utc(2026, 7, 30),
            )
            as TResult,
      );
    }
    throw UnsupportedError(command.runtimeType.toString());
  }

  @override
  Future<TResult> executeQueryAsync<TResult>(IQuery<TResult> query) {
    if (query is InspectInvitationTokenQuery) {
      return Future.value(
        InvitationTokenInspectionDto(
              tenantId: 'org-001',
              tenantName: 'Org',
              inviteeEmail: 'invitee@example.com',
              initialRoleId: 'role-staff',
              initialRoleLabel: 'Staff',
              expiresAt: DateTime.utc(2026, 8, 5),
              accountExists: true,
            )
            as TResult,
      );
    }
    throw UnsupportedError(query.runtimeType.toString());
  }
}
