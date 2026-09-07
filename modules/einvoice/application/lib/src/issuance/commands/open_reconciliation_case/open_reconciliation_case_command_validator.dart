import 'package:vet45_shared_application/application.dart';

import 'open_reconciliation_case_command.dart';

final class OpenReconciliationCaseCommandValidator
    implements ICommandValidator<OpenReconciliationCaseCommand> {
  @override
  Future<void> validate(OpenReconciliationCaseCommand command) async {
    if (command.tenantId.trim().isEmpty) {
      throw ValidationException('tenantId is required');
    }
    if (command.attemptId.trim().isEmpty) {
      throw ValidationException('attemptId is required');
    }
    if (command.reason.trim().isEmpty) {
      throw ValidationException('reason is required');
    }
  }
}
