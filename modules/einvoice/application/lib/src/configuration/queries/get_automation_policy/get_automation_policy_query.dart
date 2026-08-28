import 'package:vet45_einvoice_domain/domain.dart';
import 'package:vet45_shared_application/application.dart';
import 'automation_policy_dto.dart';

@RequiresPermission(EInvoicePermissions.manageConfiguration)
@RequiresTenant()
final class GetAutomationPolicyQuery extends QueryBase<AutomationPolicyDto>
    implements IQuery<AutomationPolicyDto>, ITenantScopedCommand {
  GetAutomationPolicyQuery({
    String? id,
    required this.tenantId,
    required this.actorId,
  }) : super(id);

  @override
  final String tenantId;
  final String actorId;
}
