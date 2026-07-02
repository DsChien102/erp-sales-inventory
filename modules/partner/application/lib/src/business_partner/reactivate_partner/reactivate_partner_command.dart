import 'package:vet45_annotations/vet45_annotations.dart';
import 'package:vet45_partner_domain/domain.dart';
import 'package:vet45_shared_application/application.dart';

import 'reactivate_partner_result.dart';

@RequiresPermission(PartnerPermissions.manageStatus)
@RequiresTenant()
final class ReactivatePartnerCommand extends CommandBase<ReactivatePartnerResult>
    implements ICommand<ReactivatePartnerResult>, ITenantScopedCommand {
  ReactivatePartnerCommand({
    String? id,
    required this.tenantId,
    required this.actorId,
    required this.partnerId,
    required this.expectedVersion,
    required this.currentStatus,
  }) : super(id);

  @override
  final String tenantId;

  final String actorId;
  final String partnerId;
  final int expectedVersion;
  final PartnerStatus currentStatus;
}
