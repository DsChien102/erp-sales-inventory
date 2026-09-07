import 'package:vet45_shared_application/application.dart';

import 'request_invoice_document_command.dart';

final class RequestInvoiceDocumentCommandValidator
    implements ICommandValidator<RequestInvoiceDocumentCommand> {
  static const maxIdempotencyKeyLength = 150;

  @override
  Future<void> validate(RequestInvoiceDocumentCommand command) async {
    if (command.tenantId.trim().isEmpty) {
      throw ValidationException('tenantId is required');
    }
    if (command.actorId.trim().isEmpty) {
      throw ValidationException('actorId is required');
    }
    if (command.salesOrderId.trim().isEmpty) {
      throw ValidationException('salesOrderId is required');
    }
    final key = command.idempotencyKey.trim();
    if (key.isEmpty) {
      throw ValidationException('idempotencyKey is required');
    }
    if (key.length > maxIdempotencyKeyLength) {
      throw ValidationException(
        'idempotencyKey must be <= $maxIdempotencyKeyLength characters',
      );
    }
  }
}
