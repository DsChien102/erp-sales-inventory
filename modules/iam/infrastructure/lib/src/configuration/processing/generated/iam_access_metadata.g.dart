// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint

import 'package:vet45_iam_application/application.dart';
import 'package:vet45_shared_application/application.dart';
import 'package:vet45_shared_infrastructure/infrastructure.dart';

final iamAccessMetadataRegistry = AccessMetadataRegistry({
  AssignMemberRoleCommand: AccessMetadata(
    permission: 'iam.members.assign_role',
    requiresTenant: true,
  ),
  CompleteMyPasswordResetCommand: AccessMetadata(
    isPublic: true,
  ),
  CreateTenantOnboardingCommand: AccessMetadata(
    permission: 'platform.tenant.create',
    idempotencyKeyField: 'idempotencyKey',
  ),
  GetCurrentSessionQuery: AccessMetadata(
    isPublic: true,
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
  ListPlatformTenantMembersQuery: AccessMetadata(
    permission: 'platform.tenant.member.view',
  ),
  ListTenantMembersQuery: AccessMetadata(
    permission: 'iam.members.read',
    requiresTenant: true,
  ),
  RequestMyPasswordResetCommand: AccessMetadata(
    isPublic: true,
  ),
  RequestPlatformPasswordResetCommand: AccessMetadata(
    permission: 'platform.user.password_reset.initiate',
  ),
  ResendMyPasswordResetCommand: AccessMetadata(
    isPublic: true,
  ),
  RestorePlatformTenantCommand: AccessMetadata(
    permission: 'platform.tenant.restore',
  ),
  RestorePlatformUserCommand: AccessMetadata(
    permission: 'platform.user.restore',
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
  SendActivationInvitationCommand: AccessMetadata(
    permission: 'platform.user.activation_invite.send',
  ),
  SignInCommand: AccessMetadata(
    isPublic: true,
  ),
  SignOutCommand: AccessMetadata(
    isPublic: true,
  ),
  SuspendPlatformTenantCommand: AccessMetadata(
    permission: 'platform.tenant.suspend',
  ),
  SuspendPlatformUserCommand: AccessMetadata(
    permission: 'platform.user.suspend',
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
  VerifyMyPasswordResetCommand: AccessMetadata(
    isPublic: true,
  ),
});

