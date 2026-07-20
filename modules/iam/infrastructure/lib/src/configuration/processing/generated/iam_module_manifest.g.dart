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
    'settings.einvoice.configure',
  ],
  commandTypes: [
    AssignMemberRoleCommand,
    SendEmailDeliveryCommand,
    SignInCommand,
    SignOutCommand,
    SwitchActiveTenantCommand,
  ],
  queryTypes: [
    GetCurrentSessionQuery,
    ListTenantMembersQuery,
  ],
);

