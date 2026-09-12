import 'package:vet45_shared_domain/shared_kernel_domain.dart';

import 'value_objects/return_exchange_valuation.dart';

final class ReturnExchangeValuationCalculator {
  const ReturnExchangeValuationCalculator();

  ReturnExchangeValuation calculate({
    required Money returnedTotal,
    required Money exchangeTotal,
  }) {
    final rule = _SameCurrencyRule(
      returnedTotal.currencyCode,
      exchangeTotal.currencyCode,
    );
    if (rule.isBroken()) {
      throw BusinessRuleValidationException(rule);
    }
    return ReturnExchangeValuation(
      returnedTotal: returnedTotal,
      exchangeTotal: exchangeTotal,
      netDifferenceMinor: exchangeTotal.amountMinor - returnedTotal.amountMinor,
    );
  }
}

final class _SameCurrencyRule implements IBusinessRule {
  const _SameCurrencyRule(this.left, this.right);

  final String left;
  final String right;

  @override
  bool isBroken() => left != right;

  @override
  String get message => 'Return and exchange totals must share the same currency.';
}
