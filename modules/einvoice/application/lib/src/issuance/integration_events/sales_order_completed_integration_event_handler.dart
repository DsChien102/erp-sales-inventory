import 'package:vet45_einvoice_integration_events/integration_events.dart';
import 'package:vet45_sales_integration_events/integration_events.dart';

import '../../ports/i_einvoice_command_dispatcher.dart';
import '../commands/start_auto_issuance/start_auto_issuance_command.dart';
import '../shared/auto_issuance_idempotency_key.dart';

final class SalesOrderCompletedIntegrationEventHandler
    implements IIntegrationEventNotificationHandler<SalesOrderCompletedIntegrationEvent> {
  SalesOrderCompletedIntegrationEventHandler({
    required IEinvoiceCommandDispatcher commands,
  }) : _commands = commands;

  final IEinvoiceCommandDispatcher _commands;

  @override
  Future<void> handle(SalesOrderCompletedIntegrationEvent event) async {
    final triggerKey = AutoIssuanceIdempotencyKey.triggerKey(
      eventId: event.id,
      salesOrderId: event.salesOrderId,
      sourceVersion: event.sourceVersion,
    );
    final idempotencyKey = AutoIssuanceIdempotencyKey.generate(
      tenantId: event.tenantId,
      salesOrderId: event.salesOrderId,
      sourceVersion: event.sourceVersion,
    );

    await _commands.execute(
      StartAutoIssuanceCommand(
        tenantId: event.tenantId,
        salesOrderId: event.salesOrderId,
        triggerKey: triggerKey,
        idempotencyKey: idempotencyKey,
      ),
    );
  }
}
