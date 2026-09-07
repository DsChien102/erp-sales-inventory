import 'package:vet45_einvoice_domain/domain.dart';

final class InvoiceDocumentOperationContextDto {
  const InvoiceDocumentOperationContextDto({
    required this.operationId,
    required this.tenantId,
    required this.electronicInvoiceId,
    required this.documentType,
    required this.generation,
    required this.attemptOrdinal,
    required this.documentVersion,
    required this.status,
    required this.providerConnectionId,
    required this.providerInvoiceReference,
    required this.invoiceSeries,
    required this.expectedVersion,
    this.invoiceDocumentId,
  });

  final String operationId;
  final String tenantId;
  final String electronicInvoiceId;
  final InvoiceDocumentType documentType;
  final int generation;
  final int attemptOrdinal;
  final int documentVersion;
  final InvoiceDocumentStatus status;
  final String providerConnectionId;
  final String providerInvoiceReference;
  final String invoiceSeries;
  final int expectedVersion;
  final String? invoiceDocumentId;
}
