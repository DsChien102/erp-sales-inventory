import 'package:test/test.dart';
import 'package:vet45_iam_application/testing.dart';
import 'package:vet45_shared_application/application.dart';

void main() {
  group('scn_e03_u04 resend revoke invitation contract', () {
    test('public exports expose S9 symbols', () {
      expect(ResendInvitationCommand, isNotNull);
      expect(RevokeInvitationCommand, isNotNull);
      expect(ResendInvitationCommandHandler, isNotNull);
      expect(RevokeInvitationCommandHandler, isNotNull);
    });

    test('validators reject empty keys / reason', () async {
      final resend = ResendInvitationCommandValidator();
      await expectLater(
        resend.validate(
          ResendInvitationCommand(
            tenantId: 'org-001',
            invitationId: 'inv-1',
            expectedVersion: 1,
            idempotencyKey: ' ',
          ),
        ),
        throwsA(isA<ValidationException>()),
      );

      final revoke = RevokeInvitationCommandValidator();
      await expectLater(
        revoke.validate(
          RevokeInvitationCommand(
            tenantId: 'org-001',
            invitationId: 'inv-1',
            expectedVersion: 1,
            reason: '  ',
            idempotencyKey: 'k',
          ),
        ),
        throwsA(isA<ValidationException>()),
      );
    });

    test('FakeIamModule invitation_resend_ok rotates expiry and version', () async {
      final module = FakeIamModule(scenario: FakeIamScenario.invitationResendOk);
      final result = await module.executeCommandAsync(
        ResendInvitationCommand(
          tenantId: 'org-001',
          invitationId: 'inv-1',
          expectedVersion: 1,
          idempotencyKey: 'resend-1',
        ),
      );
      expect(result.status, 'pending');
      expect(result.version, 2);
      expect(result.deliveryStatus, 'queued');
      expect(result.inviteeEmail, 'invitee@example.com');
      expect(
        result.expiresAt.difference(result.lastSentAt!).inDays,
        7,
      );
    });

    test('FakeIamModule invitation_revoke_ok', () async {
      final module = FakeIamModule(scenario: FakeIamScenario.invitationRevokeOk);
      final result = await module.executeCommandAsync(
        RevokeInvitationCommand(
          tenantId: 'org-001',
          invitationId: 'inv-1',
          expectedVersion: 1,
          reason: 'No longer needed',
          idempotencyKey: 'revoke-1',
        ),
      );
      expect(result.status, 'revoked');
      expect(result.revokedAt, isNotNull);
      expect(result.version, 2);
    });

    test('blocked scenarios', () async {
      Future<void> expectResend(
        FakeIamScenario scenario,
        String code,
      ) async {
        final module = FakeIamModule(scenario: scenario);
        expect(
          () => module.executeCommandAsync(
            ResendInvitationCommand(
              tenantId: 'org-001',
              invitationId: 'inv-1',
              expectedVersion: 1,
              idempotencyKey: 'k',
            ),
          ),
          throwsA(
            isA<IamBlockedException>().having((e) => e.code, 'code', code),
          ),
        );
      }

      await expectResend(
        FakeIamScenario.invitationStateChanged,
        IamBlockedCodes.stateChanged,
      );
      await expectResend(
        FakeIamScenario.invitationTerminalReject,
        IamBlockedCodes.invitationAlreadyUsed,
      );
      await expectResend(
        FakeIamScenario.invitationCrossTenantNotFound,
        IamBlockedCodes.resourceNotFound,
      );

      final oldToken = FakeIamModule(
        scenario: FakeIamScenario.invitationOldTokenInvalid,
      );
      expect(
        () => oldToken.executeCommandAsync(
          AcceptInvitationCommand(token: 'old', idempotencyKey: 'a'),
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

    test('handlers delegate to gateway', () async {
      final gateway = FakeTenantInvitationCommandGateway();
      await gateway.createInvitation(
        tenantId: 't1',
        inviteeEmail: 'a@b.c',
        initialRoleId: 'role-1',
        idempotencyKey: 'c1',
      );
      final resendHandler = ResendInvitationCommandHandler(
        commandGateway: gateway,
      );
      final resent = await resendHandler.handle(
        ResendInvitationCommand(
          tenantId: 't1',
          invitationId: gateway.current!.invitationId,
          expectedVersion: 1,
          idempotencyKey: 'r1',
        ),
      );
      expect(resent.version, 2);
      expect(resent.deliveryCorrelationId, isNot(equals('corr-c1')));

      final revokeHandler = RevokeInvitationCommandHandler(
        commandGateway: FakeTenantInvitationCommandGateway(),
      );
      final revoked = await revokeHandler.handle(
        RevokeInvitationCommand(
          tenantId: 't1',
          invitationId: 'inv-1',
          expectedVersion: 1,
          reason: 'stop',
          idempotencyKey: 'rv1',
        ),
      );
      expect(revoked.status, 'revoked');
    });

    test('invitation_resend_delivery_failed keeps pending', () async {
      final module = FakeIamModule(
        scenario: FakeIamScenario.invitationResendDeliveryFailed,
      );
      final result = await module.executeCommandAsync(
        ResendInvitationCommand(
          tenantId: 'org-001',
          invitationId: 'inv-1',
          expectedVersion: 1,
          idempotencyKey: 'fail',
        ),
      );
      expect(result.status, 'pending');
      expect(result.deliveryStatus, 'failed');
    });
  });
}
