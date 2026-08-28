/// Allow-listed provider fields safe for persistence, logs, and audit.
final class MeInvoiceSafeProviderEvidence {
  const MeInvoiceSafeProviderEvidence({
    this.refId,
    this.transactionId,
    this.invoiceNumber,
    this.invoiceSeries,
    this.providerCode,
    this.providerMessage,
  });

  final String? refId;
  final String? transactionId;
  final String? invoiceNumber;
  final String? invoiceSeries;
  final String? providerCode;
  final String? providerMessage;
}
