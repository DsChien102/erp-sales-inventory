import 'package:vet45_partner_application/application.dart';
import 'package:vet45_partner_domain/domain.dart';
import 'package:vet45_shared_application/application.dart';
import 'package:vet45_shared_infrastructure/infrastructure.dart';

/// Hand-maintained access metadata until partner codegen is enabled.
final IAccessMetadataRegistry partnerAccessMetadataRegistry = AccessMetadataRegistry(
  <Type, AccessMetadata>{
    RegisterPartnerCommand: const AccessMetadata(
      permission: 'partner.create',
      requiresTenant: true,
    ),
    CheckDuplicatePartnersQuery: const AccessMetadata(
      permission: 'partner.create',
      requiresTenant: true,
    ),
    CheckDuplicatePartnersForUpdateQuery: const AccessMetadata(
      permission: PartnerPermissions.update,
      requiresTenant: true,
    ),
    SearchPartnersQuery: const AccessMetadata(
      permission: 'partner.view',
      requiresTenant: true,
    ),
    GetPartnerDetailQuery: const AccessMetadata(
      permission: PartnerPermissions.viewDetail,
      requiresTenant: true,
    ),
    UpdatePartnerProfileCommand: const AccessMetadata(
      permission: PartnerPermissions.update,
      requiresTenant: true,
    ),
    DeactivatePartnerCommand: const AccessMetadata(
      permission: PartnerPermissions.manageStatus,
      requiresTenant: true,
    ),
    ReactivatePartnerCommand: const AccessMetadata(
      permission: PartnerPermissions.manageStatus,
      requiresTenant: true,
    ),
    DeletePartnerCommand: const AccessMetadata(
      permission: PartnerPermissions.delete,
      requiresTenant: true,
    ),
  },
);
