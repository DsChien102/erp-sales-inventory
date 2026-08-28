import 'package:vet45_shared_application/application.dart';

import 'request_invoice_preview_command.dart';

final class RequestInvoicePreviewCommandValidator
    implements ICommandValidator<RequestInvoicePreviewCommand> {
  @override
  Future<void> validate(RequestInvoicePreviewCommand command) async {
    if (command.tenantId.trim().isEmpty) {
      throw ValidationException('tenantId is required');
    }
    if (command.actorId.trim().isEmpty) {
      throw ValidationException('actorId is required');
    }
    if (command.salesOrderId.trim().isEmpty) {
      throw ValidationException('salesOrderId is required');
    }
  }
}
