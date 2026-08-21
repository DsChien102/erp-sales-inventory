import '../../business_rule.dart';

final class CurrencyCodeMustBeExplicitRule implements IBusinessRule {
  const CurrencyCodeMustBeExplicitRule(this.currencyCode);

  final String currencyCode;

  @override
  bool isBroken() => !RegExp(r'^[A-Z]{3}$').hasMatch(currencyCode);

  @override
  String get message => 'Currency code must contain three ASCII letters.';
}
