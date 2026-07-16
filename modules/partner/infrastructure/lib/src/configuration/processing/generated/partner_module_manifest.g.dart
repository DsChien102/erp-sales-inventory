// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint

import 'package:vet45_partner_application/application.dart';
import 'package:vet45_shared_application/application.dart';

final partnerModuleManifest = GeneratedModuleManifest(
  name: 'partner',
  permissions: [
    'partner.contact.manage',
    'partner.create',
    'partner.delete',
    'partner.detail.view',
    'partner.history.view',
    'partner.status.manage',
    'partner.transform',
    'partner.update',
    'partner.view',
  ],
  commandTypes: [
    AddOrganizationContactCommand,
    CreatePartnerCommand,
    DeactivatePartnerCommand,
    ReactivatePartnerCommand,
    RecordPartnerHistoryCommand,
    RemoveOrganizationContactCommand,
    SoftDeletePartnerCommand,
    TransformPersonToOrganizationCommand,
    UpdateOrganizationContactCommand,
    UpdatePartnerProfileCommand,
  ],
  queryTypes: [
    CheckDeleteEligibilityQuery,
    CheckDuplicatePartnersQuery,
    GetPartnerActionLogsQuery,
    GetPartnerDetailQuery,
    GetPartnerHistoryQuery,
    SearchPartnersQuery,
  ],
);

