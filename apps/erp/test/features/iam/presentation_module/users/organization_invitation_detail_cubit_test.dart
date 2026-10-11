import 'package:flutter_test/flutter_test.dart';
import 'package:erp/core/iam/iam_codes.dart';
import '../../support/fake_iam_backend.dart';
import 'package:erp/features/iam/presentation.dart';
import '../../support/iam_fixtures.dart';

void main() {
  OrganizationInvitationDetailCubit buildCubit({
    required FakeIamBackend module,
    String invitationId = 'inv-1',
    IdempotencyKeyFactory? keyFactory,
  }) {
    return OrganizationInvitationDetailCubit(
      invitationId: invitationId,
      invitations: FakeInvitationRepository(module),
      keyFactory: keyFactory ?? FakeIdempotencyKeyFactory(),
    );
  }

  test('load uses GetInvitationQuery by id', () async {
    final module = FakeIamBackend(scenario: FakeIamScenario.invitationResendOk);
    final cubit = buildCubit(module: module);
    await cubit.load();
    final query = module.queriesOf<GetInvitationQuery>().single;
    expect(query.invitationId, 'inv-1');
    expect(cubit.state.invitation?.inviteeEmail, 'invitee@example.com');
    expect(cubit.state.canMutate, isTrue);
    await cubit.close();
  });

  test('resend and revoke use displayed version and independent keys',
      () async {
    final module = FakeIamBackend(scenario: FakeIamScenario.invitationResendOk);
    final keys = FakeIdempotencyKeyFactory();
    final cubit = buildCubit(module: module, keyFactory: keys);
    await cubit.load();
    final before = cubit.state.invitation!;

    await cubit.resend();
    final resend = module.commandsOf<ResendInvitationCommand>().single;
    expect(resend.expectedVersion, before.version);
    expect(resend.idempotencyKey, 'resend-invitation-test-idempotency-key');
    expect(cubit.state.invitation!.version, before.version + 1);
    expect(cubit.state.invitation!.status, 'pending');

    final afterResend = cubit.state.invitation!;
    await cubit.revoke(reason: 'Sai email người nhận');
    final revoke = module.commandsOf<RevokeInvitationCommand>().single;
    expect(revoke.reason, 'Sai email người nhận');
    expect(revoke.expectedVersion, afterResend.version);
    expect(revoke.idempotencyKey, 'revoke-invitation-test-idempotency-key');
    expect(cubit.state.invitation!.status, 'revoked');
    expect(cubit.state.canMutate, isFalse);
    expect(keys.calls, 2);
    await cubit.close();
  });

  test('empty revoke reason does not send command', () async {
    final module = FakeIamBackend(scenario: FakeIamScenario.invitationRevokeOk);
    final cubit = buildCubit(module: module);
    await cubit.load();
    await cubit.revoke(reason: '   ');
    expect(module.commandsOf<RevokeInvitationCommand>(), isEmpty);
    expect(cubit.state.failure?.code, IamBlockedCodes.validationError);
    await cubit.close();
  });

  test('STATE_CHANGED reloads detail before next action', () async {
    final module = FakeIamBackend(scenario: FakeIamScenario.invitationStateChanged);
    final cubit = buildCubit(module: module);
    await cubit.load();
    expect(module.queriesOf<GetInvitationQuery>(), hasLength(1));

    await cubit.resend();
    expect(cubit.state.failure?.code, IamBlockedCodes.stateChanged);
    expect(cubit.state.failure?.requiresReload, isTrue);
    expect(module.queriesOf<GetInvitationQuery>(), hasLength(2));
    expect(cubit.state.invitation, isNotNull);
    expect(cubit.state.isSubmitting, isFalse);
    await cubit.close();
  });

  test('resend delivery failed keeps pending with warning', () async {
    final cubit = buildCubit(
      module: FakeIamBackend(
        scenario: FakeIamScenario.invitationResendDeliveryFailed,
      ),
    );
    await cubit.load();
    await cubit.resend();
    expect(cubit.state.invitation?.status, 'pending');
    expect(cubit.state.deliveryWarning, isTrue);
    expect(cubit.state.failure, isNull);
    expect(cubit.state.canMutate, isTrue);
    await cubit.close();
  });

  test('terminal invitation hides mutations', () async {
    final cubit = buildCubit(
      module: FakeIamBackend(scenario: FakeIamScenario.invitationResendOk),
      invitationId: 'inv-expired',
    );
    await cubit.load();
    expect(cubit.state.invitation?.status, 'expired');
    expect(cubit.state.canMutate, isFalse);
    await cubit.resend();
    expect(cubit.state.invitation?.status, 'expired');
    await cubit.close();
  });

  test('invitationTerminalReject maps failure', () async {
    final cubit = buildCubit(
      module: FakeIamBackend(
        scenario: FakeIamScenario.invitationTerminalReject,
      ),
    );
    await cubit.load();
    await cubit.resend();
    expect(cubit.state.failure?.code, IamBlockedCodes.invitationAlreadyUsed);
    await cubit.close();
  });

  test('cross-tenant mutation maps not found', () async {
    final cubit = buildCubit(
      module: FakeIamBackend(
        scenario: FakeIamScenario.invitationCrossTenantNotFound,
      ),
    );
    await cubit.load();
    await cubit.resend();
    expect(cubit.state.failure?.code, IamBlockedCodes.resourceNotFound);
    await cubit.close();
  });
}
