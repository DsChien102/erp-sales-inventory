/// Summary electronic invoice returned after registration or recovery.
final class ElectronicInvoiceDto {
  const ElectronicInvoiceDto({
    required this.electronicInvoiceId,
    required this.salesOrderId,
    this.providerInvoiceRef,
    this.invoiceNumber,
  });

  final String electronicInvoiceId;
  final String salesOrderId;
  final String? providerInvoiceRef;
  final String? invoiceNumber;
}
