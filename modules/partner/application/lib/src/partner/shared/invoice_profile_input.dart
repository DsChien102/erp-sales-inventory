/// Invoice fields shared by person and organization profiles.
final class InvoiceProfileInput {
  const InvoiceProfileInput({
    this.invoiceName,
    this.invoiceAddress,
    this.invoiceEmail,
  });

  final String? invoiceName;
  final String? invoiceAddress;
  final String? invoiceEmail;
}
