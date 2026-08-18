import '../configuration/commands/update_automation_policy/update_automation_policy_command.dart';
import '../configuration/queries/get_automation_policy/automation_policy_dto.dart';

/// Automation policy read/write port.
abstract interface class IAutomationPolicyGateway {
  Future<AutomationPolicyDto> getPolicy({
    required String tenantId,
    required String actorId,
  });

  Future<AutomationPolicyDto> updatePolicy(
    UpdateAutomationPolicyCommand command,
  );
}
