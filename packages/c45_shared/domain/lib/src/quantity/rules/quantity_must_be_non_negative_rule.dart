import '../../business_rule.dart';

final class QuantityMustBeNonNegativeRule implements IBusinessRule {
  const QuantityMustBeNonNegativeRule(this.quantityMicros);

  final int quantityMicros;

  @override
  bool isBroken() => quantityMicros < 0;

  @override
  String get message => 'Quantity must be non-negative.';
}
