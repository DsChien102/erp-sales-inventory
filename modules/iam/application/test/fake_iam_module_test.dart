import 'package:test/test.dart';
import 'package:vet45_iam_application/testing.dart';
import 'package:vet45_iam_domain/domain.dart';
import 'package:vet45_shared_application/application.dart';

void main() {
  group('FakeIamModule §S15', () {
    test('users_search_ok — SearchPlatformUsersQuery by email', () async {
      final module = FakeIamModule(scenario: FakeIamScenario.usersSearchOk);

      final result = await module.executeQueryAsync(
        SearchPlatformUsersQuery(query: 'lan@gmail.com'),
      );

      expect(result.items, hasLength(1));
      expect(result.items.single.email, 'lan@gmail.com');
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
        SendActivationInvitationCommand(
          userId: 'hoa-tran',
          expectedVersion: 1,
          idempotencyKey: 'act-hoa',
        ),
      );

      expect(module.activationInviteCount, 1);
    });

    test('suspend_ok then restore_ok', () async {
      final module = FakeIamModule(scenario: FakeIamScenario.suspendOk);

      await module.executeCommandAsync(
        SuspendPlatformUserCommand(
          userId: 'lan-le',
          reason: 'policy',
          expectedVersion: 1,
          idempotencyKey: 'sus-lan',
        ),
      );
      final suspended = await module.executeQueryAsync(
        GetPlatformUserQuery(userId: 'lan-le'),
      );
      expect(suspended.status, PlatformUserStatus.suspended);

      final restoreModule = FakeIamModule(scenario: FakeIamScenario.restoreOk);
      await restoreModule.executeCommandAsync(
        RestorePlatformUserCommand(
          userId: 'minh-nguyen',
          expectedVersion: 1,
          idempotencyKey: 'res-minh',
        ),
      );
      final restored = await restoreModule.executeQueryAsync(
        GetPlatformUserQuery(userId: 'minh-nguyen'),
      );
      expect(restored.status, PlatformUserStatus.active);
    });

    test('suspend stale expectedVersion throws STATE_CHANGED', () async {
      final module = FakeIamModule(scenario: FakeIamScenario.suspendOk);

      await expectLater(
        () => module.executeCommandAsync(
          SuspendPlatformUserCommand(
            userId: 'lan-le',
            reason: 'policy',
            expectedVersion: 2,
            idempotencyKey: 'sus-lan-stale',
          ),
        ),
        throwsA(
          isA<IamBlockedException>().having(
            (e) => e.code,
            'code',
            IamBlockedCodes.stateChanged,
          ),
        ),
      );
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

    test('auth_sign_in_ok — SignInCommand invokes hook', () async {
      var hooked = false;
      final module = FakeIamModule(
        scenario: FakeIamScenario.authSignInOk,
        onSignedIn: (_) => hooked = true,
      );

      await module.executeCommandAsync(
        SignInTenantUserCommand(email: 'admin@vet45.local', password: 'secret'),
      );

      expect(module.signInCount, 1);
      expect(module.lastSignedInEmail, 'admin@vet45.local');
      expect(hooked, isTrue);
    });

    test('S0 sign-in then session query returns safe authenticated DTO', () async {
      final module = FakeIamModule(scenario: FakeIamScenario.authSignInOk);

      await module.executeCommandAsync<void>(
        SignInTenantUserCommand(email: 'admin@vet45.local', password: 'secret'),
      );
      final session = await module.executeQueryAsync<SessionDto>(
        GetCurrentSessionQuery(),
      );

      expect(session.isAuthenticated, isTrue);
      expect(session.email, 'admin@vet45.local');
      expect(session.permissions, isNot(contains('secret')));
    });

    test('auth_invalid — SignInCommand throws', () async {
      final module = FakeIamModule(scenario: FakeIamScenario.authInvalid);

      expect(
        () => module.executeCommandAsync(
          SignInTenantUserCommand(email: 'x@y.z', password: 'bad'),
        ),
        throwsA(isA<ApplicationException>()),
      );
    });

    test('SignOutCommand invokes hook', () async {
      var cleared = false;
      final module = FakeIamModule(onSignedOut: () => cleared = true);

      await module.executeCommandAsync(SignOutCommand());

      expect(module.signOutCount, 1);
      expect(cleared, isTrue);
    });

    test('S0 expired fake throws exact code and clears authentication', () async {
      final module = FakeIamModule(scenario: FakeIamScenario.authSessionExpired);
      module.establishAuthenticatedSessionForTesting('admin@vet45.local');

      await expectLater(
        () => module.executeQueryAsync<SessionDto>(GetCurrentSessionQuery()),
        throwsA(
          isA<IamBlockedException>().having(
            (error) => error.code,
            'code',
            IamBlockedCodes.sessionExpired,
          ),
        ),
      );
      expect(module.isAuthenticated, isFalse);
    });

    test('S0 sign-out clears fake session even when remote sign-out fails', () async {
      final module = FakeIamModule(scenario: FakeIamScenario.signOutRemoteError);
      module.establishAuthenticatedSessionForTesting('admin@vet45.local');

      final result = await module.executeCommandAsync<SignOutResultDto>(
        SignOutCommand(),
      );

      expect(result.localCleared, isTrue);
      expect(result.remoteSucceeded, isFalse);
      expect(module.isAuthenticated, isFalse);
    });
  });

  group('FakeIamModule §S16', () {
    test('tenants_search_ok — SearchPlatformTenantsQuery', () async {
      final module = FakeIamModule(scenario: FakeIamScenario.tenantsSearchOk);

      final result = await module.executeQueryAsync(
        SearchPlatformTenantsQuery(query: 'Mậu'),
      );

      expect(result.items, hasLength(1));
      expect(result.items.single.tenantId, 'org-001');
    });

    test('tenant_detail_ok — GetPlatformTenantQuery', () async {
      final module = FakeIamModule(scenario: FakeIamScenario.tenantDetailOk);

      final detail = await module.executeQueryAsync(
        GetPlatformTenantQuery(tenantId: 'org-001'),
      );

      expect(detail.name, 'Mậu Hiên');
      expect(detail.members, isNotEmpty);
    });

    test('tenant_forbidden_403 — throws PLATFORM_PERMISSION_DENIED', () async {
      final module = FakeIamModule(
        scenario: FakeIamScenario.tenantForbidden403,
      );

      expect(
        () => module.executeQueryAsync(SearchPlatformTenantsQuery()),
        throwsA(
          isA<ApplicationException>().having(
            (e) => e.message,
            'message',
            contains('PLATFORM_PERMISSION_DENIED'),
          ),
        ),
      );
    });

    test('tenant_suspend_ok / tenant_restore_ok', () async {
      final module = FakeIamModule(scenario: FakeIamScenario.tenantSuspendOk);

      await module.executeCommandAsync(
        SuspendPlatformTenantCommand(
          tenantId: 'org-001',
          reason: 'risk review',
          expectedVersion: 1,
          idempotencyKey: 'sus-t',
        ),
      );
      final suspended = await module.executeQueryAsync(
        GetPlatformTenantQuery(tenantId: 'org-001'),
      );
      expect(suspended.status.name, 'suspended');

      final restoreModule = FakeIamModule(
        scenario: FakeIamScenario.tenantRestoreOk,
      );
      await restoreModule.executeCommandAsync(
        RestorePlatformTenantCommand(
          tenantId: 'org-003',
          expectedVersion: 1,
          idempotencyKey: 'res-t',
        ),
      );
      final restored = await restoreModule.executeQueryAsync(
        GetPlatformTenantQuery(tenantId: 'org-003'),
      );
      expect(restored.status.name, 'active');
    });

    test('tenant_suspend_rejects_never_activated_tenant', () async {
      final module = FakeIamModule(scenario: FakeIamScenario.tenantSuspendOk);

      final before = await module.executeQueryAsync(
        GetPlatformTenantQuery(tenantId: 'org-002'),
      );
      expect(before.status, TenantLifecycleStatus.provisioning);
      expect(before.activatedAt, isNull);

      expect(
        () => module.executeCommandAsync(
          SuspendPlatformTenantCommand(
            tenantId: 'org-002',
            reason: 'risk review',
            expectedVersion: before.version,
            idempotencyKey: 'sus-provisioning',
          ),
        ),
        throwsA(
          isA<IamBlockedException>().having(
            (e) => e.code,
            'code',
            IamBlockedCodes.tenantStateInvalid,
          ),
        ),
      );
    });

    test('tenant_restore_rejects_suspended_never_activated_tenant', () async {
      final module = FakeIamModule(scenario: FakeIamScenario.tenantRestoreOk);

      expect(
        () => module.executeCommandAsync(
          RestorePlatformTenantCommand(
            tenantId: 'org-005',
            expectedVersion: 1,
            idempotencyKey: 'res-legacy-never-activated',
          ),
        ),
        throwsA(
          isA<IamBlockedException>().having(
            (e) => e.code,
            'code',
            IamBlockedCodes.tenantStateInvalid,
          ),
        ),
      );
    });

    test('tenant_closed_reject — TENANT_STATE_INVALID', () async {
      final module = FakeIamModule(
        scenario: FakeIamScenario.tenantClosedReject,
      );

      expect(
        () => module.executeCommandAsync(
          SuspendPlatformTenantCommand(
            tenantId: 'org-004',
            reason: 'attempt',
            expectedVersion: 1,
            idempotencyKey: 'sus-t',
          ),
        ),
        throwsA(
          isA<IamBlockedException>().having(
            (e) => e.code,
            'code',
            IamBlockedCodes.tenantStateInvalid,
          ),
        ),
      );
    });

    test('ownership_transfer_ok — one owner', () async {
      final module = FakeIamModule(
        scenario: FakeIamScenario.ownershipTransferOk,
      );

      await module.executeCommandAsync(
        TransferPlatformTenantOwnershipCommand(
          tenantId: 'org-001',
          newOwnerUserId: 'hoa-tran',
          expectedVersion: 1,
          idempotencyKey: 'xfer-1',
        ),
      );
      final detail = await module.executeQueryAsync(
        GetPlatformTenantQuery(tenantId: 'org-001'),
      );
      expect(detail.ownerUserId, 'hoa-tran');
      expect(detail.members.where((m) => m.isOwner), hasLength(1));
    });

    test('ownership_invalid_target — OWNER_TARGET_INVALID', () async {
      final module = FakeIamModule(
        scenario: FakeIamScenario.ownershipInvalidTarget,
      );

      expect(
        () => module.executeCommandAsync(
          TransferPlatformTenantOwnershipCommand(
            tenantId: 'org-001',
            newOwnerUserId: 'hoa-tran',
            expectedVersion: 1,
            idempotencyKey: 'xfer-bad',
          ),
        ),
        throwsA(
          isA<IamBlockedException>().having(
            (e) => e.code,
            'code',
            IamBlockedCodes.ownerTargetInvalid,
          ),
        ),
      );
    });

    test('audit_search_ok / audit detail', () async {
      final module = FakeIamModule(scenario: FakeIamScenario.auditSearchOk);

      final logs = await module.executeQueryAsync(
        SearchPlatformAuditLogsQuery(action: null),
      );
      expect(logs.items, isNotEmpty);

      final detail = await module.executeQueryAsync(
        GetPlatformAuditLogQuery(auditLogId: logs.items.first.id),
      );
      expect(detail.correlationId, isNotEmpty);
    });

    test('audit_forbidden_403', () async {
      final module = FakeIamModule(scenario: FakeIamScenario.auditForbidden403);

      expect(
        () => module.executeQueryAsync(SearchPlatformAuditLogsQuery()),
        throwsA(isA<ApplicationException>()),
      );
    });
  });

  group('FakeIamModule §S1–§S3 EP-05', () {
    test('tenants_multi — ListAccessibleTenantsQuery marks current', () async {
      final module = FakeIamModule(scenario: FakeIamScenario.tenantsMulti);

      final list = await module.executeQueryAsync(ListAccessibleTenantsQuery());

      expect(list, hasLength(3));
      expect(list.where((t) => t.isCurrent), hasLength(1));
      expect(list.firstWhere((t) => t.isCurrent).tenantId, 'org-001');
    });

    test('tenants_single — one current membership', () async {
      final module = FakeIamModule(scenario: FakeIamScenario.tenantsSingle);

      final list = await module.executeQueryAsync(ListAccessibleTenantsQuery());

      expect(list, hasLength(1));
      expect(list.single.isCurrent, isTrue);
    });

    test('tenants_suspended_disabled — suspended item present', () async {
      final module = FakeIamModule(
        scenario: FakeIamScenario.tenantsSuspendedDisabled,
      );

      final list = await module.executeQueryAsync(ListAccessibleTenantsQuery());

      expect(
        list.any((t) => t.status == TenantLifecycleStatus.suspended),
        isTrue,
      );
    });

    test('tenants_provisioning — provisioning status in list', () async {
      final module = FakeIamModule(
        scenario: FakeIamScenario.tenantsProvisioning,
      );

      final list = await module.executeQueryAsync(ListAccessibleTenantsQuery());

      expect(
        list.any((t) => t.status == TenantLifecycleStatus.provisioning),
        isTrue,
      );
    });

    test('switch_ok — SwitchTenantContextCommand updates current', () async {
      final module = FakeIamModule(scenario: FakeIamScenario.switchOk);

      final ctx = await module.executeCommandAsync(
        SwitchTenantContextCommand(targetTenantId: 'org-002'),
      );

      expect(ctx.status, TenantContextStatus.valid);
      expect(ctx.tenantId, 'org-002');
      expect(module.currentTenantId, 'org-002');
      expect(module.lastSelectedTenantId, 'org-002');
      expect(module.switchTenantCount, 1);

      final list = await module.executeQueryAsync(ListAccessibleTenantsQuery());
      expect(list.firstWhere((t) => t.isCurrent).tenantId, 'org-002');
    });

    test('switch_denied — TENANT_ACCESS_DENIED', () async {
      final module = FakeIamModule(scenario: FakeIamScenario.switchDenied);

      expect(
        () => module.executeCommandAsync(
          SwitchTenantContextCommand(targetTenantId: 'org-002'),
        ),
        throwsA(
          isA<ApplicationException>().having(
            (e) => e.message,
            'message',
            contains('TENANT_ACCESS_DENIED'),
          ),
        ),
      );
    });

    test('switch_suspended — TENANT_SUSPENDED', () async {
      final module = FakeIamModule(scenario: FakeIamScenario.switchSuspended);

      expect(
        () => module.executeCommandAsync(
          SwitchTenantContextCommand(targetTenantId: 'org-003'),
        ),
        throwsA(
          isA<ApplicationException>().having(
            (e) => e.message,
            'message',
            contains('TENANT_SUSPENDED'),
          ),
        ),
      );
    });

    test('switch_closed — TENANT_CLOSED', () async {
      final module = FakeIamModule(scenario: FakeIamScenario.switchClosed);

      expect(
        () => module.executeCommandAsync(
          SwitchTenantContextCommand(targetTenantId: 'org-004'),
        ),
        throwsA(
          isA<ApplicationException>().having(
            (e) => e.message,
            'message',
            contains('TENANT_CLOSED'),
          ),
        ),
      );
    });

    test('switch_same_tenant — VALIDATION_ERROR', () async {
      final module = FakeIamModule(scenario: FakeIamScenario.switchSameTenant);

      expect(
        () => module.executeCommandAsync(
          SwitchTenantContextCommand(targetTenantId: 'org-001'),
        ),
        throwsA(isA<ValidationException>()),
      );
    });

    test('bootstrap_valid — GetTenantContextQuery from last selected', () async {
      final module = FakeIamModule(scenario: FakeIamScenario.bootstrapValid);

      final ctx = await module.executeQueryAsync(
        GetTenantContextQuery(bootstrapFromLastSelected: true),
      );

      expect(ctx.status, TenantContextStatus.valid);
      expect(ctx.tenantId, 'org-001');
      expect(ctx.tenantName, 'Thú y Minh Phát');
    });

    test('bootstrap_current_session — no preference uses current tenant', () async {
      final module = FakeIamModule(scenario: FakeIamScenario.bootstrapValid)
        ..currentTenantId = 'org-001'
        ..lastSelectedTenantId = null;

      final ctx = await module.executeQueryAsync(
        GetTenantContextQuery(bootstrapFromLastSelected: true),
      );

      expect(ctx.status, TenantContextStatus.valid);
      expect(ctx.tenantId, 'org-001');
      expect(module.lastSelectedTenantId, 'org-001');
    });

    test('bootstrap_invalid — status none (OQ-07)', () async {
      final module = FakeIamModule(scenario: FakeIamScenario.bootstrapInvalid);

      final ctx = await module.executeQueryAsync(
        GetTenantContextQuery(bootstrapFromLastSelected: true),
      );

      expect(ctx.status, TenantContextStatus.none);
    });

    test('context_none — status none', () async {
      final module = FakeIamModule(scenario: FakeIamScenario.contextNone);

      final ctx = await module.executeQueryAsync(
        GetTenantContextQuery(bootstrapFromLastSelected: true),
      );

      expect(ctx.status, TenantContextStatus.none);
    });

    test('context_invalidated — mid-session blocked state', () async {
      final module = FakeIamModule(
        scenario: FakeIamScenario.contextInvalidated,
      );

      final ctx = await module.executeQueryAsync(GetTenantContextQuery());

      expect(ctx.status, TenantContextStatus.invalidated);
      expect(ctx.blockedErrorCode, 'TENANT_SUSPENDED');
      expect(
        ctx.invalidationReason,
        TenantContextInvalidationReason.tenantSuspended,
      );
    });
  });
}
