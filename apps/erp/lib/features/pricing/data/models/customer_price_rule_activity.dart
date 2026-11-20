import 'pricing_enums.dart';

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

final class CustomerPriceRuleActivityActorDto {
  const CustomerPriceRuleActivityActorDto({
    required this.displayName,
    required this.isSystemActor,
    this.actorId,
  });

  final String? actorId;
  final String displayName;
  final bool isSystemActor;
}

final class CustomerPriceRuleActivitySourceTraceDto {
  const CustomerPriceRuleActivitySourceTraceDto({
    this.importId,
    this.importRowId,
    this.orderId,
    this.orderLineId,
    this.memoryRequestId,
    this.soldAt,
  });

  final String? importId;
  final String? importRowId;
  final String? orderId;
  final String? orderLineId;
  final String? memoryRequestId;
  final DateTime? soldAt;
}

