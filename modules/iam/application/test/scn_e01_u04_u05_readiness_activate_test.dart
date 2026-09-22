import 'package:test/test.dart';
import 'package:vet45_iam_application/testing.dart';
import 'package:vet45_iam_domain/domain.dart';
import 'package:vet45_shared_application/application.dart';

void main() {
  final readiness = TenantReadinessDto(
    tenantId: 'org-002',
    status: TenantLifecycleStatus.provisioning,
    blockers: const [TenantReadinessIssueCodes.contactAddressMissing],
    warnings: const [TenantReadinessIssueCodes.legalProfileMissing],
    evaluatedAt: DateTime.utc(2026, 7, 13),
    tenantVersion: 1,
    canActivate: false,
  );

  final activation = TenantActivationResultDto(
    tenantId: 'org-002',
    status: TenantLifecycleStatus.active,
    activatedAt: DateTime.utc(2026, 7, 14),
    version: 2,
  );

  group('scn_e01_u04_u05 readiness + activate handlers', () {
    test('GetTenantReadinessQuery delegates to gateway', () async {
      final gateway = _RecordingReadinessGateway(readiness);
      final handler = GetTenantReadinessQueryHandler(readinessGateway: gateway);
      final result = await handler.handle(
        GetTenantReadinessQuery(tenantId: 'org-002'),
      );
      expect(result.canActivate, isFalse);
      expect(result.blockers, isNotEmpty);
    });

    test('ActivateTenantCommand delegates to gateway', () async {
      final gateway = _RecordingActivationGateway(activation);
      final handler = ActivateTenantCommandHandler(commandGateway: gateway);
      final result = await handler.handle(
        ActivateTenantCommand(
          tenantId: 'org-002',
          expectedVersion: 1,
          idempotencyKey: 'key-1',
        ),
      );
      expect(result.status, TenantLifecycleStatus.active);
      expect(gateway.calls, 1);
    });

    test('FakeTenantActivationIdentityPort returns snapshot', () async {
      final port = FakeTenantActivationIdentityPort(
        scenario: FakeIamScenario.readinessWarningOnly,
      );
      final snapshot = await port.getActivationSnapshot(
        tenantId: 'org-002',
        ownerUserId: 'lan-le',
      );
      expect(snapshot.emailVerified, isTrue);
    });

    for (final blocker in const [
      TenantReadinessIssueCodes.displayNameMissing,
      TenantReadinessIssueCodes.contactEmailMissingOrInvalid,
      TenantReadinessIssueCodes.contactPhoneMissingOrInvalid,
      TenantReadinessIssueCodes.contactAddressMissing,
      TenantReadinessIssueCodes.ownerMembershipInvalid,
      TenantReadinessIssueCodes.ownerAcceptancePending,
      TenantReadinessIssueCodes.ownerInvitationExpired,
      TenantReadinessIssueCodes.ownerIdentityInactive,
      TenantReadinessIssueCodes.ownerIdentityUnavailable,
      TenantReadinessIssueCodes.ownerEmailUnverified,
    ]) {
      test('readiness with $blocker cannot activate', () async {
        final gateway = _RecordingReadinessGateway(
          TenantReadinessDto(
            tenantId: 'org-002',
            status: TenantLifecycleStatus.provisioning,
            blockers: [blocker],
            warnings: const [],
            evaluatedAt: DateTime.utc(2026, 7, 13),
            tenantVersion: 1,
            canActivate: false,
          ),
        );
        final handler = GetTenantReadinessQueryHandler(
          readinessGateway: gateway,
        );
        final result = await handler.handle(
          GetTenantReadinessQuery(tenantId: 'org-002'),
        );
        expect(result.canActivate, isFalse);
        expect(result.blockers, contains(blocker));
      });
    }

    group('ActivateTenantCommandValidator', () {
      final validator = ActivateTenantCommandValidator();

      test('accepts valid command', () async {
        await validator.validate(
          ActivateTenantCommand(
            tenantId: 'org-002',
            expectedVersion: 1,
            idempotencyKey: 'key-1',
          ),
        );
      });

      test('rejects empty idempotency key', () {
        expect(
          () => validator.validate(
            ActivateTenantCommand(
              tenantId: 'org-002',
              expectedVersion: 1,
              idempotencyKey: '  ',
            ),
          ),
          throwsA(isA<ValidationException>()),
        );
      });

      test('rejects negative expected version', () {
        expect(
          () => validator.validate(
            ActivateTenantCommand(
              tenantId: 'org-002',
              expectedVersion: -1,
              idempotencyKey: 'key-1',
            ),
          ),
          throwsA(isA<ValidationException>()),
        );
      });
    });

    test('Unavailable activation identity port throws SYSTEM_ERROR', () async {
      final port = UnavailableTenantActivationIdentityPortFake();
      expect(
        () => port.getActivationSnapshot(
          tenantId: 'org-002',
          ownerUserId: 'lan-le',
        ),
        throwsA(
          isA<IamBlockedException>().having(
            (e) => e.code,
            'code',
            IamBlockedCodes.systemError,
          ),
        ),
      );
    });
  });
}

final class _RecordingReadinessGateway implements ITenantReadinessGateway {
  _RecordingReadinessGateway(this.readiness);

  final TenantReadinessDto readiness;

  @override
  Future<TenantReadinessDto> getReadiness({required String tenantId}) async {
    return readiness;
  }
}

final class _RecordingActivationGateway
    implements ITenantActivationCommandGateway {
  _RecordingActivationGateway(this.result);

  final TenantActivationResultDto result;
  int calls = 0;

  @override
  Future<TenantActivationResultDto> activate({
    required String tenantId,
    required int expectedVersion,
    required String idempotencyKey,
  }) async {
    calls++;
    return result;
  }
}
