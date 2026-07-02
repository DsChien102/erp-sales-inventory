import 'package:vet45_annotations/vet45_annotations.dart';
import 'package:vet45_partner_domain/domain.dart';

@ModuleManifest(
  name: 'partner',
  permissions: [
    PartnerPermissions.view,
    PartnerPermissions.create,
    PartnerPermissions.viewDetail,
    PartnerPermissions.update,
    PartnerPermissions.manageStatus,
    PartnerPermissions.delete,
  ],
)
final class PartnerModuleDefinition {}
