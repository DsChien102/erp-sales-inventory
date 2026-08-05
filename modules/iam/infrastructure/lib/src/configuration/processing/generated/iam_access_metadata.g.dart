// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint

import 'package:vet45_iam_application/application.dart';
import 'package:vet45_shared_application/application.dart';
import 'package:vet45_shared_infrastructure/infrastructure.dart';

final iamAccessMetadataRegistry = AccessMetadataRegistry({
  AcceptInvitationCommand: AccessMetadata(
    isPublic: true,
    idempotencyKeyField: 'idempotencyKey',
  ),
  ActivateTenantCommand: AccessMetadata(
    permission: 'tenant.activate',
    requiresTenant: true,
  ),
  AssignMemberRoleCommand: AccessMetadata(
    permission: 'iam.members.assign_role',
    requiresTenant: true,
  ),
  CompleteMyPasswordResetCommand: AccessMetadata(
    isPublic: true,
  ),
  CreateInvitationCommand: AccessMetadata(
    permission: 'tenant.member.invite',
    requiresTenant: true,
    idempotencyKeyField: 'idempotencyKey',
  ),
  CreateTenantOnboardingCommand: AccessMetadata(
    permission: 'platform.tenant.create',
    idempotencyKeyField: 'idempotencyKey',
  ),
  DeactivateMembershipCommand: AccessMetadata(
    permission: 'tenant.member.status.update',
    requiresTenant: true,
  ),
  DeclineInvitationCommand: AccessMetadata(
    isPublic: true,
    idempotencyKeyField: 'idempotencyKey',
  ),
  GetCurrentSessionQuery: AccessMetadata(
    isPublic: true,
  ),
  GetInvitationQuery: AccessMetadata(
    permission: 'tenant.member.view',
    requiresTenant: true,
  ),
  GetMyIdentityProfileQuery: AccessMetadata(
    isPublic: true,
  ),
  GetPlatformAuditLogQuery: AccessMetadata(
    permission: 'platform.audit.view',
  ),
  GetPlatformTenantQuery: AccessMetadata(
    permission: 'platform.tenant.view',
  ),
  GetPlatformUserQuery: AccessMetadata(
    permission: 'platform.user.view',
  ),
  GetTenantAuditLogQuery: AccessMetadata(
    permission: 'tenant.audit.view',
    requiresTenant: true,
  ),
  GetTenantMemberQuery: AccessMetadata(
    permission: 'tenant.member.view',
    requiresTenant: true,
  ),
  GetTenantOnboardingOperationQuery: AccessMetadata(
    permission: 'platform.tenant.create',
  ),
  GetTenantQuery: AccessMetadata(
    permission: 'tenant.view',
    requiresTenant: true,
  ),
  GetTenantReadinessQuery: AccessMetadata(
    permission: 'tenant.readiness.view',
    requiresTenant: true,
  ),
  InspectInvitationTokenQuery: AccessMetadata(
    isPublic: true,
  ),
  ListAssignableInvitationRolesQuery: AccessMetadata(
    permission: 'tenant.member.invite',
    requiresTenant: true,
  ),
  ListInvitationsQuery: AccessMetadata(
    permission: 'tenant.member.view',
    requiresTenant: true,
  ),
  ListPlatformTenantMembersQuery: AccessMetadata(
    permission: 'platform.tenant.member.view',
  ),
  ListTenantMembersQuery: AccessMetadata(
    permission: 'tenant.member.view',
    requiresTenant: true,
  ),
  ReactivateMembershipCommand: AccessMetadata(
    permission: 'tenant.member.status.update',
    requiresTenant: true,
  ),
  RegisterFromInvitationCommand: AccessMetadata(
    isPublic: true,
    idempotencyKeyField: 'idempotencyKey',
  ),
  RemoveMembershipCommand: AccessMetadata(
    permission: 'tenant.member.remove',
    requiresTenant: true,
  ),
  RequestMyPasswordResetCommand: AccessMetadata(
    isPublic: true,
  ),
  RequestPlatformPasswordResetCommand: AccessMetadata(
    permission: 'platform.user.password_reset.initiate',
    idempotencyKeyField: 'idempotencyKey',
  ),
  ResendInvitationCommand: AccessMetadata(
    permission: 'tenant.member.invite',
    requiresTenant: true,
    idempotencyKeyField: 'idempotencyKey',
  ),
  ResendMyPasswordResetCommand: AccessMetadata(
    isPublic: true,
  ),
  RestorePlatformTenantCommand: AccessMetadata(
    permission: 'platform.tenant.restore',
    idempotencyKeyField: 'idempotencyKey',
  ),
  RestorePlatformUserCommand: AccessMetadata(
    permission: 'platform.user.restore',
    idempotencyKeyField: 'idempotencyKey',
  ),
  RetryTenantOnboardingOperationCommand: AccessMetadata(
    permission: 'platform.tenant.create',
    idempotencyKeyField: 'idempotencyKey',
  ),
  RevokeInvitationCommand: AccessMetadata(
    permission: 'tenant.member.invite',
    requiresTenant: true,
    idempotencyKeyField: 'idempotencyKey',
  ),
  SearchPlatformAuditLogsQuery: AccessMetadata(
    permission: 'platform.audit.view',
  ),
  SearchPlatformTenantsQuery: AccessMetadata(
    permission: 'platform.tenant.view',
  ),
  SearchPlatformUsersQuery: AccessMetadata(
    permission: 'platform.user.view',
  ),
  SearchTenantAuditLogsQuery: AccessMetadata(
    permission: 'tenant.audit.view',
    requiresTenant: true,
  ),
  SendActivationInvitationCommand: AccessMetadata(
    permission: 'platform.user.activation_invite.send',
    idempotencyKeyField: 'idempotencyKey',
  ),
  SignInCommand: AccessMetadata(
    isPublic: true,
  ),
  SignOutCommand: AccessMetadata(
    isPublic: true,
  ),
  SuspendPlatformTenantCommand: AccessMetadata(
    permission: 'platform.tenant.suspend',
    idempotencyKeyField: 'idempotencyKey',
  ),
  SuspendPlatformUserCommand: AccessMetadata(
    permission: 'platform.user.suspend',
    idempotencyKeyField: 'idempotencyKey',
  ),
  SwitchActiveTenantCommand: AccessMetadata(
    requiresTenant: true,
  ),
  TransferPlatformTenantOwnershipCommand: AccessMetadata(
    permission: 'platform.tenant.owner.transfer',
    idempotencyKeyField: 'idempotencyKey',
  ),
  UpdateMyIdentityProfileCommand: AccessMetadata(
    isPublic: true,
  ),
  UpdateTenantProfileCommand: AccessMetadata(
    permission: 'tenant.profile.update',
    requiresTenant: true,
  ),
  UpsertLegalProfileCommand: AccessMetadata(
    permission: 'tenant.legal_profile.update',
    requiresTenant: true,
  ),
  VerifyMyPasswordResetCommand: AccessMetadata(
    isPublic: true,
  ),
});

