import 'package:test/test.dart';
import 'package:vet45_iam_application/application.dart';
import 'package:vet45_iam_application/testing.dart';
import 'package:vet45_shared_application/application.dart';

void main() {
  group('FakeIamModule §S15', () {
    test('users_search_ok — SearchPlatformUsersQuery by email', () async {
      final module = FakeIamModule(scenario: FakeIamScenario.usersSearchOk);

      final result = await module.executeQueryAsync(
        SearchPlatformUsersQuery(query: 'lan@gmail.com'),
      );

      expect(result, hasLength(1));
      expect(result.single.email, 'lan@gmail.com');
    });

    test('user_detail_ok — GetPlatformUserQuery returns memberships', () async {
      final module = FakeIamModule(scenario: FakeIamScenario.userDetailOk);

      final detail = await module.executeQueryAsync(
        GetPlatformUserQuery(userId: 'lan-le'),
      );

      expect(detail.fullName, 'Lê Thị Lan');
      expect(detail.memberships, isNotEmpty);
    });

    test('user_forbidden_403 — throws PLATFORM_PERMISSION_DENIED', () async {
      final module = FakeIamModule(scenario: FakeIamScenario.userForbidden403);

      expect(
        () => module.executeQueryAsync(SearchPlatformUsersQuery()),
        throwsA(
          isA<ApplicationException>().having(
            (e) => e.message,
            'message',
            contains('PLATFORM_PERMISSION_DENIED'),
          ),
        ),
      );
    });

    test('activation_resend_ok — SendActivationInvitationCommand', () async {
      final module = FakeIamModule(
        scenario: FakeIamScenario.activationResendOk,
      );

      await module.executeCommandAsync(
        SendActivationInvitationCommand(userId: 'hoa-tran'),
      );

      expect(module.activationInviteCount, 1);
    });

    test('suspend_ok then restore_ok', () async {
      final module = FakeIamModule(scenario: FakeIamScenario.suspendOk);

      await module.executeCommandAsync(
        SuspendPlatformUserCommand(userId: 'lan-le', reason: 'policy'),
      );
      final suspended = await module.executeQueryAsync(
        GetPlatformUserQuery(userId: 'lan-le'),
      );
      expect(suspended.status, PlatformUserStatus.suspended);

      final restoreModule = FakeIamModule(scenario: FakeIamScenario.restoreOk);
      await restoreModule.executeCommandAsync(
        RestorePlatformUserCommand(userId: 'minh-nguyen'),
      );
      final restored = await restoreModule.executeQueryAsync(
        GetPlatformUserQuery(userId: 'minh-nguyen'),
      );
      expect(restored.status, PlatformUserStatus.active);
    });

    test('onboarding_existing_user_ok', () async {
      final module = FakeIamModule(
        scenario: FakeIamScenario.onboardingExistingUserOk,
      );

      final result = await module.executeCommandAsync(
        CreateTenantOnboardingCommand(
          owner: const OnboardingOwnerInput.existing('lan-le'),
          organizationName: 'Công ty Demo',
          idempotencyKey: 'key-1',
        ),
      );

      expect(result.isNewUser, isFalse);
      expect(result.tenantStatus, 'provisioning');
      expect(result.ownerUserId, 'lan-le');
    });

    test('onboarding_new_user_ok', () async {
      final module = FakeIamModule(
        scenario: FakeIamScenario.onboardingNewUserOk,
      );

      final result = await module.executeCommandAsync(
        CreateTenantOnboardingCommand(
          owner: const OnboardingOwnerInput.newUser(
            lastName: 'Nguyễn',
            firstName: 'A',
            email: 'a@example.com',
          ),
          organizationName: 'Org Mới',
          idempotencyKey: 'key-new',
        ),
      );

      expect(result.isNewUser, isTrue);
    });

    test('onboarding_retry_idempotent — same key returns same result', () async {
      final module = FakeIamModule(
        scenario: FakeIamScenario.onboardingRetryIdempotent,
      );

      final first = await module.executeCommandAsync(
        CreateTenantOnboardingCommand(
          owner: const OnboardingOwnerInput.existing('lan-le'),
          organizationName: 'Org',
          idempotencyKey: 'idem-same',
        ),
      );
      final second = await module.executeCommandAsync(
        CreateTenantOnboardingCommand(
          owner: const OnboardingOwnerInput.existing('lan-le'),
          organizationName: 'Org',
          idempotencyKey: 'idem-same',
        ),
      );

      expect(second.tenantId, first.tenantId);
      expect(second.ownerMembershipId, first.ownerMembershipId);
    });

    test('onboarding_validation_error', () async {
      final module = FakeIamModule(
        scenario: FakeIamScenario.onboardingValidationError,
      );

      expect(
        () => module.executeCommandAsync(
          CreateTenantOnboardingCommand(
            owner: const OnboardingOwnerInput.existing('lan-le'),
            organizationName: 'Org',
            idempotencyKey: 'k',
          ),
        ),
        throwsA(isA<ValidationException>()),
      );
    });
  });
}
