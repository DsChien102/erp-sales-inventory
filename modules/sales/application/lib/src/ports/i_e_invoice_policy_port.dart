abstract interface class IEInvoicePolicyPort {
  Future<bool> isEInvoiceRequired({
    required String tenantId,
    required String salesOrderId,
  });
}
