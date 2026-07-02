// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint

import 'package:vet45_partner_application/application.dart';
import 'package:vet45_shared_application/application.dart';

final partnerModuleManifest = GeneratedModuleManifest(
  name: 'partner',
  permissions: [
    'partner.create',
    'partner.delete',
    'partner.manage_status',
    'partner.update',
    'partner.view',
    'partner.view_detail',
  ],
  commandTypes: [
    DeactivatePartnerCommand,
    DeletePartnerCommand,
    ReactivatePartnerCommand,
    RegisterPartnerCommand,
    UpdatePartnerProfileCommand,
  ],
  queryTypes: [
    CheckDuplicatePartnersForUpdateQuery,
    CheckDuplicatePartnersQuery,
    GetPartnerDetailQuery,
    SearchPartnersQuery,
  ],
);

