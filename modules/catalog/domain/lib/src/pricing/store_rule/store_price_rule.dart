import 'package:vet45_shared_domain/shared_kernel_domain.dart';

import '../price_band/price_band_markup_calculator.dart';
import '../price_band/price_band_markup_config.dart';
import 'rules/markup_ratio_must_be_non_negative_rule.dart';

/// Tenant-level store price rule (1 per tenant in Foundation).
final class StorePriceRule extends Entity<String> implements IAggregateRoot {
  StorePriceRule({
    required super.id,
    required this.tenantId,
    required this.name,
    required this.listMarkupRatio,
    required this.floorMarkupRatio,
    this.isActive = true,
  });

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

  /// Suggests before-VAT list/floor from base price using store markups.
  ({int listBeforeVat, int floorBeforeVat}) suggestPrices(double basePrice) {
    final calculated = PriceBandMarkupCalculator.calculate(
      basePriceForUnit: basePrice,
      config: PriceBandMarkupConfig(
        listMarkupRatio: listMarkupRatio,
        floorMarkupRatio: floorMarkupRatio,
      ),
    );
    return (
      listBeforeVat: calculated.listPrice,
      floorBeforeVat: calculated.floorPrice!,
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
    PriceBandMarkupConfig(
      listMarkupRatio: listMarkupRatio,
      floorMarkupRatio: floorMarkupRatio,
    );
  }
}
