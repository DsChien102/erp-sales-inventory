import 'package:vet45_einvoice_domain/domain.dart';
import 'package:vet45_shared_application/application.dart';

import '../../queries/get_automation_policy/automation_policy_dto.dart';

@RequiresPermission(EInvoicePermissions.manageConfiguration)
@RequiresTenant()
final class UpdateAutomationPolicyCommand extends CommandBase<AutomationPolicyDto>
    implements ICommand<AutomationPolicyDto>, ITenantScopedCommand {
  UpdateAutomationPolicyCommand({
    String? id,
    required this.tenantId,
    required this.actorId,
    this.autoIssueEnabled,
    this.autoSendEnabled,
    required this.expectedPolicyVersion,
  }) : super(id);

  @override
  final String tenantId;
  final String actorId;
  final bool? autoIssueEnabled;
  final bool? autoSendEnabled;
  final int expectedPolicyVersion;
}
