import 'package:vet45_annotations/vet45_annotations.dart';
import 'package:vet45_iam_domain/domain.dart';

@ModuleManifest(
  name: 'iam',
  permissions: [
    IamPermissions.membersRead,
    IamPermissions.membersAssignRole,
    InterimPermissionCodes.partnerRead,
    InterimPermissionCodes.partnerWrite,
    InterimPermissionCodes.settingsEinvoiceConfigure,
  ],
)
final class IamModuleDefinition {}
