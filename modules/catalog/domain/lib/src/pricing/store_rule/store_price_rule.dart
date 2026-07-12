import 'package:vet45_shared_domain/shared_kernel_domain.dart';

import 'rules/markup_ratio_must_be_non_negative_rule.dart';
import 'rules/suggested_floor_not_greater_than_list_rule.dart';

/// Tenant-level store price rule (1 per tenant in Foundation).
final class StorePriceRule extends Entity<String> implements IAggregateRoot {
  StorePriceRule({
    required String id,
    required this.tenantId,
    required this.name,
    required this.listMarkupRatio,
    required this.floorMarkupRatio,
    this.isActive = true,
  }) : super(id: id);

  final String tenantId;
  final String name;
  final double listMarkupRatio;
  final double floorMarkupRatio;
  final bool isActive;

  factory StorePriceRule.create({
    required String id,
    required String tenantId,
    required String name,
    required double listMarkupRatio,
    required double floorMarkupRatio,
    bool isActive = true,
  }) {
    final rule = StorePriceRule(
      id: id,
      tenantId: tenantId,
      name: name.trim(),
      listMarkupRatio: listMarkupRatio,
      floorMarkupRatio: floorMarkupRatio,
      isActive: isActive,
    );
    rule._validateMarkups();
    if (rule.name.isEmpty) {
      throw DomainException('Store price rule name must not be empty.');
    }
    return rule;
  }

  StorePriceRule replace({
    required String name,
    required double listMarkupRatio,
    required double floorMarkupRatio,
    bool? isActive,
  }) {
    return StorePriceRule.create(
      id: id,
      tenantId: tenantId,
      name: name,
      listMarkupRatio: listMarkupRatio,
      floorMarkupRatio: floorMarkupRatio,
      isActive: isActive ?? this.isActive,
    );
  }

  StorePriceRule deactivate() {
    return StorePriceRule(
      id: id,
      tenantId: tenantId,
      name: name,
      listMarkupRatio: listMarkupRatio,
      floorMarkupRatio: floorMarkupRatio,
      isActive: false,
    );
  }

  StorePriceRule activate() {
    return StorePriceRule(
      id: id,
      tenantId: tenantId,
      name: name,
      listMarkupRatio: listMarkupRatio,
      floorMarkupRatio: floorMarkupRatio,
      isActive: true,
    );
  }

  /// Suggests list/floor from base price using store markups.
  ({double listPrice, double floorPrice}) suggestPrices(double basePrice) {
    checkRule(
      SuggestedFloorNotGreaterThanListRule(
        basePrice: basePrice,
        listMarkupRatio: listMarkupRatio,
        floorMarkupRatio: floorMarkupRatio,
      ),
    );
    return (
      listPrice: (basePrice * (1 + listMarkupRatio)).roundToDouble(),
      floorPrice: (basePrice * (1 + floorMarkupRatio)).roundToDouble(),
    );
  }

  void _validateMarkups() {
    checkRule(
      MarkupRatioMustBeNonNegativeRule(
        ratio: listMarkupRatio,
        label: 'List markup ratio',
      ),
    );
    checkRule(
      MarkupRatioMustBeNonNegativeRule(
        ratio: floorMarkupRatio,
        label: 'Floor markup ratio',
      ),
    );
  }
}
