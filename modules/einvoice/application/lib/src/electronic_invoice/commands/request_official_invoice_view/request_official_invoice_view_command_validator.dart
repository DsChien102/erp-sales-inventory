import 'package:vet45_shared_application/application.dart';

import 'request_official_invoice_view_command.dart';

final class RequestOfficialInvoiceViewCommandValidator
    implements ICommandValidator<RequestOfficialInvoiceViewCommand> {
  @override
  Future<void> validate(RequestOfficialInvoiceViewCommand command) async {
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
