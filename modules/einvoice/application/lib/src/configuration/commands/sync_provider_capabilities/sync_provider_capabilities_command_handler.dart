import 'package:vet45_einvoice_domain/domain.dart';
import 'package:vet45_shared_application/application.dart';

import '../../../exceptions/provider_unavailable_exception.dart';
import '../../../ports/i_me_invoice_provider_port.dart';
import '../../../ports/i_provider_connection_command_gateway.dart';
import '../record_connection_verified/record_connection_verified_command.dart';
import 'sync_provider_capabilities_command.dart';

@CommandHandlerFor(SyncProviderCapabilitiesCommand)
final class SyncProviderCapabilitiesCommandHandler
    implements ICommandHandler<SyncProviderCapabilitiesCommand, void> {
  SyncProviderCapabilitiesCommandHandler({
    required IMeInvoiceProviderPort meInvoiceProviderPort,
    required IProviderConnectionCommandGateway commandGateway,
  }) : _meInvoiceProviderPort = meInvoiceProviderPort,
       _commandGateway = commandGateway;

  final IMeInvoiceProviderPort _meInvoiceProviderPort;
  final IProviderConnectionCommandGateway _commandGateway;

  @override
  Future<void> handle(SyncProviderCapabilitiesCommand command) async {
    final outcome = await _meInvoiceProviderPort.authenticateAndListTemplates(
      tenantId: command.tenantId,
      connectionId: command.connectionId,
    );

    if (outcome.providerUnavailable) {
      throw const ProviderUnavailableException();
    }

    if (outcome.authFailed) {
      await _commandGateway.recordConnectionVerified(
        RecordConnectionVerifiedCommand(
          tenantId: command.tenantId,
          connectionId: command.connectionId,
          expectedConnectionVersion: command.expectedConnectionVersion,
          status: ProviderConnectionStatus.reconnectRequired,
          correlationId: command.correlationId,
        ),
      );
      return;
    }

    final now = DateTime.now().toUtc();
    await _commandGateway.recordConnectionVerified(
      RecordConnectionVerifiedCommand(
        tenantId: command.tenantId,
        connectionId: command.connectionId,
        expectedConnectionVersion: command.expectedConnectionVersion,
        status: ProviderConnectionStatus.connected,
        capabilities: ProviderCapabilitiesSnapshot(
          supportsEmailDelivery: outcome.supportsEmailDelivery,
          supportedDocumentTypes: outcome.supportedDocumentTypes,
          supportsPreview: outcome.supportsPreview,
          // Current MISA has no delivery-result observation API.
          supportsDeliveryResultObservation: false,
          templateCount: outcome.templateCount,
          templates: outcome.templates,
          syncedAt: now,
        ),
        verifiedAt: now,
        correlationId: command.correlationId,
      ),
    );
  }
}
