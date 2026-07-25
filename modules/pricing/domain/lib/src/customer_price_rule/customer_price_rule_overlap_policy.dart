import 'customer_price_rule.dart';
import 'customer_price_rule_status.dart';

/// Closed-interval overlap policy for active, non-deleted customer price rules.
abstract final class CustomerPriceRuleOverlapPolicy {
  static bool conflicts({
    required CustomerPriceRule candidate,
    required CustomerPriceRule existing,
    String? excludeRuleId,
  }) {
    if (excludeRuleId != null && existing.id == excludeRuleId) {
      return false;
    }
    if (!_isOverlapCandidate(existing)) {
      return false;
    }
    if (candidate.key != existing.key) {
      return false;
    }
    return candidate.effectivePeriod.overlaps(existing.effectivePeriod);
  }

  static List<CustomerPriceRule> findConflicts({
    required CustomerPriceRule candidate,
    required Iterable<CustomerPriceRule> existingRules,
    String? excludeRuleId,
  }) =>
      existingRules
          .where(
            (existing) => conflicts(
              candidate: candidate,
              existing: existing,
              excludeRuleId: excludeRuleId,
            ),
          )
          .toList(growable: false);

  static bool _isOverlapCandidate(CustomerPriceRule rule) =>
      rule.status == CustomerPriceRuleStatus.active && rule.deletedAt == null;
}
