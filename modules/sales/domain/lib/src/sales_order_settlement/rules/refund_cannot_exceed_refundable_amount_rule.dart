import 'package:vet45_shared_domain/shared_kernel_domain.dart';

final class RefundCannotExceedRefundableAmountRule implements IBusinessRule {
  const RefundCannotExceedRefundableAmountRule({
    required this.refundAmount,
    required this.refundableAmount,
  });

  final Money refundAmount;
  final Money refundableAmount;

  @override
  bool isBroken() => refundAmount.amountMinor > refundableAmount.amountMinor;

  @override
  String get message => 'Refund cannot exceed refundable collected amount.';
}
