import 'package:vet45_einvoice_application/application.dart';

import 'i_einvoice_internal_command_client.dart';
import 'i_einvoice_internal_command_dead_letter_handler.dart';

/// Dead-letters exhausted `einvoice.send_invoice_email` commands.
///
/// Always passes [WORKER_EXHAUSTED_BEFORE_DISPATCH]; SQL classifies QUEUED →
/// FAILED vs SUBMITTED → UNKNOWN + PENDING VERIFY_DELIVERY from delivery status.
final class DeliveryCommandDeadLetterHandler
    implements IEinvoiceInternalCommandDeadLetterHandler {
  const DeliveryCommandDeadLetterHandler({
    required IDeliveryCommandGateway commandGateway,
  }) : _commandGateway = commandGateway;

  static const safeFailureCode = 'WORKER_EXHAUSTED_BEFORE_DISPATCH';

  final IDeliveryCommandGateway _commandGateway;

  @override
  Future<void> handleDeadLetter({
    required String tenantId,
    required ClaimedInternalCommand command,
    required Object error,
  }) async {
    final payload = DeliveryCommandPayload.fromJson({
      if (!command.payload.containsKey('tenant_id') &&
          !command.payload.containsKey('tenantId'))
        'tenant_id': tenantId,
      ...command.payload,
    });
    if (payload.tenantId != tenantId) {
      throw const FormatException(
        'Delivery tenant does not match claimed tenant',
      );
    }

    await _commandGateway.recordCommandDeadLetter(
      tenantId: tenantId,
      deliveryId: payload.deliveryId,
      retryCount: payload.retryCount,
      safeFailureCode: safeFailureCode,
    );
  }
}
