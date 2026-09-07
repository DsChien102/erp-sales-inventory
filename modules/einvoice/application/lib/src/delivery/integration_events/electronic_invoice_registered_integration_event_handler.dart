import 'package:vet45_einvoice_integration_events/integration_events.dart';

import '../../ports/i_einvoice_command_dispatcher.dart';
import '../commands/start_auto_delivery/start_auto_delivery_command.dart';
import '../shared/auto_delivery_idempotency_key.dart';

final class ElectronicInvoiceRegisteredIntegrationEventHandler
    implements IIntegrationEventNotificationHandler<ElectronicInvoiceRegisteredIntegrationEvent> {
  ElectronicInvoiceRegisteredIntegrationEventHandler({
    required IEinvoiceCommandDispatcher commands,
  }) : _commands = commands;

  final IEinvoiceCommandDispatcher _commands;

  @override
  Future<void> handle(ElectronicInvoiceRegisteredIntegrationEvent event) async {
    final idempotencyKey = AutoDeliveryIdempotencyKey.generate(
      tenantId: event.tenantId,
      electronicInvoiceId: event.electronicInvoiceId,
    );

    await _commands.execute(
      StartAutoDeliveryCommand(
        tenantId: event.tenantId,
        electronicInvoiceId: event.electronicInvoiceId,
        triggerId: event.id,
        idempotencyKey: idempotencyKey,
      ),
    );
  }
}
