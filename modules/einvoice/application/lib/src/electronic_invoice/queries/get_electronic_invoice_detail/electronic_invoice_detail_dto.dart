final class ElectronicInvoiceDetailDto {
  const ElectronicInvoiceDetailDto({
    required this.electronicInvoiceId,
    required this.salesOrderId,
    this.invoiceNumber,
    this.providerRef,
    this.issuedAt,
  });

  final String electronicInvoiceId;
  final String salesOrderId;
  final String? invoiceNumber;
  final String? providerRef;
  final DateTime? issuedAt;
}
