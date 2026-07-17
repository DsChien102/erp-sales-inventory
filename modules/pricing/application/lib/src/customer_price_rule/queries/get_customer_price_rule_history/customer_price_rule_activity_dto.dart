import 'package:vet45_pricing_domain/domain.dart';

import 'customer_price_rule_activity_actor_dto.dart';
import 'customer_price_rule_activity_source_trace_dto.dart';
import 'customer_price_rule_activity_type.dart';

final class CustomerPriceRuleActivityDto {
  const CustomerPriceRuleActivityDto({
    required this.id,
    required this.activityType,
    required this.actor,
    required this.sourceType,
    required this.oldValue,
    required this.newValue,
    required this.reason,
    required this.sourceTrace,
    required this.sensitiveValuesHidden,
    required this.createdAt,
  });

  final String id;
  final CustomerPriceRuleActivityType activityType;
  final CustomerPriceRuleActivityActorDto actor;
  final CustomerPriceRuleSourceType sourceType;
  final Map<String, Object?>? oldValue;
  final Map<String, Object?> newValue;
  final String? reason;
  final CustomerPriceRuleActivitySourceTraceDto sourceTrace;
  final bool sensitiveValuesHidden;
  final DateTime createdAt;
}
