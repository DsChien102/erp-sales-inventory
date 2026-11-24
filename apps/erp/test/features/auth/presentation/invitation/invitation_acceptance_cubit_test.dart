import 'package:erp/core/errors/app_exception.dart';
import 'package:erp/features/auth/logic/invitation_acceptance_cubit.dart';
import 'package:erp/features/auth/logic/invitation_acceptance_state.dart';
import '../../../iam/support/iam_fixtures.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:erp/core/iam/iam_codes.dart';
import 'package:erp/features/iam/data/models/tenant_member.dart';
import '../../../iam/support/fake_iam_backend.dart';

import '../../support/scripted_auth.dart';
import '../../support/scripted_invitations.dart';

void main() {
  InvitationAcceptanceCubit buildCubit({
    required ScriptedInvitations invitations,
    ScriptedAuthRepository? auth,
    FakeIdempotencyKeyFactory? keys,
    List<String>? log,
  }) {
    return InvitationAcceptanceCubit(
      invitations: invitations,
      auth: auth ?? ScriptedAuthRepository(log: log),
      session: loginSession(email: 'invitee@example.com', log: log),
      nextKey: (keys ?? FakeIdempotencyKeyFactory()).next,
    );
  }

  test('inspectExistingAccount goes to existing login without exposing token', () async {
    final cubit = buildCubit(
      invitations: ScriptedInvitations(scenario: FakeIamScenario.inspectExistingAccount),
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
      invitations: ScriptedInvitations(scenario: FakeIamScenario.inspectNewAccount),
    );
    await cubit.inspect('token-new');
    expect(cubit.state.step, InvitationAcceptanceStep.newAccountRegistration);
    expect(cubit.state.inspection?.accountExists, isFalse);
    await cubit.close();
  });

  test('inspectInvalidNoLeak stays on entry with a failure to toast', () async {
    final cubit = buildCubit(
      invitations: ScriptedInvitations(scenario: FakeIamScenario.inspectInvalidNoLeak),
    );
    await cubit.inspect('bad-token');
    expect(cubit.state.step, InvitationAcceptanceStep.tokenEntry);
    expect(cubit.state.failure?.code, IamBlockedCodes.invitationTokenInvalid);
    expect(cubit.state.tokenPresent, isFalse);
    expect(cubit.state.toString(), isNot(contains('bad-token')));
    await cubit.close();
  });

  test('loginAndAccept signs in, accepts, then signs out without tenant bootstrap', () async {
    final log = <String>[];
    final keys = FakeIdempotencyKeyFactory();
    final invitations = ScriptedInvitations(
      scenario: FakeIamScenario.acceptExistingAccountOk,
      log: log,
    );
    final cubit = buildCubit(invitations: invitations, keys: keys, log: log);
    await cubit.inspect('tok-1');
    await cubit.loginAndAccept(password: 'secret');

    expect(cubit.state.step, InvitationAcceptanceStep.accepted);
    expect(cubit.state.acceptedMembership?.status, MembershipStatus.active);
    expect(cubit.state.tokenPresent, isFalse);
    expect(invitations.accepts, ['accept-invitation-test-idempotency-key']);
    expect(log, ['inspect', 'signIn', 'accept', 'signOut']);
    await cubit.close();
  });

  test('acceptExistingAccount accepts then signs out before completion', () async {
    final log = <String>[];
    final keys = FakeIdempotencyKeyFactory();
    final invitations = ScriptedInvitations(
      scenario: FakeIamScenario.inspectExistingAccount,
      log: log,
    );
    final cubit = buildCubit(invitations: invitations, keys: keys, log: log);
    await cubit.inspect('tok-1');
    expect(cubit.state.step, InvitationAcceptanceStep.existingAccountLogin);

    await cubit.acceptExistingAccount();

    expect(cubit.state.step, InvitationAcceptanceStep.accepted);
    expect(cubit.state.acceptedMembership?.status, MembershipStatus.active);
    expect(cubit.state.tokenPresent, isFalse);
    expect(cubit.state.failure, isNull);
    expect(log.where((event) => event == 'signIn'), isEmpty);
    expect(invitations.accepts, ['accept-invitation-test-idempotency-key']);
    expect(log.indexOf('accept'), lessThan(log.indexOf('signOut')));
    await cubit.close();
  });

  test('acceptExistingAccount error falls back to existingAccountLogin with failure', () async {
    final invitations = ScriptedInvitations(
      scenario: FakeIamScenario.inspectExistingAccount,
      acceptError: const AppException(IamBlockedCodes.idempotencyConflict),
    );
    final cubit = buildCubit(invitations: invitations);
    await cubit.inspect('tok-1');
    await cubit.acceptExistingAccount();

    expect(cubit.state.step, InvitationAcceptanceStep.existingAccountLogin);
    expect(cubit.state.failure?.code, IamBlockedCodes.idempotencyConflict);
    expect(cubit.state.tokenPresent, isTrue);
    await cubit.close();
  });

  test('acceptExistingAccount terminal error transitions to blocked', () async {
    final invitations = ScriptedInvitations(
      scenario: FakeIamScenario.inspectExistingAccount,
      acceptError: const AppException(IamBlockedCodes.invitationAlreadyUsed),
    );
    final cubit = buildCubit(invitations: invitations);
    await cubit.inspect('tok-1');
    await cubit.acceptExistingAccount();

    expect(cubit.state.step, InvitationAcceptanceStep.blocked);
    expect(cubit.state.failure?.code, IamBlockedCodes.invitationAlreadyUsed);
    expect(cubit.state.tokenPresent, isFalse);
    await cubit.close();
  });

  test('registerAndAccept creates the account and accepts in one call, without verification', () async {
    final log = <String>[];
    final keys = FakeIdempotencyKeyFactory();
    final invitations = ScriptedInvitations(
      scenario: FakeIamScenario.registerAndAcceptOk,
      log: log,
    );
    final cubit = buildCubit(invitations: invitations, keys: keys, log: log);
    final steps = <InvitationAcceptanceStep>[];
    final subscription = cubit.stream.listen((state) => steps.add(state.step));

    await cubit.inspect('tok-new');
    await cubit.registerAndAccept(
      givenName: 'An',
      familyName: 'Nguyen',
      phone: ' 0900000000 ',
      password: 'password-1!',
    );
    await Future<void>.delayed(Duration.zero);
    await subscription.cancel();

    expect(cubit.state.step, InvitationAcceptanceStep.accepted);
    expect(cubit.state.acceptedMembership?.status, MembershipStatus.active);
    expect(cubit.state.registrationResult?.userId, 'invitee-user');
    expect(cubit.state.tokenPresent, isFalse);
    expect(cubit.state.failure, isNull);
    expect(steps, [
      InvitationAcceptanceStep.inspecting,
      InvitationAcceptanceStep.newAccountRegistration,
      InvitationAcceptanceStep.submitting,
      InvitationAcceptanceStep.accepted,
    ]);
    final call = invitations.registers.single;
    expect(call.givenName, 'An');
    expect(call.familyName, 'Nguyen');
    expect(call.phone, '0900000000');
    expect(call.password, 'password-1!');
    expect(call.key, 'register-from-invitation-test-idempotency-key');
    expect(log, ['inspect', 'inspect', 'registerAndAccept']);
    expect(log, isNot(contains('signUp')));
    expect(log, isNot(contains('signOut')));
    expect(cubit.state.toString(), isNot(contains('password-1!')));
    expect(cubit.state.toString(), isNot(contains('tok-new')));
    await cubit.close();
  });

  test('registerAndAccept rejects invalid input without calling the server', () async {
    final invitations = ScriptedInvitations(scenario: FakeIamScenario.registerAndAcceptOk);
    final cubit = buildCubit(invitations: invitations);
    await cubit.inspect('tok-new');
    await cubit.registerAndAccept(
      givenName: 'An',
      familyName: 'Nguyen',
      password: 'short',
    );

    expect(cubit.state.step, InvitationAcceptanceStep.newAccountRegistration);
    expect(cubit.state.failure?.code, AppErrorCode.validation);
    expect(invitations.registers, isEmpty);
    await cubit.close();
  });

  test('registerIdentityConflict switches to existing login', () async {
    final cubit = buildCubit(
      invitations: ScriptedInvitations(
        scenario: FakeIamScenario.registerIdentityConflict,
        registerError: const AppException('PLATFORM_USER_ALREADY_EXISTS'),
      ),
    );
    await cubit.inspect('tok');
    await cubit.registerAndAccept(
      givenName: 'A',
      familyName: 'B',
      password: 'password-1!',
    );
    expect(cubit.state.step, InvitationAcceptanceStep.existingAccountLogin);
    expect(cubit.state.failure?.code, IamBlockedCodes.platformUserAlreadyExists);
    expect(cubit.state.tokenPresent, isTrue);
    await cubit.close();
  });

  test('registerAndAccept with an expired invitation blocks with the expired message', () async {
    final cubit = buildCubit(
      invitations: ScriptedInvitations(
        scenario: FakeIamScenario.registerAndAcceptOk,
        registerError: const AppException(IamBlockedCodes.invitationExpired),
      ),
    );
    await cubit.inspect('tok');
    await cubit.registerAndAccept(
      givenName: 'A',
      familyName: 'B',
      password: 'password-1!',
    );
    expect(cubit.state.step, InvitationAcceptanceStep.blocked);
    expect(cubit.state.failure?.code, IamBlockedCodes.invitationExpired);
    expect(cubit.state.tokenPresent, isFalse);
    await cubit.close();
  });

  test('registerAndAccept network failure stays on registration and retries with the same key', () async {
    final keys = FakeIdempotencyKeyFactory();
    final invitations = ScriptedInvitations(
      scenario: FakeIamScenario.registerAndAcceptOk,
      registerError: const AppException(AppErrorCode.network),
    );
    final cubit = buildCubit(invitations: invitations, keys: keys);
    await cubit.inspect('tok');
    await cubit.registerAndAccept(
      givenName: 'A',
      familyName: 'B',
      password: 'password-1!',
    );

    expect(cubit.state.step, InvitationAcceptanceStep.newAccountRegistration);
    expect(cubit.state.failure?.code, IamBlockedCodes.systemError);
    expect(cubit.state.failure?.retryable, isTrue);
    expect(cubit.state.tokenPresent, isTrue);

    await cubit.registerAndAccept(
      givenName: 'A',
      familyName: 'B',
      password: 'password-1!',
    );
    expect(invitations.registers, hasLength(2));
    expect(invitations.registers[0].key, invitations.registers[1].key);
    expect(keys.calls, 1);
    await cubit.close();
  });

  test('acceptEmailMismatch keeps locked-email login step', () async {
    final cubit = buildCubit(
      invitations: ScriptedInvitations(scenario: FakeIamScenario.acceptEmailMismatch),
    );
    await cubit.inspect('tok');
    await cubit.loginAndAccept(password: 'secret');
    expect(cubit.state.step, InvitationAcceptanceStep.existingAccountLogin);
    expect(cubit.state.failure?.code, IamBlockedCodes.invitationEmailMismatch);
    expect(cubit.state.tokenPresent, isTrue);
    await cubit.close();
  });

  test('acceptExpired stays on entry with an expired failure', () async {
    final cubit = buildCubit(
      invitations: ScriptedInvitations(scenario: FakeIamScenario.acceptExpired),
    );
    await cubit.inspect('tok');
    expect(cubit.state.step, InvitationAcceptanceStep.tokenEntry);
    expect(cubit.state.failure?.code, IamBlockedCodes.invitationExpired);
    expect(cubit.state.tokenPresent, isFalse);
    await cubit.close();
  });

  test('acceptRotatedToken stays on entry as invalid', () async {
    final cubit = buildCubit(
      invitations: ScriptedInvitations(scenario: FakeIamScenario.acceptRotatedToken),
    );
    await cubit.inspect('old-token');
    expect(cubit.state.step, InvitationAcceptanceStep.tokenEntry);
    expect(cubit.state.failure?.code, IamBlockedCodes.invitationTokenInvalid);
    await cubit.close();
  });

  test('acceptDeclined stays on entry as already used', () async {
    final cubit = buildCubit(
      invitations: ScriptedInvitations(scenario: FakeIamScenario.acceptDeclined),
    );
    await cubit.inspect('tok');
    expect(cubit.state.step, InvitationAcceptanceStep.tokenEntry);
    expect(cubit.state.failure?.code, IamBlockedCodes.invitationAlreadyUsed);
    await cubit.close();
  });

  test('acceptConcurrent blocks terminal after accept', () async {
    final cubit = buildCubit(
      invitations: ScriptedInvitations(scenario: FakeIamScenario.acceptConcurrent),
    );
    await cubit.inspect('tok');
    await cubit.loginAndAccept(password: 'secret');
    expect(cubit.state.step, InvitationAcceptanceStep.blocked);
    expect(cubit.state.failure?.code, IamBlockedCodes.invitationAlreadyUsed);
    expect(cubit.state.tokenPresent, isFalse);
    await cubit.close();
  });

  test('acceptRetryAfterIdentityCreated accepts after login', () async {
    final cubit = buildCubit(
      invitations: ScriptedInvitations(
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
    final keys = FakeIdempotencyKeyFactory();
    final invitations = ScriptedInvitations(scenario: FakeIamScenario.declineOk);
    final cubit = buildCubit(invitations: invitations, keys: keys);
    await cubit.inspect('tok');
    await cubit.decline();
    expect(cubit.state.step, InvitationAcceptanceStep.declined);
    expect(cubit.state.tokenPresent, isFalse);
    expect(invitations.declines, ['decline-invitation-test-idempotency-key']);
    await cubit.close();

    final retryKeys = FakeIdempotencyKeyFactory();
    final retry = ScriptedInvitations(
      scenario: FakeIamScenario.inspectExistingAccount,
      declineFailures: 1,
    );
    final retryCubit = buildCubit(invitations: retry, keys: retryKeys);
    await retryCubit.inspect('tok');
    await retryCubit.decline();
    expect(retryCubit.state.step, InvitationAcceptanceStep.existingAccountLogin);
    expect(retryCubit.state.failure?.code, IamBlockedCodes.idempotencyConflict);
    expect(retryKeys.calls, 1);
    await retryCubit.decline();
    expect(retryCubit.state.step, InvitationAcceptanceStep.declined);
    expect(retryKeys.calls, 1);
    expect(retry.declines, hasLength(2));
    expect(retry.declines[0], retry.declines[1]);
    await retryCubit.close();
  });

  test('reset clears public state and private token', () async {
    final cubit = buildCubit(
      invitations: ScriptedInvitations(scenario: FakeIamScenario.inspectExistingAccount),
    );
    await cubit.inspect('opaque');
    cubit.reset();
    expect(cubit.state.step, InvitationAcceptanceStep.tokenEntry);
    expect(cubit.state.tokenPresent, isFalse);
    expect(cubit.state.inspection, isNull);
    await cubit.close();
  });
}
