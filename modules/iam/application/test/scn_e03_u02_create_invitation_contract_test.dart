import 'package:test/test.dart';
import 'package:vet45_iam_application/application.dart';
import 'package:vet45_shared_application/application.dart';

void main() {
  group('scn_e03_u02 create invitation contract', () {
    test('public exports expose S7 symbols', () {
      expect(CreateInvitationCommand, isNotNull);
      expect(CreateInvitationCommandHandler, isNotNull);
      expect(CreateInvitationCommandValidator, isNotNull);
      expect(ITenantInvitationCommandGateway, isNotNull);
      expect(InvitationDetailDto, isNotNull);
    });

    test('validator rejects invalid email and empty key', () async {
      final validator = CreateInvitationCommandValidator();
      await expectLater(
        validator.validate(
          CreateInvitationCommand(
            tenantId: 'org-001',
            inviteeEmail: 'not-an-email',
            initialRoleId: 'role-staff',
            idempotencyKey: 'k1',
          ),
        ),
        throwsA(isA<ValidationException>()),
      );
      await expectLater(
        validator.validate(
          CreateInvitationCommand(
            tenantId: 'org-001',
            inviteeEmail: 'a@b.c',
            initialRoleId: 'role-staff',
            idempotencyKey: '  ',
          ),
        ),
        throwsA(isA<ValidationException>()),
      );
    });

    test('handler delegates canonical email to gateway', () async {
      String? seenEmail;
      final gateway = FakeTenantInvitationCommandGateway(
        onCreate: ({
          required tenantId,
          required inviteeEmail,
          required initialRoleId,
          required idempotencyKey,
        }) async {
          seenEmail = inviteeEmail;
          return InvitationDetailDto(
            invitationId: 'inv-1',
            inviteeEmail: inviteeEmail,
            initialRoleId: initialRoleId,
            initialRoleLabel: 'Staff',
            status: 'pending',
            expiresAt: DateTime.utc(2026, 8, 5),
            deliveryStatus: 'queued',
            deliveryCorrelationId: 'c1',
            version: 1,
            createdAt: DateTime.utc(2026, 7, 29),
            createdBy: 'actor',
            lastSentAt: DateTime.utc(2026, 7, 29),
          );
        },
      );
      final handler = CreateInvitationCommandHandler(commandGateway: gateway);
      final result = await handler.handle(
        CreateInvitationCommand(
          tenantId: 'org-001',
          inviteeEmail: '  New.User@Example.COM ',
          initialRoleId: 'role-staff',
          idempotencyKey: 'idem-1',
        ),
      );
      expect(seenEmail, 'new.user@example.com');
      expect(result.status, 'pending');
      expect(result.deliveryStatus, 'queued');
      expect(result.expiresAt.difference(result.createdAt).inDays, 7);
    });

    test('FakeIamModule invite_ok and conflict scenarios', () async {
      final ok = FakeIamModule(scenario: FakeIamScenario.inviteOk);
      final created = await ok.executeCommandAsync(
        CreateInvitationCommand(
          tenantId: 'org-001',
          inviteeEmail: 'fresh@example.com',
          initialRoleId: 'role-staff',
          idempotencyKey: 'k-ok',
        ),
      );
      expect(created.status, 'pending');
      expect(created.deliveryStatus, 'queued');

      Future<void> expectBlocked(
        FakeIamScenario scenario,
        String code,
      ) async {
        final module = FakeIamModule(scenario: scenario);
        expect(
          () => module.executeCommandAsync(
            CreateInvitationCommand(
              tenantId: 'org-001',
              inviteeEmail: 'x@y.z',
              initialRoleId: 'role-staff',
              idempotencyKey: 'k',
            ),
          ),
          throwsA(
            isA<IamBlockedException>().having((e) => e.code, 'code', code),
          ),
        );
      }

      await expectBlocked(
        FakeIamScenario.inviteDuplicateMembership,
        IamBlockedCodes.duplicateMembership,
      );
      await expectBlocked(
        FakeIamScenario.inviteInactiveMembership,
        IamBlockedCodes.membershipInactive,
      );
      await expectBlocked(
        FakeIamScenario.invitePendingExists,
        IamBlockedCodes.invitationPendingExists,
      );
      await expectBlocked(
        FakeIamScenario.inviteRoleNotAssignable,
        IamBlockedCodes.roleNotAssignable,
      );
      await expectBlocked(
        FakeIamScenario.inviteForbidden,
        IamBlockedCodes.permissionDenied,
      );
      await expectBlocked(
        FakeIamScenario.inviteIdempotencyConflict,
        IamBlockedCodes.idempotencyConflict,
      );
    });

    test('FakeIamModule invite_idempotent_retry returns same result', () async {
      final module = FakeIamModule(scenario: FakeIamScenario.inviteIdempotentRetry);
      final cmd = CreateInvitationCommand(
        tenantId: 'org-001',
        inviteeEmail: 'retry@example.com',
        initialRoleId: 'role-staff',
        idempotencyKey: 'same-key',
      );
      final first = await module.executeCommandAsync(cmd);
      final second = await module.executeCommandAsync(cmd);
      expect(second.invitationId, first.invitationId);
      expect(second.deliveryCorrelationId, first.deliveryCorrelationId);
    });

    test('FakeIamModule invite_delivery_failed keeps pending invitation', () async {
      final module = FakeIamModule(scenario: FakeIamScenario.inviteDeliveryFailed);
      final created = await module.executeCommandAsync(
        CreateInvitationCommand(
          tenantId: 'org-001',
          inviteeEmail: 'fail@example.com',
          initialRoleId: 'role-staff',
          idempotencyKey: 'k-fail',
        ),
      );
      expect(created.status, 'pending');
      expect(created.deliveryStatus, 'failed');
    });
  });
}
