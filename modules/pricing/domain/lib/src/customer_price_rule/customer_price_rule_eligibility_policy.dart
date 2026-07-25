import 'customer_price_rule.dart';
import 'customer_price_rule_status.dart';
import 'rule_validation_state.dart';

/// Decides whether a persisted rule may apply on a business date (BR-08).
abstract final class CustomerPriceRuleEligibilityPolicy {
  static bool isApplicable(
    CustomerPriceRule rule,
    DateTime businessDate,
  ) {
    if (rule.status != CustomerPriceRuleStatus.active) {
      return false;
    }
    if (rule.deletedAt != null) {
      return false;
    }
    if (rule.validationOutcome.outcome == RuleValidationState.blocked) {
      return false;
    }
    if (rule.validationOutcome.blockingCodes.isNotEmpty) {
      return false;
    }

    final day = DateTime.utc(
      businessDate.year,
      businessDate.month,
      businessDate.day,
    );
    final from = rule.effectivePeriod.effectiveFrom;
    final to = rule.effectivePeriod.effectiveTo;
    if (day.isBefore(from)) {
      return false;
    }
    if (to != null && day.isAfter(to)) {
      return false;
    }
    return true;
  }
}
