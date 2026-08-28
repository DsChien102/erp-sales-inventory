import 'package:uuid/uuid.dart';
import 'package:vet45_shared_application/application.dart';

import 'issue_invoice_command.dart';

final class IssueInvoiceCommandValidator implements ICommandValidator<IssueInvoiceCommand> {
  @override
  Future<void> validate(IssueInvoiceCommand command) async {
    if (command.tenantId.trim().isEmpty) {
      throw ValidationException('tenantId is required');
    }
    if (command.actorId.trim().isEmpty) {
      throw ValidationException('actorId is required');
    }
    if (command.salesOrderId.trim().isEmpty) {
      throw ValidationException('salesOrderId is required');
    }
    if (command.sourceVersion.trim().isEmpty) {
      throw ValidationException('sourceVersion is required');
    }
    if (!Uuid.isValidUUID(fromString: command.idempotencyKey)) {
      throw ValidationException('idempotencyKey must be a canonical UUID');
    }
  }
}
