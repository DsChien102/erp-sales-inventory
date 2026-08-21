import 'package:vet45_pricing_application/application.dart';
import 'package:vet45_pricing_domain/domain.dart';
import 'package:vet45_shared_domain/shared_kernel_domain.dart';

import 'customer_price_rule_detail_rpc_mapper.dart';
import 'pricing_rpc_mapper.dart';

abstract final class PricingUpdateRpcMapper {
  static Map<String, dynamic> contextParams(
    UpdateCustomerPriceRuleCommand command,
  ) => {
    'p_tenant_id': command.tenantId,
    'p_rule_id': command.ruleId,
    'p_expected_version': command.expectedVersion,
    'p_rule_price_minor': command.rulePriceMinor,
    'p_effective_from': _date(command.effectiveFrom),
    'p_effective_to': command.effectiveTo == null
        ? null
        : _date(command.effectiveTo!),
  };

  static CustomerPriceRuleUpdateContext contextFromJson({
    required UpdateCustomerPriceRuleCommand command,
    required Map<String, dynamic> json,
  }) {
    final currentJson = _map(json['current_rule'], 'current_rule');
    final detail = CustomerPriceRuleDetailRpcMapper.detailFromJson(currentJson);
    final shared = PricingRpcMapper.createContextFromJson({
      'customer': json['customer'],
      'product_unit': json['product_unit'],
      'can_override_floor': json['can_override_floor'],
      'has_conflicting_rule': json['has_conflicting_rule'],
      'conflicting_rule_id': json['conflicting_rule_id'],
      'idempotency_key_exists': false,
    });
    final validation = detail.validationOutcome;
    final current = CustomerPriceRule.reconstitute(
      id: detail.id,
      key: CustomerPriceRuleKey(
        tenantId: command.tenantId,
        customerId: detail.customer.customerId,
        productId: detail.productUnit.productId,
        productUnitId: detail.productUnit.productUnitId,
      ),
      price: _money(detail.price),
      effectivePeriod: EffectivePeriod(
        effectiveFrom: detail.effectivePeriod.effectiveFrom,
        effectiveTo: detail.effectivePeriod.effectiveTo,
      ),
      actorId: detail.updatedBy,
      validationOutcome: RuleValidationOutcome(
        outcome: _validationState(validation.outcome),
        priceCheckStatus: _priceCheckStatus(
          _requiredString(currentJson, 'price_check_status'),
        ),
        warningCodes: validation.warningCodes,
        blockingCodes: validation.blockingCodes,
        listPrice: validation.listPrice == null
            ? null
            : _money(validation.listPrice!),
        floorPrice: validation.floorPrice == null
            ? null
            : _money(validation.floorPrice!),
        floorPriceHidden: validation.floorPriceHidden,
      ),
      note: detail.note,
      ruleType: detail.ruleType,
      sourceType: detail.sourceType,
      status: detail.persistedStatus,
      reviewStatus: _reviewStatus(
        _requiredString(currentJson, 'review_status'),
      ),
      version: detail.version,
    );
    return CustomerPriceRuleUpdateContext(
      currentRule: current,
      customer: shared.customer,
      productUnit: shared.productUnit,
      canOverrideFloor: shared.canOverrideFloor,
      hasConflictingRule: shared.hasConflictingRule,
      conflictingRuleId: shared.conflictingRuleId,
    );
  }

  static Map<String, dynamic> updateParams({
    required CustomerPriceRule candidate,
    required int expectedVersion,
    required bool acknowledgeFloorWarning,
    bool acknowledgeOverwrite = false,
  }) => {
    'p_tenant_id': candidate.key.tenantId,
    'p_rule_id': candidate.id,
    'p_expected_version': expectedVersion,
    'p_rule_price_minor': candidate.price.amountMinor,
    'p_effective_from': _date(candidate.effectivePeriod.effectiveFrom),
    'p_effective_to': candidate.effectivePeriod.effectiveTo == null
        ? null
        : _date(candidate.effectivePeriod.effectiveTo!),
    'p_note': candidate.note,
    'p_acknowledge_floor_warning': acknowledgeFloorWarning,
    'p_acknowledge_overwrite': acknowledgeOverwrite,
  };

  static CustomerPriceRuleDetailDto updateResultFromJson(
    Map<String, dynamic> json,
  ) => CustomerPriceRuleDetailRpcMapper.detailFromJson(json);

  static Money _money(MoneyDto value) =>
      Money(amountMinor: value.amountMinor, currencyCode: value.currencyCode);

  static RuleValidationState _validationState(String value) => switch (value) {
    'valid' || 'notChecked' => RuleValidationState.valid,
    'warning' => RuleValidationState.warning,
    'blocked' => RuleValidationState.blocked,
    'needsReview' || 'needs_review' => RuleValidationState.needsReview,
    _ => throw FormatException('Unknown validation outcome: $value.'),
  };

  static PriceCheckStatus _priceCheckStatus(String value) => switch (value) {
    'not_checked' => PriceCheckStatus.notChecked,
    'normal' => PriceCheckStatus.normal,
    'override_allowed' => PriceCheckStatus.overrideAllowed,
    _ => throw FormatException('Unknown price check status: $value.'),
  };

  static CustomerPriceRuleReviewStatus _reviewStatus(String value) =>
      switch (value) {
        'clear' => CustomerPriceRuleReviewStatus.clear,
        'warning' => CustomerPriceRuleReviewStatus.warning,
        'blocked' => CustomerPriceRuleReviewStatus.blocked,
        'needs_review' => CustomerPriceRuleReviewStatus.needsReview,
        _ => throw FormatException('Unknown review status: $value.'),
      };

  static Map<String, dynamic> _map(Object? value, String field) {
    if (value is! Map) throw FormatException('Expected object field $field.');
    return value.cast<String, dynamic>();
  }

  static String _requiredString(Map<String, dynamic> map, String field) {
    final value = map[field];
    if (value is! String || value.trim().isEmpty) {
      throw FormatException('Expected required string field $field.');
    }
    return value;
  }

  static String _date(DateTime value) =>
      '${value.year.toString().padLeft(4, '0')}-'
      '${value.month.toString().padLeft(2, '0')}-'
      '${value.day.toString().padLeft(2, '0')}';
}
