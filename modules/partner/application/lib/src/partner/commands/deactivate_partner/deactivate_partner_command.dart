import 'package:vet45_partner_domain/domain.dart';
import 'package:vet45_shared_application/application.dart';

import 'deactivate_partner_result.dart';

@RequiresPermission(PartnerPermissions.statusManage)
@RequiresTenant()
final class DeactivatePartnerCommand extends CommandBase<DeactivatePartnerResult>
    implements ICommand<DeactivatePartnerResult>, ITenantScopedCommand {
  DeactivatePartnerCommand({
    String? id,
    required this.tenantId,
    required this.actorId,
    required this.partnerId,
    this.reason,
    required this.expectedVersion,
  }) : super(id);

  @override
  final String tenantId;
  final String actorId;
  final String partnerId;
  final String? reason;
  final int expectedVersion;
}
