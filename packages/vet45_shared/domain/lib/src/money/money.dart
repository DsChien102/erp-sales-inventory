import '../value_object.dart';
import 'rules/currency_code_must_be_explicit_rule.dart';
import 'rules/money_amount_must_be_non_negative_rule.dart';
import 'rules/money_currency_must_match_rule.dart';

/// Integer minor-unit money with an explicit ISO-4217-style currency code.
final class Money extends ValueObject {
  Money({required this.amountMinor, required String currencyCode})
    : currencyCode = currencyCode.trim().toUpperCase() {
    ValueObject.checkRule(MoneyAmountMustBeNonNegativeRule(amountMinor));
    ValueObject.checkRule(CurrencyCodeMustBeExplicitRule(this.currencyCode));
  }

  final int amountMinor;
  final String currencyCode;

  static Money zero(String currencyCode) =>
      Money(amountMinor: 0, currencyCode: currencyCode);

  bool get isZero => amountMinor == 0;
  bool get isNotZero => amountMinor != 0;

  Money operator +(Money other) {
    ValueObject.checkRule(
      MoneyCurrencyMustMatchRule(currencyCode, other.currencyCode),
    );
    return Money(
      amountMinor: amountMinor + other.amountMinor,
      currencyCode: currencyCode,
    );
  }

  Money operator -(Money other) {
    ValueObject.checkRule(
      MoneyCurrencyMustMatchRule(currencyCode, other.currencyCode),
    );
    return Money(
      amountMinor: amountMinor - other.amountMinor,
      currencyCode: currencyCode,
    );
  }

  bool operator >(Money other) {
    ValueObject.checkRule(
      MoneyCurrencyMustMatchRule(currencyCode, other.currencyCode),
    );
    return amountMinor > other.amountMinor;
  }

  bool operator >=(Money other) {
    ValueObject.checkRule(
      MoneyCurrencyMustMatchRule(currencyCode, other.currencyCode),
    );
    return amountMinor >= other.amountMinor;
  }

  bool operator <(Money other) {
    ValueObject.checkRule(
      MoneyCurrencyMustMatchRule(currencyCode, other.currencyCode),
    );
    return amountMinor < other.amountMinor;
  }

  bool operator <=(Money other) {
    ValueObject.checkRule(
      MoneyCurrencyMustMatchRule(currencyCode, other.currencyCode),
    );
    return amountMinor <= other.amountMinor;
  }

  @override
  List<Object?> get props => [amountMinor, currencyCode];

  @override
  String toString() => 'Money($amountMinor $currencyCode)';
}
