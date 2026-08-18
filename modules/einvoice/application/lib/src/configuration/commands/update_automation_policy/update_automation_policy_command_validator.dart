import 'package:vet45_shared_application/application.dart';

import 'update_automation_policy_command.dart';

final class UpdateAutomationPolicyCommandValidator
    implements ICommandValidator<UpdateAutomationPolicyCommand> {
  @override
  Future<void> validate(UpdateAutomationPolicyCommand command) async {
    if (command.tenantId.trim().isEmpty) {
      throw ValidationException('tenantId is required');
    }
    if (command.expectedPolicyVersion < 0) {
      throw ValidationException('expectedPolicyVersion must be non-negative');
    }
    if (command.autoIssueEnabled == null && command.autoSendEnabled == null) {
      throw ValidationException(
        'At least one of autoIssueEnabled or autoSendEnabled must be set',
      );
    }
  }
}
