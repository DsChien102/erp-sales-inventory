import 'package:vet45_shared_application/application.dart';

import 'poll_issuance_status_command.dart';

final class PollIssuanceStatusCommandValidator
    implements ICommandValidator<PollIssuanceStatusCommand> {
  @override
  Future<void> validate(PollIssuanceStatusCommand command) async {
    if (command.tenantId.trim().isEmpty) {
      throw ValidationException('tenant_id cannot be empty');
    }
    if (command.caseId.trim().isEmpty) {
      throw ValidationException('case_id cannot be empty');
    }
    if (command.attemptId.trim().isEmpty) {
      throw ValidationException('attempt_id cannot be empty');
    }
    if (command.correlationId.trim().isEmpty) {
      throw ValidationException('correlation_id cannot be empty');
    }
    if (command.checkOrdinal < 1) {
      throw ValidationException('check_ordinal must be >= 1');
    }
  }
}
