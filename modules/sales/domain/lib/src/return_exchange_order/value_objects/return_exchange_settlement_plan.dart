import 'package:vet45_shared_domain/shared_kernel_domain.dart';

import '../rules/return_exchange_settlement_plan_must_balance_rule.dart';

/// Balanced allocation of a signed return/exchange settlement difference.
///
/// Sign convention (Theme 5 / ADR-2): `settlementDifference = exchangeValue - returnValue`.
/// Positive → collect / receivable create; negative → refund / receivable reverse;
/// zero → no settlement cash or receivable movement.
final class ReturnExchangeSettlementPlan extends ValueObject {
  ReturnExchangeSettlementPlan._({
    required this.netDifferenceMinor,
    required this.currencyCode,
    required this.collectAmount,
    required this.refundAmount,
    required this.receivableCreateAmount,
    required this.receivableReverseAmount,
  });

  factory ReturnExchangeSettlementPlan.create({
    required int netDifferenceMinor,
    required String currencyCode,
    required Money collectAmount,
    required Money refundAmount,
    required Money receivableCreateAmount,
    required Money receivableReverseAmount,
  }) {
    final normalizedCurrency = currencyCode.trim().toUpperCase();
    final plan = ReturnExchangeSettlementPlan._(
      netDifferenceMinor: netDifferenceMinor,
      currencyCode: normalizedCurrency,
      collectAmount: collectAmount,
      refundAmount: refundAmount,
      receivableCreateAmount: receivableCreateAmount,
      receivableReverseAmount: receivableReverseAmount,
    );
    final rule = ReturnExchangeSettlementPlanMustBalanceRule(plan);
    if (rule.isBroken()) throw BusinessRuleValidationException(rule);
    return plan;
  }

  /// Signed difference mirrored from [ReturnExchangeValuation.netDifferenceMinor].
  final int netDifferenceMinor;
  final String currencyCode;
  final Money collectAmount;
  final Money refundAmount;
  final Money receivableCreateAmount;
  final Money receivableReverseAmount;

  bool get isBalanced => netDifferenceMinor == 0;

  @override
  List<Object?> get props => <Object?>[
    netDifferenceMinor,
    currencyCode,
    collectAmount,
    refundAmount,
    receivableCreateAmount,
    receivableReverseAmount,
  ];
}
