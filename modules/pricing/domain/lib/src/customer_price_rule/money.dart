import 'package:vet45_shared_domain/shared_kernel_domain.dart';

import 'rules/amount_must_be_positive_rule.dart';
import 'rules/currency_code_must_be_explicit_rule.dart';

final class Money extends ValueObject {
  Money({required this.amountMinor, required String currencyCode})
    : currencyCode = currencyCode.trim().toUpperCase() {
    ValueObject.checkRule(AmountMustBePositiveRule(amountMinor));
    ValueObject.checkRule(CurrencyCodeMustBeExplicitRule(this.currencyCode));
  }

  final int amountMinor;
  final String currencyCode;

  @override
  List<Object?> get props => [amountMinor, currencyCode];
}
