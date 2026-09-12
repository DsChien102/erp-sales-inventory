import 'package:vet45_shared_domain/shared_kernel_domain.dart';

import '../value_objects/return_exchange_settlement_plan.dart';

final class ReturnExchangeSettlementPlanMustBalanceRule implements IBusinessRule {
  const ReturnExchangeSettlementPlanMustBalanceRule(this.plan);

  final ReturnExchangeSettlementPlan plan;

  @override
  bool isBroken() {
    final components = <Money>[
      plan.collectAmount,
      plan.refundAmount,
      plan.receivableCreateAmount,
      plan.receivableReverseAmount,
    ];
    if (components.any((money) => money.currencyCode != plan.currencyCode)) {
      return true;
    }
    if (components.any((money) => money.amountMinor < 0)) {
      return true;
    }

    final collect = plan.collectAmount.amountMinor;
    final refund = plan.refundAmount.amountMinor;
    final create = plan.receivableCreateAmount.amountMinor;
    final reverse = plan.receivableReverseAmount.amountMinor;
    final net = plan.netDifferenceMinor;

    // ADR-2: positive net (exchange > return) → collect / receivable create.
    if (net > 0) {
      return refund != 0 || reverse != 0 || collect + create != net;
    }
    // Negative net (return > exchange) → refund / receivable reverse.
    if (net < 0) {
      return collect != 0 || create != 0 || refund + reverse != -net;
    }
    return collect != 0 || refund != 0 || create != 0 || reverse != 0;
  }

  @override
  String get message =>
      'Settlement plan components must balance the signed return/exchange difference '
      '(settlementDifference = exchangeValue - returnValue).';
}
