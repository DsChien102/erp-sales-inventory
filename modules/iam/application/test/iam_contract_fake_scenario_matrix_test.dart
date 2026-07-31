import 'package:test/test.dart';
import 'package:vet45_iam_application/application.dart';
import 'package:vet45_iam_domain/domain.dart';

Matcher throwsBlocked(String code) => throwsA(
  isA<IamBlockedException>().having((e) => e.code, 'code', code),
);

void main() {
  group('TH-01 fake scenario matrix', () {
    test('S0 exact ids stay mapped', () async {
      expect(FakeIamScenario.values, contains(FakeIamScenario.authSessionOk));
      expect(
        FakeIamScenario.values,
        contains(FakeIamScenario.authSessionExpired),
      );
      expect(FakeIamScenario.values, contains(FakeIamScenario.authSignOutOk));

      final signIn = FakeIamModule(scenario: FakeIamScenario.authSignInOk);
      await signIn.executeCommandAsync(
        SignInCommand(email: 'admin@vet45.local', password: 'secret'),
      );
      expect(signIn.signInCount, 1);

      final signOut = FakeIamModule(scenario: FakeIamScenario.authSignOutOk);
      final signOutResult = await signOut.executeCommandAsync(SignOutCommand());
      expect(signOutResult.remoteSucceeded, isTrue);

      final expired = FakeIamModule(scenario: FakeIamScenario.authSessionExpired);
      expired.establishAuthenticatedSessionForTesting('admin@vet45.local');
      await expectLater(
        () => expired.executeQueryAsync<SessionDto>(GetCurrentSessionQuery()),
        throwsBlocked(IamBlockedCodes.sessionExpired),
      );
      expect(expired.isAuthenticated, isFalse);
    });

    test('S1 closed disabled and inactive membership exclusion', () async {
      final closed = FakeIamModule(
        scenario: FakeIamScenario.tenantsClosedDisabled,
      );
      final closedList = await closed.executeQueryAsync(
        ListAccessibleTenantsQuery(),
      );
      final closedRow = closedList.singleWhere((t) => t.tenantId == 'org-004');
      expect(closedRow.isSelectable, isFalse);
      expect(closedRow.status, TenantLifecycleStatus.closed);

      final inactive = FakeIamModule(
        scenario: FakeIamScenario.tenantsExcludesInactiveMembership,
      );
      final inactiveList = await inactive.executeQueryAsync(
        ListAccessibleTenantsQuery(),
      );
      expect(inactiveList.map((t) => t.tenantId), ['org-001']);
    });

    test('S2 switch session/preference failures preserve context', () async {
      final sessionFail = FakeIamModule(
        scenario: FakeIamScenario.switchSessionFailure,
      );
      final beforeSession = sessionFail.currentTenantId;
      final beforePref = sessionFail.lastSelectedTenantId;
      await expectLater(
        () => sessionFail.executeCommandAsync(
          SwitchTenantContextCommand(targetTenantId: 'org-002'),
        ),
        throwsBlocked(IamBlockedCodes.systemError),
      );
      expect(sessionFail.currentTenantId, beforeSession);
      expect(sessionFail.lastSelectedTenantId, beforePref);

      final prefFail = FakeIamModule(
        scenario: FakeIamScenario.switchPreferenceFailure,
      );
      final beforePrefSession = prefFail.currentTenantId;
      final beforePrefPref = prefFail.lastSelectedTenantId;
      await expectLater(
        () => prefFail.executeCommandAsync(
          SwitchTenantContextCommand(targetTenantId: 'org-002'),
        ),
        throwsBlocked(IamBlockedCodes.systemError),
      );
      expect(prefFail.currentTenantId, beforePrefSession);
      expect(prefFail.lastSelectedTenantId, beforePrefPref);
    });

    test('S3 identity inactive and permissions refreshed', () async {
      final identityInactive = FakeIamModule(
        scenario: FakeIamScenario.tenantsIdentityInactive,
      );
      await expectLater(
        () => identityInactive.executeQueryAsync(ListAccessibleTenantsQuery()),
        throwsBlocked(IamBlockedCodes.authenticationRequired),
      );

      final none = FakeIamModule(scenario: FakeIamScenario.contextNone);
      final noneContext = await none.executeQueryAsync(
        GetTenantContextQuery(bootstrapFromLastSelected: true),
      );
      expect(noneContext.status, TenantContextStatus.none);

      final contextInactive = FakeIamModule(
        scenario: FakeIamScenario.contextIdentityInactive,
      );
      final invalidated = await contextInactive.executeQueryAsync(
        GetTenantContextQuery(),
      );
      expect(invalidated.status, TenantContextStatus.invalidated);
      expect(
        invalidated.invalidationReason,
        TenantContextInvalidationReason.identityInactive,
      );

      final refreshed = FakeIamModule(
        scenario: FakeIamScenario.contextPermissionsRefreshed,
      );
      final valid = await refreshed.executeQueryAsync(GetTenantContextQuery());
      expect(valid.status, TenantContextStatus.valid);
      expect(valid.permissions, contains('tenant.members.view'));
    });

    test('S6 members/invitations filter and forbidden', () async {
      final filtered = FakeIamModule(
        scenario: FakeIamScenario.membersFilterInactive,
      );
      final members = await filtered.executeQueryAsync(
        ListTenantMembersQuery(tenantId: 'org-001', status: 'inactive'),
      );
      expect(members.items, isNotEmpty);
      expect(members.items.every((m) => m.status == 'inactive'), isTrue);

      final invitations = FakeIamModule(
        scenario: FakeIamScenario.invitationsSearchOk,
      );
      final invitationPage = await invitations.executeQueryAsync(
        ListInvitationsQuery(tenantId: 'org-001'),
      );
      expect(invitationPage.items, isNotEmpty);

      final detail = FakeIamModule(scenario: FakeIamScenario.invitationDetailOk);
      final invitation = await detail.executeQueryAsync(
        GetInvitationQuery(tenantId: 'org-001', invitationId: 'inv-1'),
      );
      expect(invitation.invitationId, 'inv-1');
      expect(invitation.inviteeEmail, isNot(contains('token')));

      final forbidden = FakeIamModule(
        scenario: FakeIamScenario.memberInvitationForbidden,
      );
      await expectLater(
        () => forbidden.executeQueryAsync(
          ListTenantMembersQuery(tenantId: 'org-001'),
        ),
        throwsBlocked(IamBlockedCodes.permissionDenied),
      );
    });

    test('S8 inspect/accept edge scenarios', () async {
      final inspectNew = FakeIamModule(
        scenario: FakeIamScenario.inspectNewAccount,
      );
      final preview = await inspectNew.executeQueryAsync(
        InspectInvitationTokenQuery(token: 'token-new'),
      );
      expect(preview.accountExists, isFalse);
      expect(preview.inviteeEmail, isNotEmpty);

      final rotated = FakeIamModule(scenario: FakeIamScenario.acceptRotatedToken);
      await expectLater(
        () => rotated.executeCommandAsync(
          AcceptInvitationCommand(
            token: 'old-token',
            idempotencyKey: 'accept-rotated',
          ),
        ),
        throwsBlocked(IamBlockedCodes.invitationTokenInvalid),
      );

      final concurrent = FakeIamModule(
        scenario: FakeIamScenario.acceptConcurrent,
      );
      await expectLater(
        () => concurrent.executeCommandAsync(
          AcceptInvitationCommand(
            token: 'token-concurrent',
            idempotencyKey: 'accept-concurrent',
          ),
        ),
        throwsBlocked(IamBlockedCodes.invitationAlreadyUsed),
      );

      final retry = FakeIamModule(
        scenario: FakeIamScenario.acceptRetryAfterIdentityCreated,
      );
      final membership = await retry.executeCommandAsync(
        AcceptInvitationCommand(
          token: 'token-retry',
          idempotencyKey: 'accept-retry',
        ),
      );
      expect(membership.status, MembershipStatus.active);
      expect(membership.membershipId, isNotEmpty);
    });

    test('S10 membership lifecycle scenarios', () async {
      final detail = FakeIamModule(scenario: FakeIamScenario.memberDetailOk);
      final member = await detail.executeQueryAsync(
        GetTenantMemberQuery(tenantId: 'org-001', membershipId: 'mem-staff-1'),
      );
      expect(member.membershipId, 'mem-staff-1');
      expect(member.status, MembershipStatus.active);

      final notFound = FakeIamModule(scenario: FakeIamScenario.memberNotFound);
      await expectLater(
        () => notFound.executeQueryAsync(
          GetTenantMemberQuery(tenantId: 'org-001', membershipId: 'missing'),
        ),
        throwsBlocked(IamBlockedCodes.resourceNotFound),
      );

      final deactivate = FakeIamModule(
        scenario: FakeIamScenario.memberDeactivateOk,
      );
      final deactivated = await deactivate.executeCommandAsync(
        DeactivateMembershipCommand(
          tenantId: 'org-001',
          membershipId: 'mem-staff-1',
          expectedVersion: 1,
        ),
      );
      expect(deactivated.status, MembershipStatus.inactive);
      expect(deactivated.version, 2);

      final reactivate = FakeIamModule(
        scenario: FakeIamScenario.memberReactivateOk,
      );
      final reactivated = await reactivate.executeCommandAsync(
        ReactivateMembershipCommand(
          tenantId: 'org-001',
          membershipId: 'mem-inactive-1',
          expectedVersion: 2,
        ),
      );
      expect(reactivated.status, MembershipStatus.active);
      expect(reactivated.version, 3);

      final remove = FakeIamModule(scenario: FakeIamScenario.memberRemoveOk);
      final removed = await remove.executeCommandAsync(
        RemoveMembershipCommand(
          tenantId: 'org-001',
          membershipId: 'mem-staff-1',
          expectedVersion: 1,
        ),
      );
      expect(removed.status, MembershipStatus.removed);

      final lastOwner = FakeIamModule(
        scenario: FakeIamScenario.memberLastOwnerProtected,
      );
      await expectLater(
        () => lastOwner.executeCommandAsync(
          DeactivateMembershipCommand(
            tenantId: 'org-001',
            membershipId: 'mem-owner-1',
            expectedVersion: 1,
          ),
        ),
        throwsBlocked(IamBlockedCodes.lastOwnerProtected),
      );

      final stateChanged = FakeIamModule(
        scenario: FakeIamScenario.memberStateChanged,
      );
      await expectLater(
        () => stateChanged.executeCommandAsync(
          DeactivateMembershipCommand(
            tenantId: 'org-001',
            membershipId: 'mem-staff-1',
            expectedVersion: 1,
          ),
        ),
        throwsBlocked(IamBlockedCodes.stateChanged),
      );

      final terminal = FakeIamModule(
        scenario: FakeIamScenario.memberRemovedTerminal,
      );
      await expectLater(
        () => terminal.executeCommandAsync(
          ReactivateMembershipCommand(
            tenantId: 'org-001',
            membershipId: 'mem-removed-1',
            expectedVersion: 3,
          ),
        ),
        throwsBlocked(IamBlockedCodes.membershipRemoved),
      );

      final memberForbidden = FakeIamModule(
        scenario: FakeIamScenario.memberForbidden,
      );
      await expectLater(
        () => memberForbidden.executeCommandAsync(
          RemoveMembershipCommand(
            tenantId: 'org-001',
            membershipId: 'mem-staff-1',
            expectedVersion: 1,
          ),
        ),
        throwsBlocked(IamBlockedCodes.permissionDenied),
      );
    });

    test('S11 readiness and activate scenarios', () async {
      final blocked = FakeIamModule(scenario: FakeIamScenario.readinessBlocked);
      final readiness = await blocked.executeQueryAsync(
        GetTenantReadinessQuery(tenantId: 'org-001'),
      );
      expect(readiness.canActivate, isFalse);
      expect(readiness.blockers, isNotEmpty);

      final activateOk = FakeIamModule(scenario: FakeIamScenario.activateOk);
      final activated = await activateOk.executeCommandAsync(
        ActivateTenantCommand(
          tenantId: 'org-002',
          expectedVersion: 1,
          idempotencyKey: 'act-ok-1',
        ),
      );
      expect(activated.status, TenantLifecycleStatus.active);

      final readinessBlocked = FakeIamModule(
        scenario: FakeIamScenario.activateReadinessBlocked,
      );
      await expectLater(
        () => readinessBlocked.executeCommandAsync(
          ActivateTenantCommand(
            tenantId: 'org-002',
            expectedVersion: 1,
            idempotencyKey: 'act-blocked',
          ),
        ),
        throwsBlocked(IamBlockedCodes.readinessBlocked),
      );

      final retry = FakeIamModule(
        scenario: FakeIamScenario.activateIdempotentRetry,
      );
      final first = await retry.executeCommandAsync(
        ActivateTenantCommand(
          tenantId: 'org-002',
          expectedVersion: 1,
          idempotencyKey: 'act-retry',
        ),
      );
      final second = await retry.executeCommandAsync(
        ActivateTenantCommand(
          tenantId: 'org-002',
          expectedVersion: 1,
          idempotencyKey: 'act-retry',
        ),
      );
      expect(second.tenantId, first.tenantId);
      expect(second.version, first.version);

      final conflict = FakeIamModule(
        scenario: FakeIamScenario.activateIdempotencyConflict,
      );
      await expectLater(
        () => conflict.executeCommandAsync(
          ActivateTenantCommand(
            tenantId: 'org-002',
            expectedVersion: 1,
            idempotencyKey: 'act-conflict',
          ),
        ),
        throwsBlocked(IamBlockedCodes.idempotencyConflict),
      );

      final alreadyActive = FakeIamModule(
        scenario: FakeIamScenario.activateAlreadyActive,
      );
      await expectLater(
        () => alreadyActive.executeCommandAsync(
          ActivateTenantCommand(
            tenantId: 'org-001',
            expectedVersion: 1,
            idempotencyKey: 'act-already',
          ),
        ),
        throwsBlocked(IamBlockedCodes.tenantStateInvalid),
      );
    });

    test('S12 tenant profile and legal scenarios', () async {
      final profileOk = FakeIamModule(scenario: FakeIamScenario.tenantProfileOk);
      final profile = await profileOk.executeQueryAsync(
        GetTenantQuery(tenantId: 'org-001'),
      );
      expect(profile.displayName, 'Mậu Hiên');

      final updateOk = FakeIamModule(
        scenario: FakeIamScenario.tenantProfileUpdateOk,
      );
      final updated = await updateOk.executeCommandAsync(
        UpdateTenantProfileCommand(
          tenantId: 'org-001',
          displayName: 'Mậu Hiên Updated',
          contactEmail: 'new@mauhien.vn',
          contactPhone: '+84901112233',
          contactAddressText: '456 Le Loi',
          provinceCode: '01',
          communeCode: '00001',
          expectedVersion: 1,
        ),
      );
      expect(updated.displayName, 'Mậu Hiên Updated');
      expect(updated.version, 2);

      final validation = FakeIamModule(
        scenario: FakeIamScenario.tenantProfileValidation,
      );
      await expectLater(
        () => validation.executeCommandAsync(
          UpdateTenantProfileCommand(
            tenantId: 'org-001',
            displayName: '',
            contactEmail: null,
            contactPhone: null,
            contactAddressText: null,
            provinceCode: null,
            communeCode: null,
            expectedVersion: 1,
          ),
        ),
        throwsBlocked(IamBlockedCodes.validationError),
      );

      final stale = FakeIamModule(scenario: FakeIamScenario.tenantProfileStale);
      await expectLater(
        () => stale.executeCommandAsync(
          UpdateTenantProfileCommand(
            tenantId: 'org-001',
            displayName: 'Stale',
            contactEmail: 'a@b.c',
            contactPhone: null,
            contactAddressText: null,
            provinceCode: null,
            communeCode: null,
            expectedVersion: 1,
          ),
        ),
        throwsBlocked(IamBlockedCodes.stateChanged),
      );

      final profileForbidden = FakeIamModule(
        scenario: FakeIamScenario.tenantProfileForbidden,
      );
      await expectLater(
        () => profileForbidden.executeQueryAsync(
          GetTenantQuery(tenantId: 'org-001'),
        ),
        throwsBlocked(IamBlockedCodes.permissionDenied),
      );

      final profileNotFound = FakeIamModule(
        scenario: FakeIamScenario.tenantProfileNotFound,
      );
      await expectLater(
        () => profileNotFound.executeQueryAsync(
          GetTenantQuery(tenantId: 'missing'),
        ),
        throwsBlocked(IamBlockedCodes.resourceNotFound),
      );

      final legalOk = FakeIamModule(scenario: FakeIamScenario.legalUpsertOk);
      final legalSaved = await legalOk.executeCommandAsync(
        UpsertLegalProfileCommand(
          tenantId: 'org-001',
          legalEntityType: 'ENTERPRISE',
          legalName: 'Mậu Hiên Co., Ltd',
          taxCode: '0123456789',
          registeredAddressText: '123 Nguyen Trai',
          provinceCode: '01',
          communeCode: '00001',
          expectedVersion: 1,
          allowDuplicateTaxCode: false,
        ),
      );
      expect(legalSaved.isWarning, isFalse);

      final legalWarning = FakeIamModule(
        scenario: FakeIamScenario.legalDuplicateWarning,
      );
      final warning = await legalWarning.executeCommandAsync(
        UpsertLegalProfileCommand(
          tenantId: 'org-001',
          legalEntityType: 'ENTERPRISE',
          legalName: 'Dup Co',
          taxCode: '9999999999',
          registeredAddressText: '1 A',
          provinceCode: '01',
          communeCode: '00001',
          expectedVersion: 1,
          allowDuplicateTaxCode: false,
        ),
      );
      expect(warning.isWarning, isTrue);

      final legalConfirm = FakeIamModule(
        scenario: FakeIamScenario.legalDuplicateConfirm,
      );
      final confirmed = await legalConfirm.executeCommandAsync(
        UpsertLegalProfileCommand(
          tenantId: 'org-001',
          legalEntityType: 'ENTERPRISE',
          legalName: 'Confirmed Co',
          taxCode: '9999999999',
          registeredAddressText: '1 A',
          provinceCode: '01',
          communeCode: '00001',
          expectedVersion: 1,
          allowDuplicateTaxCode: true,
        ),
      );
      expect(confirmed.isWarning, isFalse);
    });

    test('S13 tenant audit scenarios', () async {
      final detailOk = FakeIamModule(
        scenario: FakeIamScenario.tenantAuditDetailOk,
      );
      final detail = await detailOk.executeQueryAsync(
        GetTenantAuditLogQuery(tenantId: 'org-001', auditLogId: 'AUD-T-001'),
      );
      expect(detail.auditLogId, 'AUD-T-001');
      expect(detail.actorUnavailable, isFalse);

      final empty = FakeIamModule(scenario: FakeIamScenario.tenantAuditEmpty);
      final page = await empty.executeQueryAsync(
        SearchTenantAuditLogsQuery(
          tenantId: 'org-001',
          fromUtc: DateTime.utc(2026, 1, 1),
          toUtc: DateTime.utc(2026, 12, 31),
        ),
      );
      expect(page.items, isEmpty);

      final forbidden = FakeIamModule(
        scenario: FakeIamScenario.tenantAuditForbidden,
      );
      await expectLater(
        () => forbidden.executeQueryAsync(
          GetTenantAuditLogQuery(tenantId: 'org-001', auditLogId: 'AUD-T-001'),
        ),
        throwsBlocked(IamBlockedCodes.permissionDenied),
      );

      final actorUnavailable = FakeIamModule(
        scenario: FakeIamScenario.tenantAuditActorUnavailable,
      );
      final unavailable = await actorUnavailable.executeQueryAsync(
        GetTenantAuditLogQuery(tenantId: 'org-001', auditLogId: 'AUD-T-001'),
      );
      expect(unavailable.actorUnavailable, isTrue);

      final auditCrossTenant = FakeIamModule(
        scenario: FakeIamScenario.tenantAuditCrossTenant,
      );
      await expectLater(
        () => auditCrossTenant.executeQueryAsync(
          GetTenantAuditLogQuery(tenantId: 'org-001', auditLogId: 'AUD-T-999'),
        ),
        throwsBlocked(IamBlockedCodes.resourceNotFound),
      );
    });

    test('S14 identity and password-reset scenarios', () async {
      final myAccount = FakeIamModule(scenario: FakeIamScenario.myAccountOk);
      final profile = await myAccount.executeQueryAsync(
        GetMyIdentityProfileQuery(),
      );
      expect(profile.email, 'lan@gmail.com');

      final update = FakeIamModule(scenario: FakeIamScenario.myAccountUpdateOk);
      final updated = await update.executeCommandAsync(
        UpdateMyIdentityProfileCommand(
          firstName: 'Lan',
          lastName: 'Updated',
          phoneNumber: '+84900000000',
        ),
      );
      expect(updated.lastName, 'Updated');

      final request = FakeIamModule(
        scenario: FakeIamScenario.passwordResetRequestOk,
      );
      final requestResult = await request.executeCommandAsync(
        RequestMyPasswordResetCommand(),
      );
      expect(requestResult.operationId, isNotEmpty);
      expect(requestResult.maskedEmail, isNot(contains('lan@gmail.com')));

      final module = FakeIamModule(scenario: FakeIamScenario.passwordResetResendOk);
      final first = await module.executeCommandAsync(
        RequestMyPasswordResetCommand(),
      );
      final resend = await module.executeCommandAsync(
        ResendMyPasswordResetCommand(operationId: first.operationId),
      );
      expect(resend.operationId, first.operationId);

      final verify = FakeIamModule(
        scenario: FakeIamScenario.passwordResetVerifyOk,
      );
      final verifyRequest = await verify.executeCommandAsync(
        RequestMyPasswordResetCommand(),
      );
      final verified = await verify.executeCommandAsync(
        VerifyMyPasswordResetCommand(
          operationId: verifyRequest.operationId,
          code: '123456',
        ),
      );
      expect(verified.verified, isTrue);

      final invalid = FakeIamModule(
        scenario: FakeIamScenario.passwordResetInvalidCode,
      );
      final invalidRequest = await invalid.executeCommandAsync(
        RequestMyPasswordResetCommand(),
      );
      await expectLater(
        () => invalid.executeCommandAsync(
          VerifyMyPasswordResetCommand(
            operationId: invalidRequest.operationId,
            code: '000000',
          ),
        ),
        throwsBlocked(IamBlockedCodes.resetCodeInvalid),
      );

      final complete = FakeIamModule(
        scenario: FakeIamScenario.passwordResetCompleteOk,
      );
      final completeRequest = await complete.executeCommandAsync(
        RequestMyPasswordResetCommand(),
      );
      await complete.executeCommandAsync(
        VerifyMyPasswordResetCommand(
          operationId: completeRequest.operationId,
          code: '123456',
        ),
      );
      final completion = await complete.executeCommandAsync(
        CompleteMyPasswordResetCommand(
          operationId: completeRequest.operationId,
          newPassword: 'Password#123',
        ),
      );
      expect(completion.currentSessionRotated, isTrue);
      expect(completion.otherSessionsRevoked, isTrue);

      final signOutOk = FakeIamModule(scenario: FakeIamScenario.signOutOk);
      final signOut = await signOutOk.executeCommandAsync(SignOutCommand());
      expect(signOut.localCleared, isTrue);
      expect(signOut.remoteSucceeded, isTrue);

      final remoteError = FakeIamModule(
        scenario: FakeIamScenario.signOutRemoteError,
      );
      remoteError.establishAuthenticatedSessionForTesting('lan@gmail.com');
      final remote = await remoteError.executeCommandAsync(SignOutCommand());
      expect(remote.localCleared, isTrue);
      expect(remote.remoteSucceeded, isFalse);
      expect(remoteError.isAuthenticated, isFalse);

      final unavailable = FakeIamModule(
        scenario: FakeIamScenario.identityUnavailable,
      );
      await expectLater(
        () => unavailable.executeQueryAsync(GetMyIdentityProfileQuery()),
        throwsBlocked(IamBlockedCodes.systemError),
      );
    });

    test('S15 platform users / onboarding edge scenarios', () async {
      final paged = FakeIamModule(scenario: FakeIamScenario.usersSearchPaged);
      final page = await paged.executeQueryAsync(
        SearchPlatformUsersQuery(limit: 1),
      );
      expect(page.items, hasLength(1));
      expect(page.nextCursor, isNotNull);

      final stale = FakeIamModule(scenario: FakeIamScenario.suspendStaleVersion);
      await expectLater(
        () => stale.executeCommandAsync(
          SuspendPlatformUserCommand(
            userId: 'lan-le',
            reason: 'policy',
            expectedVersion: 1,
            idempotencyKey: 'sus-stale',
          ),
        ),
        throwsBlocked(IamBlockedCodes.stateChanged),
      );

      final conflict = FakeIamModule(
        scenario: FakeIamScenario.suspendIdempotencyConflict,
      );
      await expectLater(
        () => conflict.executeCommandAsync(
          SuspendPlatformUserCommand(
            userId: 'lan-le',
            reason: 'policy',
            expectedVersion: 1,
            idempotencyKey: 'sus-conflict',
          ),
        ),
        throwsBlocked(IamBlockedCodes.idempotencyConflict),
      );

      final stepUp = FakeIamModule(scenario: FakeIamScenario.stepUpRequired);
      await expectLater(
        () => stepUp.executeCommandAsync(
          SuspendPlatformUserCommand(
            userId: 'lan-le',
            reason: 'policy',
            expectedVersion: 1,
            idempotencyKey: 'sus-stepup',
          ),
        ),
        throwsBlocked(IamBlockedCodes.stepUpAuthRequired),
      );

      final partial = FakeIamModule(
        scenario: FakeIamScenario.onboardingPartialFailure,
      );
      final partialOp = await partial.executeQueryAsync(
        GetTenantOnboardingOperationQuery(operationId: 'op-partial'),
      );
      expect(
        partialOp.status,
        TenantOnboardingOperationStatus.partialFailure,
      );
      expect(partialOp.failedStep, 'identity');

      final resume = FakeIamModule(scenario: FakeIamScenario.onboardingResumeOk);
      final resumed = await resume.executeCommandAsync(
        RetryTenantOnboardingOperationCommand(
          operationId: 'op-resume',
          idempotencyKey: 'resume-1',
        ),
      );
      expect(resumed.status, TenantOnboardingOperationStatus.completed);
    });

    test('S16 tenants filtered / ownership conflict / audit detail', () async {
      final filtered = FakeIamModule(
        scenario: FakeIamScenario.tenantsSearchFiltered,
      );
      final page = await filtered.executeQueryAsync(
        SearchPlatformTenantsQuery(readinessState: 'warning'),
      );
      expect(page.items, isNotEmpty);

      final ownershipConflict = FakeIamModule(
        scenario: FakeIamScenario.ownershipIdempotencyConflict,
      );
      await expectLater(
        () => ownershipConflict.executeCommandAsync(
          TransferPlatformTenantOwnershipCommand(
            tenantId: 'org-001',
            newOwnerUserId: 'hoa-tran',
            expectedVersion: 1,
            idempotencyKey: 'own-conflict',
          ),
        ),
        throwsBlocked(IamBlockedCodes.idempotencyConflict),
      );

      final auditDetail = FakeIamModule(scenario: FakeIamScenario.auditDetailOk);
      final detail = await auditDetail.executeQueryAsync(
        GetPlatformAuditLogQuery(auditLogId: 'AUD-000982'),
      );
      expect(detail.id, 'AUD-000982');
    });
  });
}
