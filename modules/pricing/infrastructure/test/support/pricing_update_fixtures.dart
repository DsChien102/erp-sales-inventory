import 'package:vet45_pricing_application/application.dart';
import 'package:vet45_pricing_domain/domain.dart';
import 'package:vet45_shared_domain/shared_kernel_domain.dart';

const updateRuleId = '00000000-0000-4000-8000-000000000001';

UpdateCustomerPriceRuleCommand updateCommand() =>
    UpdateCustomerPriceRuleCommand(
      tenantId: 'tenant-1',
      actorId: 'user-1',
      ruleId: updateRuleId,
      expectedVersion: 3,
      rulePriceMinor: 95000,
      effectiveFrom: DateTime.utc(2026, 7, 16, 13),
      effectiveTo: DateTime.utc(2026, 7, 20, 22),
      note: 'Updated note',
      acknowledgeFloorWarning: true,
    );

CustomerPriceRule updateCandidate() {
  final rule = CustomerPriceRule.reconstitute(
    id: updateRuleId,
    key: CustomerPriceRuleKey(
      tenantId: 'tenant-1',
      customerId: 'customer-1',
      productId: 'product-1',
      productUnitId: 'unit-1',
    ),
    price: Money(amountMinor: 90000, currencyCode: 'VND'),
    effectivePeriod: EffectivePeriod(effectiveFrom: DateTime.utc(2026, 7, 16)),
    actorId: 'user-previous',
    validationOutcome: RuleValidationOutcome.clear(),
    note: 'VIP',
    ruleType: CustomerPriceRuleType.specialPrice,
    sourceType: CustomerPriceRuleSourceType.manual,
    status: CustomerPriceRuleStatus.active,
    reviewStatus: CustomerPriceRuleReviewStatus.clear,
    version: 3,
  );
  rule.updateMutableFields(
    price: Money(amountMinor: 95000, currencyCode: 'VND'),
    effectivePeriod: EffectivePeriod(
      effectiveFrom: DateTime.utc(2026, 7, 16),
      effectiveTo: DateTime.utc(2026, 7, 20),
    ),
    validationOutcome: RuleValidationOutcome.clear(),
    note: 'Updated note',
  );
  return rule;
}

Map<String, dynamic> updateContextJson() {
  final currentRule = updateDetailJson(version: 3, amountMinor: 90000)
    ..['review_status'] = 'clear'
    ..['price_check_status'] = 'normal';
  return {
    'current_rule': currentRule,
    'customer': {
      'customer_id': 'customer-1',
      'display_name': 'Clinic A',
      'status': 'active',
      'exists': true,
      'is_customer': true,
    },
    'product_unit': {
      'product_id': 'product-1',
      'product_name': 'Vaccine',
      'product_unit_id': 'unit-1',
      'unit_name': 'Bottle',
      'sellable_status': 'active',
      'currency_code': 'VND',
      'list_price_minor': 150000,
      'floor_price_minor': 100000,
      'floor_price_hidden': false,
      'is_below_floor': true,
    },
    'can_override_floor': true,
    'has_conflicting_rule': false,
    'conflicting_rule_id': null,
  };
}

Map<String, dynamic> updateDetailJson({
  required int version,
  required int amountMinor,
}) => {
  'id': updateRuleId,
  'customer': {
    'customer_id': 'customer-1',
    'display_name': 'Clinic A',
    'status': 'active',
  },
  'product_unit': {
    'product_id': 'product-1',
    'product_name': 'Vaccine',
    'product_unit_id': 'unit-1',
    'unit_name': 'Bottle',
    'sellable_status': 'active',
    'product_reference_id': 'VAC-001',
    'sku': 'VAC-BTL',
  },
  'price': {'amount_minor': amountMinor, 'currency_code': 'VND'},
  'effective_period': {
    'effective_from': '2026-07-16',
    'effective_to': '2026-07-20',
  },
  'rule_type': 'special_price',
  'source_type': 'manual',
  'persisted_status': 'active',
  'derived_status': 'applying',
  'note': amountMinor == 90000 ? 'VIP' : 'Updated note',
  'validation_outcome': {
    'outcome': 'valid',
    'warning_codes': <String>[],
    'blocking_codes': <String>[],
    'list_price': {'amount_minor': 150000, 'currency_code': 'VND'},
    'floor_price': {'amount_minor': 80000, 'currency_code': 'VND'},
    'floor_price_hidden': false,
  },
  'reference_health': {
    'customer_state': 'valid',
    'product_unit_state': 'valid',
    'price_band_state': 'current',
    'issue_codes': <String>[],
    'used_stored_price_band_snapshot': false,
  },
  'source_trace': {
    'hidden': false,
    'source_import_id': null,
    'source_import_row_id': null,
    'source_order_id': null,
    'source_order_line_id': null,
  },
  'created_by': 'user-created',
  'created_at': '2026-07-01T00:00:00Z',
  'updated_by': 'user-previous',
  'updated_at': '2026-07-16T00:00:00Z',
  'version': version,
  'available_actions': <String>['edit'],
};
