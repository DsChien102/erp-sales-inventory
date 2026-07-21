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
  CreateTenantOnboardingCommand: AccessMetadata(
    permission: 'platform.tenant.create',
    idempotencyKeyField: 'idempotencyKey',
  ),
  GetCurrentSessionQuery: AccessMetadata(
    isPublic: true,
  ),
  GetPlatformUserQuery: AccessMetadata(
    permission: 'platform.user.view',
  ),
  ListTenantMembersQuery: AccessMetadata(
    permission: 'iam.members.read',
    requiresTenant: true,
  ),
  RequestPlatformPasswordResetCommand: AccessMetadata(
    permission: 'platform.user.password_reset.initiate',
  ),
  RestorePlatformUserCommand: AccessMetadata(
    permission: 'platform.user.restore',
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
  SuspendPlatformUserCommand: AccessMetadata(
    permission: 'platform.user.suspend',
  ),
  SwitchActiveTenantCommand: AccessMetadata(
    requiresTenant: true,
  ),
});

