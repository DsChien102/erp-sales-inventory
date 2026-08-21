import 'package:vet45_shared_domain/shared_kernel_domain.dart';

import '../../exceptions/floor_price_greater_than_list_price_exception.dart';
import '../../ids/product_id.dart';
import 'events/product_price_band_changed.dart';
import 'price_band_calculation_mode.dart';
import 'price_band_markup_calculator.dart';
import 'price_band_markup_config.dart';
import 'product_price_band_status.dart';
import 'rules/floor_after_vat_not_greater_than_list_after_vat_rule.dart';
import 'rules/floor_before_vat_not_greater_than_list_before_vat_rule.dart';

/// List + optional floor price band for a product unit (before/after VAT).
final class ProductUnitPriceBand extends Entity<String> implements IAggregateRoot {
  ProductUnitPriceBand({
    required super.id,
    required this.tenantId,
    required this.productId,
    this.productUnitId,
    this.listBeforeVat,
    this.floorBeforeVat,
    this.listAfterVat,
    this.floorAfterVat,
    required this.effectiveFrom,
    this.effectiveTo,
    this.status = ProductPriceBandStatus.active,
    this.storePriceRuleId,
    PriceBandCalculationMode? calculationMode,
    this.markupConfig,
  }) : calculationMode =
           calculationMode ??
           (storePriceRuleId == null
               ? PriceBandCalculationMode.manual
               : PriceBandCalculationMode.ruleBased) {
    _validateCalculationSource(
      calculationMode: this.calculationMode,
      storePriceRuleId: storePriceRuleId,
      markupConfig: markupConfig,
    );
  }

  final String tenantId;
  final String productId;
  final String? productUnitId;
  final Money? listBeforeVat;
  final Money? floorBeforeVat;
  final Money? listAfterVat;
  final Money? floorAfterVat;
  final DateTime effectiveFrom;
  final DateTime? effectiveTo;
  final ProductPriceBandStatus status;
  final String? storePriceRuleId;
  final PriceBandCalculationMode calculationMode;
  final PriceBandMarkupConfig? markupConfig;

  /// Complete when list before-VAT and list after-VAT are set; floors optional.
  bool get isComplete => listBeforeVat != null && listAfterVat != null;

  factory ProductUnitPriceBand.set({
    required String id,
    required TenantId tenantId,
    required ProductId productId,
    String? productUnitId,
    required int listBeforeVat,
    required int listAfterVat,
    int? floorBeforeVat,
    int? floorAfterVat,
    DateTime? effectiveFrom,
    DateTime? effectiveTo,
    ProductPriceBandStatus status = ProductPriceBandStatus.active,
    String? storePriceRuleId,
    String? actorId,
  }) {
    return _setMaterialized(
      id: id,
      tenantId: tenantId,
      productId: productId,
      productUnitId: productUnitId,
      listBeforeVat: listBeforeVat,
      listAfterVat: listAfterVat,
      floorBeforeVat: floorBeforeVat,
      floorAfterVat: floorAfterVat,
      effectiveFrom: effectiveFrom,
      effectiveTo: effectiveTo,
      status: status,
      calculationMode: storePriceRuleId == null
          ? PriceBandCalculationMode.manual
          : PriceBandCalculationMode.ruleBased,
      storePriceRuleId: storePriceRuleId,
      actorId: actorId,
    );
  }

  factory ProductUnitPriceBand.setManual({
    required String id,
    required TenantId tenantId,
    required ProductId productId,
    String? productUnitId,
    required int listBeforeVat,
    required int listAfterVat,
    int? floorBeforeVat,
    int? floorAfterVat,
    DateTime? effectiveFrom,
    DateTime? effectiveTo,
    ProductPriceBandStatus status = ProductPriceBandStatus.active,
    String? actorId,
  }) {
    return _setMaterialized(
      id: id,
      tenantId: tenantId,
      productId: productId,
      productUnitId: productUnitId,
      listBeforeVat: listBeforeVat,
      listAfterVat: listAfterVat,
      floorBeforeVat: floorBeforeVat,
      floorAfterVat: floorAfterVat,
      effectiveFrom: effectiveFrom,
      effectiveTo: effectiveTo,
      status: status,
      calculationMode: PriceBandCalculationMode.manual,
      actorId: actorId,
    );
  }

  factory ProductUnitPriceBand.setCustomConfig({
    required String id,
    required TenantId tenantId,
    required ProductId productId,
    String? productUnitId,
    num? basePriceForUnit,
    required PriceBandMarkupConfig markupConfig,
    DateTime? effectiveFrom,
    DateTime? effectiveTo,
    ProductPriceBandStatus status = ProductPriceBandStatus.active,
    String? actorId,
  }) {
    if (basePriceForUnit == null) {
      return ProductUnitPriceBand(
        id: id,
        tenantId: tenantId.value,
        productId: productId.value,
        productUnitId: productUnitId,
        effectiveFrom: effectiveFrom ?? DateTime.now().toUtc(),
        effectiveTo: effectiveTo,
        status: status,
        calculationMode: PriceBandCalculationMode.customConfig,
        markupConfig: markupConfig,
      );
    }
    final prices = PriceBandMarkupCalculator.calculate(
      basePriceForUnit: basePriceForUnit,
      config: markupConfig,
    );
    return _setMaterialized(
      id: id,
      tenantId: tenantId,
      productId: productId,
      productUnitId: productUnitId,
      listBeforeVat: prices.listPrice,
      listAfterVat: prices.listPrice,
      floorBeforeVat: prices.floorPrice,
      floorAfterVat: prices.floorPrice,
      effectiveFrom: effectiveFrom,
      effectiveTo: effectiveTo,
      status: status,
      calculationMode: PriceBandCalculationMode.customConfig,
      markupConfig: markupConfig,
      actorId: actorId,
    );
  }

  factory ProductUnitPriceBand.setRuleBased({
    required String id,
    required TenantId tenantId,
    required ProductId productId,
    String? productUnitId,
    required String storePriceRuleId,
    required num basePriceForUnit,
    required PriceBandMarkupConfig ruleConfig,
    DateTime? effectiveFrom,
    DateTime? effectiveTo,
    ProductPriceBandStatus status = ProductPriceBandStatus.active,
    String? actorId,
  }) {
    final prices = PriceBandMarkupCalculator.calculate(
      basePriceForUnit: basePriceForUnit,
      config: ruleConfig,
    );
    return _setMaterialized(
      id: id,
      tenantId: tenantId,
      productId: productId,
      productUnitId: productUnitId,
      listBeforeVat: prices.listPrice,
      listAfterVat: prices.listPrice,
      floorBeforeVat: prices.floorPrice,
      floorAfterVat: prices.floorPrice,
      effectiveFrom: effectiveFrom,
      effectiveTo: effectiveTo,
      status: status,
      calculationMode: PriceBandCalculationMode.ruleBased,
      storePriceRuleId: storePriceRuleId,
      actorId: actorId,
    );
  }

  static ProductUnitPriceBand _setMaterialized({
    required String id,
    required TenantId tenantId,
    required ProductId productId,
    String? productUnitId,
    required int listBeforeVat,
    required int listAfterVat,
    int? floorBeforeVat,
    int? floorAfterVat,
    DateTime? effectiveFrom,
    DateTime? effectiveTo,
    required ProductPriceBandStatus status,
    required PriceBandCalculationMode calculationMode,
    String? storePriceRuleId,
    PriceBandMarkupConfig? markupConfig,
    String? actorId,
  }) {
    final listBeforeVo = Money(amountMinor: listBeforeVat, currencyCode: 'VND');
    final listAfterVo = Money(amountMinor: listAfterVat, currencyCode: 'VND');
    final floorBeforeVo = floorBeforeVat == null
        ? null
        : Money(amountMinor: floorBeforeVat, currencyCode: 'VND');
    final floorAfterVo = floorAfterVat == null
        ? null
        : Money(amountMinor: floorAfterVat, currencyCode: 'VND');

    final beforeRule = FloorBeforeVatNotGreaterThanListBeforeVatRule(
      floorBeforeVat: floorBeforeVo,
      listBeforeVat: listBeforeVo,
    );
    if (beforeRule.isBroken()) {
      throw FloorPriceGreaterThanListPriceException(beforeRule.message);
    }

    final afterRule = FloorAfterVatNotGreaterThanListAfterVatRule(
      floorAfterVat: floorAfterVo,
      listAfterVat: listAfterVo,
    );
    if (afterRule.isBroken()) {
      throw FloorPriceGreaterThanListPriceException(afterRule.message);
    }

    final from = effectiveFrom ?? DateTime.now().toUtc();
    final band = ProductUnitPriceBand(
      id: id,
      tenantId: tenantId.value,
      productId: productId.value,
      productUnitId: productUnitId,
      listBeforeVat: listBeforeVo,
      floorBeforeVat: floorBeforeVo,
      listAfterVat: listAfterVo,
      floorAfterVat: floorAfterVo,
      effectiveFrom: from,
      effectiveTo: effectiveTo,
      status: status,
      storePriceRuleId: storePriceRuleId,
      calculationMode: calculationMode,
      markupConfig: markupConfig,
    );
    band.addDomainEvent(
      ProductPriceBandChanged(
        productId: productId,
        tenantId: tenantId,
        productUnitId: productUnitId,
        listBeforeVat: listBeforeVat,
        floorBeforeVat: floorBeforeVat,
        listAfterVat: listAfterVat,
        floorAfterVat: floorAfterVat,
        effectiveFrom: from,
        effectiveTo: effectiveTo,
        status: status,
        calculationMode: calculationMode,
        listMarkupRatio: markupConfig?.listMarkupRatio,
        floorMarkupRatio: markupConfig?.floorMarkupRatio,
      ),
    );
    return band;
  }

  ProductUnitPriceBand replacePrices({
    required int listBeforeVat,
    required int listAfterVat,
    int? floorBeforeVat,
    int? floorAfterVat,
    DateTime? effectiveFrom,
    DateTime? effectiveTo,
    ProductPriceBandStatus? status,
    String? storePriceRuleId,
    String? actorId,
  }) {
    final nextStorePriceRuleId = storePriceRuleId ?? this.storePriceRuleId;
    final nextCalculationMode = nextStorePriceRuleId == null
        ? calculationMode
        : PriceBandCalculationMode.ruleBased;
    return _setMaterialized(
      id: id,
      tenantId: TenantId(tenantId),
      productId: ProductId(productId),
      productUnitId: productUnitId,
      listBeforeVat: listBeforeVat,
      listAfterVat: listAfterVat,
      floorBeforeVat: floorBeforeVat ?? this.floorBeforeVat?.amountMinor,
      floorAfterVat: floorAfterVat ?? this.floorAfterVat?.amountMinor,
      effectiveFrom: effectiveFrom ?? this.effectiveFrom,
      effectiveTo: effectiveTo ?? this.effectiveTo,
      status: status ?? this.status,
      calculationMode: nextCalculationMode,
      storePriceRuleId: nextStorePriceRuleId,
      markupConfig: nextCalculationMode == PriceBandCalculationMode.customConfig
          ? markupConfig
          : null,
      actorId: actorId,
    );
  }

  static void _validateCalculationSource({
    required PriceBandCalculationMode calculationMode,
    required String? storePriceRuleId,
    required PriceBandMarkupConfig? markupConfig,
  }) {
    switch (calculationMode) {
      case PriceBandCalculationMode.ruleBased:
        if (storePriceRuleId == null || storePriceRuleId.trim().isEmpty) {
          throw DomainException(
            'Rule-based price bands require a store price rule.',
          );
        }
        if (markupConfig != null) {
          throw DomainException(
            'Rule-based price bands cannot store custom markup ratios.',
          );
        }
      case PriceBandCalculationMode.customConfig:
        if (storePriceRuleId != null || markupConfig == null) {
          throw DomainException(
            'Custom-config price bands require custom ratios and no store rule.',
          );
        }
      case PriceBandCalculationMode.manual:
        if (storePriceRuleId != null || markupConfig != null) {
          throw DomainException(
            'Manual price bands cannot reference a formula source.',
          );
        }
    }
  }
}
