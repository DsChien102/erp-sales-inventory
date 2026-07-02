// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint

import 'package:vet45_partner_application/application.dart';
import 'package:vet45_shared_application/application.dart';
import 'package:vet45_shared_infrastructure/infrastructure.dart';

final partnerAccessMetadataRegistry = AccessMetadataRegistry({
  CheckDuplicatePartnersForUpdateQuery: AccessMetadata(
    permission: 'partner.update',
    requiresTenant: true,
  ),
  CheckDuplicatePartnersQuery: AccessMetadata(
    permission: 'partner.create',
    requiresTenant: true,
  ),
  DeactivatePartnerCommand: AccessMetadata(
    permission: 'partner.manage_status',
    requiresTenant: true,
  ),
  DeletePartnerCommand: AccessMetadata(
    permission: 'partner.delete',
    requiresTenant: true,
  ),
  GetPartnerDetailQuery: AccessMetadata(
    permission: 'partner.view_detail',
    requiresTenant: true,
  ),
  ReactivatePartnerCommand: AccessMetadata(
    permission: 'partner.manage_status',
    requiresTenant: true,
  ),
  RegisterPartnerCommand: AccessMetadata(
    permission: 'partner.create',
    requiresTenant: true,
  ),
  SearchPartnersQuery: AccessMetadata(
    permission: 'partner.view',
    requiresTenant: true,
  ),
  UpdatePartnerProfileCommand: AccessMetadata(
    permission: 'partner.update',
    requiresTenant: true,
  ),
});

