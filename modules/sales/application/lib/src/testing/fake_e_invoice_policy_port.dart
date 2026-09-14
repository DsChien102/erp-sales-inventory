import '../ports/i_e_invoice_policy_port.dart';

final class FakeEInvoicePolicyPort implements IEInvoicePolicyPort {
  const FakeEInvoicePolicyPort({this.requiredByPolicy = false});

  final bool requiredByPolicy;

  @override
  Future<bool> isEInvoiceRequired({
    required String tenantId,
    required String salesOrderId,
  }) async => requiredByPolicy;
}
