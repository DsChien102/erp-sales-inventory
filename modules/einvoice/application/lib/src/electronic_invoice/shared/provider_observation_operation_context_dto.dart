/// Worker context for a claimed `einvoice.poll_provider_observation` command.
final class ProviderObservationOperationContextDto {
  const ProviderObservationOperationContextDto({
    required this.commandId,
    required this.tenantId,
    required this.electronicInvoiceId,
    required this.providerConnectionId,
    required this.providerInvoiceReference,
    required this.invoiceSeries,
    required this.triggerId,
    required this.correlationId,
  });

  final String commandId;
  final String tenantId;
  final String electronicInvoiceId;
  final String providerConnectionId;
  final String providerInvoiceReference;
  final String invoiceSeries;
  final String triggerId;
  final String correlationId;
}
