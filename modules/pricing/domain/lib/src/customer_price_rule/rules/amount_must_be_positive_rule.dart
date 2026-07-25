import 'package:vet45_shared_domain/shared_kernel_domain.dart';

final class AmountMustBePositiveRule implements IBusinessRule {
  const AmountMustBePositiveRule(this.amountMinor);

  final int amountMinor;

  @override
  bool isBroken() => amountMinor < 0;

  @override
  String get message => 'Money amount must be positive.';
}
