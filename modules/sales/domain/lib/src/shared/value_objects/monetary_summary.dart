import 'package:vet45_shared_domain/shared_kernel_domain.dart';

/// Immutable commercial totals for a draft/order/checkout snapshot.
final class MonetarySummary extends ValueObject {
  MonetarySummary({
    required this.subtotal,
    required this.discountTotal,
    required this.taxTotal,
    required this.rounding,
    required this.grandTotal,
  });

  final Money subtotal;
  final Money discountTotal;
  final Money taxTotal;
  final Money rounding;
  final Money grandTotal;

  String get currencyCode => grandTotal.currencyCode;

  @override
  List<Object?> get props => [
    subtotal,
    discountTotal,
    taxTotal,
    rounding,
    grandTotal,
  ];
}
