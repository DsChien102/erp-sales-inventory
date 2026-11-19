import '../../business_rule.dart';

final class MoneyCurrencyMustMatchRule implements IBusinessRule {
  const MoneyCurrencyMustMatchRule(this.left, this.right);

  final String left;
  final String right;

  @override
  bool isBroken() => left != right;

  @override
  String get message => 'Money operands must share the same currency.';
}
