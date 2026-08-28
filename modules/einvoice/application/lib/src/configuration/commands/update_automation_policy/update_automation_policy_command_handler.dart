import 'package:vet45_shared_application/application.dart';

import '../../../ports/i_automation_policy_gateway.dart';
import '../../queries/get_automation_policy/automation_policy_dto.dart';
import 'update_automation_policy_command.dart';

@CommandHandlerFor(UpdateAutomationPolicyCommand)
final class UpdateAutomationPolicyCommandHandler
    implements ICommandHandler<UpdateAutomationPolicyCommand, AutomationPolicyDto> {
  UpdateAutomationPolicyCommandHandler({
    required IAutomationPolicyGateway policyGateway,
  }) : _policyGateway = policyGateway;

  final IAutomationPolicyGateway _policyGateway;

  @override
  Future<AutomationPolicyDto> handle(UpdateAutomationPolicyCommand command) {
    return _policyGateway.updatePolicy(command);
  }
}
