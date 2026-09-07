import 'package:vet45_einvoice_domain/domain.dart';

final class OfficialViewOperationContextDto {
  const OfficialViewOperationContextDto({
    required this.operationId,
    required this.tenantId,
    required this.electronicInvoiceId,
    required this.generation,
    required this.attemptOrdinal,
    required this.status,
    required this.providerConnectionId,
    required this.providerInvoiceReference,
    required this.invoiceSeries,
    required this.expectedVersion,
  });

  final String operationId;
  final String tenantId;
  final String electronicInvoiceId;
  final int generation;
  final int attemptOrdinal;
  final InvoiceDocumentStatus status;
  final String providerConnectionId;
  final String providerInvoiceReference;
  final String invoiceSeries;
  final int expectedVersion;
}
