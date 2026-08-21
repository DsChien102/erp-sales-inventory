import '../../business_rule.dart';

final class MoneyAmountMustBeNonNegativeRule implements IBusinessRule {
  const MoneyAmountMustBeNonNegativeRule(this.amountMinor);

  final int amountMinor;

  @override
  bool isBroken() => amountMinor < 0;

  @override
  String get message => 'Money amount must be non-negative.';
}
