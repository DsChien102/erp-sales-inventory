import 'package:vet45_annotations/vet45_annotations.dart';
import 'package:vet45_partner_domain/domain.dart';
import 'package:vet45_shared_application/application.dart';

import 'delete_partner_result.dart';

@RequiresPermission(PartnerPermissions.delete)
@RequiresTenant()
final class DeletePartnerCommand extends CommandBase<DeletePartnerResult>
    implements ITenantScopedCommand {
  DeletePartnerCommand({
    String? id,
    required this.tenantId,
    required this.actorId,
    required this.partnerId,
    required this.expectedVersion,
    required this.hasBusinessData,
  }) : super(id);

  @override
  final String tenantId;

  final String actorId;
  final String partnerId;
  final int expectedVersion;
  final bool hasBusinessData;
}
