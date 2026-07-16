// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint

import 'package:vet45_partner_application/application.dart';
import 'package:vet45_shared_application/application.dart';
import 'package:vet45_shared_infrastructure/infrastructure.dart';

final partnerAccessMetadataRegistry = AccessMetadataRegistry({
  AddOrganizationContactCommand: AccessMetadata(
    permission: 'partner.contact.manage',
    requiresTenant: true,
  ),
  CheckDeleteEligibilityQuery: AccessMetadata(
    permission: 'partner.delete',
    requiresTenant: true,
  ),
  CheckDuplicatePartnersQuery: AccessMetadata(
    permission: 'partner.create',
    requiresTenant: true,
  ),
  CreatePartnerCommand: AccessMetadata(
    permission: 'partner.create',
    requiresTenant: true,
  ),
  DeactivatePartnerCommand: AccessMetadata(
    permission: 'partner.status.manage',
    requiresTenant: true,
  ),
  GetPartnerActionLogsQuery: AccessMetadata(
    permission: 'partner.detail.view',
    requiresTenant: true,
  ),
  GetPartnerDetailQuery: AccessMetadata(
    permission: 'partner.detail.view',
    requiresTenant: true,
  ),
  GetPartnerHistoryQuery: AccessMetadata(
    permission: 'partner.history.view',
    requiresTenant: true,
  ),
  ReactivatePartnerCommand: AccessMetadata(
    permission: 'partner.status.manage',
    requiresTenant: true,
  ),
  RecordPartnerHistoryCommand: AccessMetadata(
    isPublic: true,
  ),
  RemoveOrganizationContactCommand: AccessMetadata(
    permission: 'partner.contact.manage',
    requiresTenant: true,
  ),
  SearchPartnersQuery: AccessMetadata(
    permission: 'partner.view',
    requiresTenant: true,
  ),
  SoftDeletePartnerCommand: AccessMetadata(
    permission: 'partner.delete',
    requiresTenant: true,
  ),
  TransformPersonToOrganizationCommand: AccessMetadata(
    permission: 'partner.transform',
    requiresTenant: true,
  ),
  UpdateOrganizationContactCommand: AccessMetadata(
    permission: 'partner.contact.manage',
    requiresTenant: true,
  ),
  UpdatePartnerProfileCommand: AccessMetadata(
    permission: 'partner.update',
    requiresTenant: true,
  ),
});

