import 'package:vet45_shared_domain/shared_kernel_domain.dart';

import 'value_objects/monetary_summary.dart';

/// Integer-money totals: grandTotal = subtotal − discount + tax + rounding.
final class OrderTotalsCalculator {
  const OrderTotalsCalculator();

  MonetarySummary calculate({
    required List<Money> lineTotals,
    required Money discountTotal,
    required Money taxTotal,
    required Money rounding,
  }) {
    final currency = lineTotals.isEmpty
        ? discountTotal.currencyCode
        : lineTotals.first.currencyCode;
    var subtotalMinor = 0;
    for (final line in lineTotals) {
      subtotalMinor += line.amountMinor;
    }
    final grandMinor =
        subtotalMinor - discountTotal.amountMinor + taxTotal.amountMinor + rounding.amountMinor;
    return MonetarySummary(
      subtotal: Money(amountMinor: subtotalMinor, currencyCode: currency),
      discountTotal: discountTotal,
      taxTotal: taxTotal,
      rounding: rounding,
      grandTotal: Money(
        amountMinor: grandMinor < 0 ? 0 : grandMinor,
        currencyCode: currency,
      ),
    );
  }

  bool balances(MonetarySummary summary) {
    final expectedMinor =
        summary.subtotal.amountMinor -
        summary.discountTotal.amountMinor +
        summary.taxTotal.amountMinor +
        summary.rounding.amountMinor;
    return expectedMinor == summary.grandTotal.amountMinor;
  }
}
