import 'package:vet45_shared_application/application.dart';

import '../../../ports/i_delivery_command_gateway.dart';
import '../../shared/manual_delivery_start_request.dart';
import 'send_electronic_invoice_command.dart';
import 'send_electronic_invoice_result.dart';

@CommandHandlerFor(SendElectronicInvoiceCommand)
final class SendElectronicInvoiceCommandHandler
    implements ICommandHandler<SendElectronicInvoiceCommand, SendInvoiceResultDto> {
  SendElectronicInvoiceCommandHandler({
    required IDeliveryCommandGateway gateway,
  }) : _gateway = gateway;

  final IDeliveryCommandGateway _gateway;

  @override
  Future<SendInvoiceResultDto> handle(SendElectronicInvoiceCommand command) {
    return _gateway.startManual(
      ManualDeliveryStartRequest(
        tenantId: command.tenantId,
        actorId: command.actorId,
        salesOrderId: command.salesOrderId,
        recipientEmail: command.recipientEmail,
        idempotencyKey: command.idempotencyKey,
      ),
    );
  }
}
