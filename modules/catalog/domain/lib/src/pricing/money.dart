import 'package:vet45_shared_domain/shared_kernel_domain.dart';

/// Non-negative money amount in integer minor units (VND: 1 unit = 1 đồng).
final class AmountMustBeNonNegativeRule implements IBusinessRule {
  const AmountMustBeNonNegativeRule(this.amount);

  final int amount;

  @override
  bool isBroken() => amount < 0;

  @override
  String get message => 'Amount must be non-negative';
}

final class Money extends ValueObject {
  Money(this.amount) {
    ValueObject.checkRule(AmountMustBeNonNegativeRule(amount));
  }

  final int amount;

  static Money get zero => Money(0);

  static Money min(Money a, Money b) => a < b ? a : b;

  Money get abs => Money(amount.abs());

  Money operator +(Money other) => Money(amount + other.amount);

  Money operator -(Money other) => Money(amount - other.amount);

  bool operator >(Money other) => amount > other.amount;

  bool operator >=(Money other) => amount >= other.amount;

  bool operator <(Money other) => amount < other.amount;

  bool operator <=(Money other) => amount <= other.amount;

  bool get isZero => amount == 0;

  bool get isNotZero => amount != 0;

  @override
  List<Object?> get props => [amount];

  @override
  String toString() => 'Money($amount)';
}
