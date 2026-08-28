import 'package:vet45_shared_application/application.dart';

import 'complete_buyer_invoice_data_command.dart';

final class CompleteBuyerInvoiceDataCommandValidator
    implements ICommandValidator<CompleteBuyerInvoiceDataCommand> {
  @override
  Future<void> validate(CompleteBuyerInvoiceDataCommand command) async {
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
