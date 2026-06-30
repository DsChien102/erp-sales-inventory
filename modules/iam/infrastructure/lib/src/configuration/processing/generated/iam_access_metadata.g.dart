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
  GetCurrentSessionQuery: AccessMetadata(
    isPublic: true,
  ),
  ListTenantMembersQuery: AccessMetadata(
    permission: 'iam.members.read',
    requiresTenant: true,
  ),
  SignInCommand: AccessMetadata(
    isPublic: true,
  ),
  SignOutCommand: AccessMetadata(
    isPublic: true,
  ),
  SwitchActiveTenantCommand: AccessMetadata(
    requiresTenant: true,
  ),
});

