import 'package:test/test.dart';
import 'package:vet45_iam_application/application.dart';
import 'package:vet45_iam_domain/domain.dart';

void main() {
  group('scn_e03_u03 invitation acceptance contract', () {
    test('public exports expose S8 symbols', () {
      expect(InspectInvitationTokenQuery, isNotNull);
      expect(AcceptInvitationCommand, isNotNull);
      expect(RegisterFromInvitationCommand, isNotNull);
      expect(DeclineInvitationCommand, isNotNull);
      expect(InvitationTokenInspectionDto, isNotNull);
      expect(InvitationRegistrationProfileInput, isNotNull);
      expect(InvitationRegistrationResultDto, isNotNull);
    });

    test('AcceptInvitationCommand has no actorUserId field', () {
      final command = AcceptInvitationCommand(
        token: 'tok',
        idempotencyKey: 'k1',
      );
      expect(command.token, 'tok');
      expect(command.idempotencyKey, 'k1');
      // Compile-time contract: no actorUserId constructor param.
    });

    test('inspect_existing_account and inspect_invalid_no_leak', () async {
      final ok = FakeIamModule(scenario: FakeIamScenario.inspectExistingAccount);
      final preview = await ok.executeQueryAsync(
        InspectInvitationTokenQuery(token: 'valid-token'),
      );
      expect(preview.accountExists, isTrue);
      expect(preview.inviteeEmail, contains('@'));

      final bad = FakeIamModule(scenario: FakeIamScenario.inspectInvalidNoLeak);
      expect(
        () => bad.executeQueryAsync(
          InspectInvitationTokenQuery(token: 'bad'),
        ),
        throwsA(
          isA<IamBlockedException>().having(
            (e) => e.code,
            'code',
            IamBlockedCodes.invitationTokenInvalid,
          ),
        ),
      );
    });

    test('accept paths and security blocked codes', () async {
      final ok = FakeIamModule(
        scenario: FakeIamScenario.acceptExistingAccountOk,
      );
      final membership = await ok.executeCommandAsync(
        AcceptInvitationCommand(token: 'tok-1', idempotencyKey: 'a1'),
      );
      expect(membership.status, MembershipStatus.active);

      Future<void> expectCode(FakeIamScenario scenario, String code) async {
        final module = FakeIamModule(scenario: scenario);
        expect(
          () => module.executeCommandAsync(
            AcceptInvitationCommand(token: 't', idempotencyKey: 'k'),
          ),
          throwsA(
            isA<IamBlockedException>().having((e) => e.code, 'code', code),
          ),
        );
      }

      await expectCode(
        FakeIamScenario.acceptEmailMismatch,
        IamBlockedCodes.invitationEmailMismatch,
      );
      await expectCode(
        FakeIamScenario.acceptExpired,
        IamBlockedCodes.invitationExpired,
      );
      await expectCode(
        FakeIamScenario.acceptTenantSuspended,
        IamBlockedCodes.tenantSuspended,
      );
      await expectCode(
        FakeIamScenario.acceptDeclined,
        IamBlockedCodes.invitationAlreadyUsed,
      );
    });

    test('register_and_accept_ok and identity conflict', () async {
      final ok = FakeIamModule(scenario: FakeIamScenario.registerAndAcceptOk);
      final result = await ok.executeCommandAsync(
        RegisterFromInvitationCommand(
          token: 'tok-new',
          profile: const InvitationRegistrationProfileInput(
            givenName: 'An',
            familyName: 'Nguyen',
          ),
          credentialProof: 'password-1',
          idempotencyKey: 'reg-1',
        ),
      );
      expect(result.userId, isNotEmpty);
      expect(result.membership.status, MembershipStatus.active);

      final conflict = FakeIamModule(
        scenario: FakeIamScenario.registerIdentityConflict,
      );
      expect(
        () => conflict.executeCommandAsync(
          RegisterFromInvitationCommand(
            token: 'tok',
            profile: const InvitationRegistrationProfileInput(
              givenName: 'A',
              familyName: 'B',
            ),
            credentialProof: 'x',
            idempotencyKey: 'k',
          ),
        ),
        throwsA(
          isA<IamBlockedException>().having(
            (e) => e.code,
            'code',
            IamBlockedCodes.platformUserAlreadyExists,
          ),
        ),
      );
    });

    test('decline_ok and decline_idempotent_retry', () async {
      final module = FakeIamModule(scenario: FakeIamScenario.declineOk);
      final first = await module.executeCommandAsync(
        DeclineInvitationCommand(token: 'tok', idempotencyKey: 'd1'),
      );
      expect(first.status, 'declined');

      final retry = FakeIamModule(
        scenario: FakeIamScenario.declineIdempotentRetry,
      );
      final a = await retry.executeCommandAsync(
        DeclineInvitationCommand(token: 'tok', idempotencyKey: 'same'),
      );
      final b = await retry.executeCommandAsync(
        DeclineInvitationCommand(token: 'tok', idempotencyKey: 'same'),
      );
      expect(b.invitationId, a.invitationId);
      expect(b.status, 'declined');
    });
  });

  group('handlers', () {
    test('InspectInvitationTokenQueryHandler rejects empty token', () async {
      final handler = InspectInvitationTokenQueryHandler(
        acceptancePort: FakeTenantInvitationAcceptancePort(),
      );
      expect(
        () => handler.handle(InspectInvitationTokenQuery(token: '  ')),
        throwsA(
          isA<IamBlockedException>().having(
            (e) => e.code,
            'code',
            IamBlockedCodes.invitationTokenInvalid,
          ),
        ),
      );
    });

    test('RegisterFromInvitationCommandHandler registers then accepts', () async {
      final acceptance = FakeTenantInvitationAcceptancePort(
        inspection: InvitationTokenInspectionDto(
          tenantId: 'org-001',
          tenantName: 'Org',
          inviteeEmail: 'fresh@example.com',
          initialRoleId: 'role-1',
          initialRoleLabel: 'Staff',
          expiresAt: DateTime.utc(2026, 8, 5),
          accountExists: false,
        ),
      );
      final identity = FakeInvitationIdentityPort();
      final handler = RegisterFromInvitationCommandHandler(
        acceptancePort: acceptance,
        identityPort: identity,
      );
      final result = await handler.handle(
        RegisterFromInvitationCommand(
          token: 'tok',
          profile: const InvitationRegistrationProfileInput(
            givenName: 'Lan',
            familyName: 'Le',
          ),
          credentialProof: 'secret',
          idempotencyKey: 'idem',
        ),
      );
      expect(result.userId, startsWith('user-'));
      expect(result.membership.status, MembershipStatus.active);
    });
  });
}
