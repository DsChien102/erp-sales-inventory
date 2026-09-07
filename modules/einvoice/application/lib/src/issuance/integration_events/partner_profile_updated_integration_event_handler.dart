import 'package:vet45_einvoice_integration_events/integration_events.dart';
import 'package:vet45_partner_integration_events/integration_events.dart';

import '../../ports/i_auto_issuance_gateway.dart';
import '../../ports/i_einvoice_command_dispatcher.dart';
import '../commands/reevaluate_auto_issuance/reevaluate_auto_issuance_command.dart';

final class PartnerProfileUpdatedIntegrationEventHandler
    implements IIntegrationEventNotificationHandler<PartnerProfileUpdatedIntegrationEvent> {
  PartnerProfileUpdatedIntegrationEventHandler({
    required IAutoIssuanceGateway gateway,
    required IEinvoiceCommandDispatcher commands,
  }) : _gateway = gateway,
       _commands = commands;

  final IAutoIssuanceGateway _gateway;
  final IEinvoiceCommandDispatcher _commands;

  @override
  Future<void> handle(PartnerProfileUpdatedIntegrationEvent event) async {
    final openProcesses = await _gateway.listOpenProcesses(
      tenantId: event.tenantId,
      partnerId: event.partnerId,
    );

    for (final process in openProcesses) {
      await _commands.execute(
        ReevaluateAutoIssuanceCommand(
          tenantId: event.tenantId,
          processId: process.processId,
          sourceEventId: event.id,
        ),
      );
    }
  }
}
