import 'package:vet45_shared_domain/shared_kernel_domain.dart';

import '../value_objects/monetary_summary.dart';

final class CommercialSnapshotMustBalanceRule implements IBusinessRule {
  const CommercialSnapshotMustBalanceRule(this.summary);

  final MonetarySummary summary;

  @override
  bool isBroken() {
    final expectedMinor =
        summary.subtotal.amountMinor -
        summary.discountTotal.amountMinor +
        summary.taxTotal.amountMinor +
        summary.rounding.amountMinor;
    return expectedMinor != summary.grandTotal.amountMinor;
  }

  @override
  String get message =>
      'Commercial snapshot totals must balance (lines − discount + tax + rounding).';
}
