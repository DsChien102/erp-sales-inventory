import 'package:vet45_einvoice_domain/domain.dart';

final class OfficialViewOperationContextDto {
  const OfficialViewOperationContextDto({
    required this.tenantId,
    required this.electronicInvoiceId,
    required this.requestId,
    required this.status,
    required this.providerConnectionId,
    required this.providerInvoiceReference,
    required this.invoiceSeries,
  });

  final String tenantId;
  final String electronicInvoiceId;
  final String requestId;
  final InvoiceDocumentStatus status;
  final String providerConnectionId;
  final String providerInvoiceReference;
  final String invoiceSeries;
}
