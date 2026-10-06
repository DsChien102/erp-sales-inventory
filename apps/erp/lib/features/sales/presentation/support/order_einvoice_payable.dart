/// Amount shown on the e-invoice issue confirmation sheet.
///
/// The invoice is issued for goods still held after return/exchange, so the
/// sheet must not keep the original sale total once that total has changed.
final class OrderEInvoicePayable {
  const OrderEInvoicePayable._();

  static int minor({
    required int originalTotalMinor,
    int? currentPayableMinor,
    Iterable<int> currentHoldingTotals = const [],
    bool hasReturnOrExchange = false,
  }) {
    if (currentPayableMinor != null) return currentPayableMinor;
    if (hasReturnOrExchange) {
      return currentHoldingTotals.fold<int>(0, (sum, total) => sum + total);
    }
    return originalTotalMinor;
  }
}
