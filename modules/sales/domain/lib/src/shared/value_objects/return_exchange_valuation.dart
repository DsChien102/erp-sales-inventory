import 'package:vet45_shared_domain/shared_kernel_domain.dart';

/// Versioned valuation evidence for a return/exchange session.
///
/// Sign convention (Theme 5 / ADR-2 / FC-14):
/// `settlementDifference = exchangeValue - returnValue`
/// (`netDifferenceMinor = exchangeTotal - returnedTotal`).
/// Positive → collect / receivable create; negative → refund / receivable
/// reverse; zero → balanced.
final class ReturnExchangeValuation extends ValueObject {
  ReturnExchangeValuation({
    required this.returnedTotal,
    required this.exchangeTotal,
    required this.netDifferenceMinor,
  }) {
    if (returnedTotal.currencyCode != exchangeTotal.currencyCode) {
      throw DomainException(
        'Return and exchange totals must share the same currency.',
      );
    }
    final expected = exchangeTotal.amountMinor - returnedTotal.amountMinor;
    if (netDifferenceMinor != expected) {
      throw DomainException(
        'Valuation netDifferenceMinor must equal exchangeTotal - returnedTotal.',
      );
    }
  }

  final Money returnedTotal;
  final Money exchangeTotal;

  /// Signed settlement difference in minor units (exchange − return).
  final int netDifferenceMinor;

  String get currencyCode => returnedTotal.currencyCode;

  bool get customerReceivesRefund => netDifferenceMinor < 0;
  bool get customerOwes => netDifferenceMinor > 0;
  bool get isBalanced => netDifferenceMinor == 0;

  @override
  List<Object?> get props => [returnedTotal, exchangeTotal, netDifferenceMinor];
}
