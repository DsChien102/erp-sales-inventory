import 'package:vet45_einvoice_domain/domain.dart';

/// Worker-safe provider context — no credentials or raw payloads.
final class ElectronicInvoiceProviderContextDto {
  const ElectronicInvoiceProviderContextDto({
    required this.tenantId,
    required this.providerConnectionId,
    required this.electronicInvoiceId,
    required this.providerInvoiceReference,
    required this.invoiceSeries,
    required this.operationId,
    this.operationGeneration,
    this.documentType,
    this.documentVersion,
  });

  final String tenantId;
  final String providerConnectionId;
  final String electronicInvoiceId;
  final String providerInvoiceReference;
  final String invoiceSeries;
  final String operationId;
  final int? operationGeneration;
  final InvoiceDocumentType? documentType;
  final int? documentVersion;
}
