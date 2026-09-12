import 'package:vet45_shared_domain/shared_kernel_domain.dart';

final class PaymentAmountMustBePositiveRule implements IBusinessRule {
  const PaymentAmountMustBePositiveRule(this.amount);

  final Money amount;

  @override
  bool isBroken() => amount.amountMinor <= 0;

  @override
  String get message => 'Payment amount must be greater than zero.';
}
