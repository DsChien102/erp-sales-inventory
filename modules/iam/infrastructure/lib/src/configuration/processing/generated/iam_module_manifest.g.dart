// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint

import 'package:vet45_iam_application/application.dart';
import 'package:vet45_shared_application/application.dart';

final iamModuleManifest = GeneratedModuleManifest(
  name: 'iam',
  permissions: [
    'iam.members.assign_role',
    'iam.members.read',
    'partner.read',
    'partner.write',
    'platform.audit.view',
    'platform.tenant.create',
    'platform.tenant.member.view',
    'platform.tenant.owner.transfer',
    'platform.tenant.restore',
    'platform.tenant.suspend',
    'platform.tenant.view',
    'platform.user.activation_invite.send',
    'platform.user.create',
    'platform.user.password_reset.initiate',
    'platform.user.restore',
    'platform.user.suspend',
    'platform.user.view',
    'settings.einvoice.configure',
  ],
  commandTypes: [
    AssignMemberRoleCommand,
    CreateTenantOnboardingCommand,
    RequestPlatformPasswordResetCommand,
    RestorePlatformTenantCommand,
    RestorePlatformUserCommand,
    SendActivationInvitationCommand,
    SendEmailDeliveryCommand,
    SignInCommand,
    SignOutCommand,
    SuspendPlatformTenantCommand,
    SuspendPlatformUserCommand,
    SwitchActiveTenantCommand,
    SwitchTenantContextCommand,
    TransferPlatformTenantOwnershipCommand,
  ],
  queryTypes: [
    GetCurrentSessionQuery,
    GetPlatformAuditLogQuery,
    GetPlatformTenantQuery,
    GetPlatformUserQuery,
    GetTenantContextQuery,
    ListAccessibleTenantsQuery,
    ListPlatformTenantMembersQuery,
    ListTenantMembersQuery,
    SearchPlatformAuditLogsQuery,
    SearchPlatformTenantsQuery,
    SearchPlatformUsersQuery,
  ],
);

