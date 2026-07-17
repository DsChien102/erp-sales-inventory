import 'package:vet45_shared_domain/shared_kernel_domain.dart';

final class CurrencyCodeMustBeExplicitRule implements IBusinessRule {
  const CurrencyCodeMustBeExplicitRule(this.currencyCode);

  final String currencyCode;

  @override
  bool isBroken() => !RegExp(r'^[A-Z]{3}$').hasMatch(currencyCode);

  @override
  String get message => 'Currency code must contain three ASCII letters.';
}
