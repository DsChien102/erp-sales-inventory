import 'package:test/test.dart';
import 'package:vet45_iam_application/application.dart';
import 'package:vet45_shared_application/application.dart';

class _IdempotentPlatformGateway implements IPlatformAdminGateway {
  final Map<String, TenantOnboardingResultDto> _byKey = {};
  var createCalls = 0;

  @override
  Future<bool> hasPlatformPermission(String permission) async => true;

  @override
  Future<List<PlatformUserSummaryDto>> searchPlatformUsers({
    String? query,
    PlatformUserStatus? status,
  }) async =>
      const [];

  @override
  Future<PlatformUserDetailDto> getPlatformUser(String userId) async {
    throw UnimplementedError();
  }

  @override
  Future<void> sendActivationInvitation(String userId) async {}

  @override
  Future<void> requestPasswordReset(String userId) async {}

  @override
  Future<void> suspendPlatformUser({
    required String userId,
    required String reason,
  }) async {}

  @override
  Future<void> restorePlatformUser(String userId) async {}

  @override
  Future<TenantOnboardingResultDto> createTenantOnboarding({
    required OnboardingOwnerInput owner,
    required String organizationName,
    required String idempotencyKey,
    String? correlationId,
  }) async {
    createCalls++;
    final existing = _byKey[idempotencyKey];
    if (existing != null) {
      return existing;
    }

    final ownerUserId = owner.isExisting
        ? owner.existingUserId!
        : 'generated-new-user';
    final result = TenantOnboardingResultDto(
      tenantId: 'tenant-$createCalls',
      ownerMembershipId: 'tenant-$createCalls:$ownerUserId',
      ownerUserId: ownerUserId,
      tenantStatus: 'provisioning',
      correlationId: correlationId ?? 'corr-$idempotencyKey',
      isNewUser: owner.isNewUser,
    );
    _byKey[idempotencyKey] = result;
    return result;
  }
}

void main() {
  group('scn_e01_u03_fr01_01 create tenant onboarding', () {
    test('onboarding_existing_user_ok', () async {
      final gateway = _IdempotentPlatformGateway();
      final handler = CreateTenantOnboardingCommandHandler(
        platformGateway: gateway,
      );

      final result = await handler.handle(
        CreateTenantOnboardingCommand(
          owner: const OnboardingOwnerInput.existing('u-existing'),
          organizationName: 'Clinic A',
          idempotencyKey: 'key-1',
        ),
      );

      expect(result.tenantStatus, 'provisioning');
      expect(result.ownerUserId, 'u-existing');
      expect(result.isNewUser, isFalse);
    });

    test('onboarding_new_user_ok (fake identity)', () async {
      final gateway = _IdempotentPlatformGateway();
      final handler = CreateTenantOnboardingCommandHandler(
        platformGateway: gateway,
      );

      final result = await handler.handle(
        CreateTenantOnboardingCommand(
          owner: const OnboardingOwnerInput.newUser(
            lastName: 'Nguyen',
            firstName: 'An',
            email: 'an@vet45.local',
          ),
          organizationName: 'Clinic B',
          idempotencyKey: 'key-new',
        ),
      );

      expect(result.tenantStatus, 'provisioning');
      expect(result.isNewUser, isTrue);
      expect(result.ownerUserId, 'generated-new-user');
    });

    test('onboarding_retry_idempotent returns same result', () async {
      final gateway = _IdempotentPlatformGateway();
      final handler = CreateTenantOnboardingCommandHandler(
        platformGateway: gateway,
      );
      final command = CreateTenantOnboardingCommand(
        owner: const OnboardingOwnerInput.existing('u-1'),
        organizationName: 'Clinic C',
        idempotencyKey: 'retry-key',
        correlationId: 'corr-1',
      );

      final first = await handler.handle(command);
      final second = await handler.handle(command);

      expect(gateway.createCalls, 2);
      expect(second.tenantId, first.tenantId);
      expect(second.correlationId, first.correlationId);
    });

    test('onboarding_validation_error — empty org name', () async {
      final validator = CreateTenantOnboardingCommandValidator();

      expect(
        () => validator.validate(
          CreateTenantOnboardingCommand(
            owner: const OnboardingOwnerInput.existing('u-1'),
            organizationName: '  ',
            idempotencyKey: 'k',
          ),
        ),
        throwsA(isA<ValidationException>()),
      );
    });

    test('onboarding_validation_error — invalid new user email', () async {
      final validator = CreateTenantOnboardingCommandValidator();

      expect(
        () => validator.validate(
          CreateTenantOnboardingCommand(
            owner: const OnboardingOwnerInput.newUser(
              lastName: 'N',
              firstName: 'A',
              email: 'not-an-email',
            ),
            organizationName: 'Clinic',
            idempotencyKey: 'k',
          ),
        ),
        throwsA(isA<ValidationException>()),
      );
    });
  });
}
