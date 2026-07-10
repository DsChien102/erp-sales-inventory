import 'package:vet45_annotations/vet45_annotations.dart';
import 'package:vet45_partner_domain/domain.dart';

@ModuleManifest(
  name: 'partner',
  permissions: [
    PartnerPermissions.view,
    PartnerPermissions.detailView,
    PartnerPermissions.create,
    PartnerPermissions.update,
    PartnerPermissions.contactManage,
    PartnerPermissions.transform,
    PartnerPermissions.statusManage,
    PartnerPermissions.delete,
    PartnerPermissions.historyView,
  ],
)
final class PartnerModuleDefinition {}
