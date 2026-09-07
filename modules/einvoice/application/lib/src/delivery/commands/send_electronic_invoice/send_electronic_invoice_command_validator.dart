import 'package:uuid/uuid.dart';
import 'package:vet45_einvoice_domain/domain.dart';
import 'package:vet45_shared_application/application.dart';
import 'package:vet45_shared_domain/shared_kernel_domain.dart';

import 'send_electronic_invoice_command.dart';

final class SendElectronicInvoiceCommandValidator
    implements ICommandValidator<SendElectronicInvoiceCommand> {
  @override
  Future<void> validate(SendElectronicInvoiceCommand command) async {
    if (command.tenantId.trim().isEmpty) {
      throw ValidationException('tenantId is required');
    }
    if (command.actorId.trim().isEmpty) {
      throw ValidationException('actorId is required');
    }
    if (command.salesOrderId.trim().isEmpty) {
      throw ValidationException('salesOrderId is required');
    }
    try {
      DeliveryRecipientEmail(command.recipientEmail);
    } on BusinessRuleValidationException catch (error) {
      throw ValidationException(error.details);
    }
    if (!Uuid.isValidUUID(fromString: command.idempotencyKey)) {
      throw ValidationException('idempotencyKey must be a canonical UUID');
    }
  }
}
