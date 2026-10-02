import 'package:vet45_einvoice_domain/domain.dart';

final class ElectronicInvoiceDetailDto {
  const ElectronicInvoiceDetailDto({
    required this.electronicInvoiceId,
    required this.salesOrderId,
    this.invoiceNumber,
    this.providerRef,
    this.issuedAt,
    this.officialViewOperationId,
    this.officialViewStatus,
    this.officialViewerUrl,
    this.officialViewerToken,
    this.officialViewerExpiresAt,
    this.officialViewFailureCode,
  });

  final String electronicInvoiceId;
  final String salesOrderId;
  final String? invoiceNumber;
  final String? providerRef;
  final DateTime? issuedAt;
  final String? officialViewOperationId;
  final InvoiceDocumentStatus? officialViewStatus;
  final String? officialViewerUrl;
  final String? officialViewerToken;
  final DateTime? officialViewerExpiresAt;
  final String? officialViewFailureCode;
}
