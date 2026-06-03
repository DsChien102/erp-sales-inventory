import 'package:vet45_shared_domain/shared_kernel_domain.dart';

class AmountMustBePositiveRule implements IBusinessRule {
  final int amount;
  const AmountMustBePositiveRule(this.amount);
  @override
  bool isBroken() => amount < 0;
  @override
  String get message => 'Amount must be positive';
}

class Money extends ValueObject {
  final int amount;

  Money(this.amount) {
    ValueObject.checkRule(AmountMustBePositiveRule(amount));
  }

  static Money get zero => Money(0);

  static Money min(Money a, Money b) => a < b ? a : b;

  Money get abs => Money(amount.abs());

  Money operator +(Money other) => Money(amount + other.amount);
  Money operator -(Money other) => Money(amount - other.amount);

  bool operator >(Money other) => amount > other.amount;
  bool operator >=(Money other) => amount >= other.amount;
  bool operator <(Money other) => amount < other.amount;
  bool operator <=(Money other) => amount <= other.amount;

  @override
  bool operator ==(Object other) => other is Money && amount == other.amount;

  bool get isZero => amount == 0;
  bool get isNotZero => amount != 0;

  @override
  int get hashCode => amount.hashCode;

  @override
  String toString() => 'Money($amount)';

  @override
  List<Object?> get props => [amount];
}
