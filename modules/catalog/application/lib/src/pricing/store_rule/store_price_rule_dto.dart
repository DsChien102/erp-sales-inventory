import 'store_price_calculation_type.dart';
import 'store_price_rule_status.dart';

final class StorePriceRuleDto {
  const StorePriceRuleDto({
    required this.id,
    required this.tenantId,
    required this.name,
    required this.status,
    required this.calculationType,
    required this.listMarkupRatio,
    required this.floorMarkupRatio,
    this.updatedAt,
  });

  final String id;
  final String tenantId;
  final String name;
  final StorePriceRuleStatus status;
  final StorePriceCalculationType calculationType;
  final double listMarkupRatio;
  final double floorMarkupRatio;
  final DateTime? updatedAt;

  bool get isActive => status == StorePriceRuleStatus.active;
}
