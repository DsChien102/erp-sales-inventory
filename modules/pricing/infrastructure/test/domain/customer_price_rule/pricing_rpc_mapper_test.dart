import 'package:test/test.dart';
import 'package:vet45_pricing_application/application.dart';
import 'package:vet45_pricing_domain/domain.dart';
import 'package:vet45_pricing_infrastructure/infrastructure.dart';
import 'package:vet45_shared_domain/shared_kernel_domain.dart';
import 'package:vet45_shared_infrastructure/infrastructure.dart';

void main() {
  test('create context params use date-only and never send actor id', () {
    final params = PricingRpcMapper.createContextParams(_command());

    expect(params['p_effective_from'], '2026-07-16');
    expect(params['p_effective_to'], '2026-07-20');
    expect(params['p_idempotency_key'], 'idem-1');
    expect(params, isNot(contains('p_actor_id')));
  });

  test('create params use aggregate values and never send actor id', () {
    final params = PricingRpcMapper.createParams(
      candidate: _candidate(),
      idempotencyKey: ' idem-1 ',
      acknowledgeFloorWarning: true,
    );

    expect(params['p_rule_id'], 'command-1');
    expect(params['p_rule_price_minor'], 90000);
    expect(params['p_idempotency_key'], 'idem-1');
    expect(params['p_acknowledge_floor_warning'], isTrue);
    expect(params, isNot(contains('p_actor_id')));
  });

  test('context mapper preserves floor redaction', () {
    final context = PricingRpcMapper.createContextFromJson({
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
        'floor_price_minor': null,
        'floor_price_hidden': true,
        'is_below_floor': true,
      },
      'can_override_floor': false,
      'has_conflicting_rule': true,
      'conflicting_rule_id': null,
      'idempotency_key_exists': true,
    });

    expect(context.productUnit.floorPriceMinor, isNull);
    expect(context.productUnit.floorPriceHidden, isTrue);
    expect(context.productUnit.isBelowFloor, isTrue);
    expect(context.hasConflictingRule, isTrue);
    expect(context.idempotencyKeyExists, isTrue);
  });

  test('result mapper maps authoritative detail and warnings', () {
    final result = PricingRpcMapper.createResultFromJson(_createResultJson());

    expect(result.rule.id, 'rule-1');
    expect(result.rule.price.amountMinor, 90000);
    expect(result.rule.productUnit.productReferenceId, 'VAC-001');
    expect(result.rule.productUnit.sku, 'VAC-BTL');
    expect(result.rule.ruleType, CustomerPriceRuleType.specialPrice);
    expect(result.rule.sourceType, CustomerPriceRuleSourceType.manual);
    expect(result.rule.persistedStatus, CustomerPriceRuleStatus.active);
    expect(result.rule.derivedStatus, CustomerPriceRuleDerivedStatus.applying);
    expect(
      result.rule.effectivePeriod.effectiveFrom,
      DateTime.utc(2026, 7, 16),
    );
    expect(result.rule.effectivePeriod.effectiveTo, DateTime.utc(2026, 7, 20));
    expect(
      result.rule.referenceHealth.customerState,
      CustomerPriceRuleReferenceState.valid,
    );
    expect(result.rule.sourceTrace.hidden, isFalse);
    expect(result.warnings.single.code, 'below_floor_price');
  });

  test('error mapper decodes NOT_FOUND envelope', () {
    final error = mapPricingRpcError(
      RpcException(
        '{"code":"NOT_FOUND","message":"Rule not found","details":{}}',
      ),
    );

    expect(error.code, PricingBlockedCodes.notFound);
  });

  test('error mapper decodes stable JSON envelope', () {
    final error = mapPricingRpcError(
      RpcException(
        '{"code":"IDEMPOTENCY_CONFLICT","message":"payload changed",'
        '"details":{"idempotencyKey":"idem-1"}}',
      ),
    );

    expect(error.code, PricingBlockedCodes.idempotencyConflict);
    expect(error.details['idempotencyKey'], 'idem-1');
  });

  test('error mapper converts unknown envelope codes to SYSTEM_ERROR', () {
    final error = mapPricingRpcError(
      RpcException(
        '{"code":"UNEXPECTED_DATABASE_CODE","message":"unexpected",'
        '"details":{}}',
      ),
    );

    expect(error.code, PricingBlockedCodes.systemError);
    expect(error.message, 'Pricing operation failed.');
  });

  test('error mapper rejects malformed envelope field types', () {
    final error = mapPricingRpcError(
      RpcException(
        '{"code":"VALIDATION_ERROR","message":42,'
        '"details":{"fieldErrors":[]}}',
      ),
    );

    expect(error.code, PricingBlockedCodes.systemError);
    expect(error.message, 'Pricing operation failed.');
  });

  test('error mapper does not expose raw database messages', () {
    final error = mapPricingRpcError(
      RpcException('relation pricing.private_table does not exist'),
    );

    expect(error.code, PricingBlockedCodes.systemError);
    expect(error.message, 'Pricing operation failed.');
  });
}

CreateCustomerPriceRuleCommand _command() => CreateCustomerPriceRuleCommand(
  tenantId: 'tenant-1',
  actorId: 'user-1',
  customerId: 'customer-1',
  productId: 'product-1',
  productUnitId: 'unit-1',
  rulePriceMinor: 90000,
  currencyCode: 'VND',
  effectiveFrom: DateTime.utc(2026, 7, 16, 13),
  effectiveTo: DateTime.utc(2026, 7, 20, 22),
  acknowledgeFloorWarning: true,
  idempotencyKey: 'idem-1',
);

CustomerPriceRule _candidate() => CustomerPriceRule.createManual(
  id: 'command-1',
  key: CustomerPriceRuleKey(
    tenantId: 'tenant-1',
    customerId: 'customer-1',
    productId: 'product-1',
    productUnitId: 'unit-1',
  ),
  price: Money(amountMinor: 90000, currencyCode: 'VND'),
  effectivePeriod: EffectivePeriod(
    effectiveFrom: DateTime.utc(2026, 7, 16),
    effectiveTo: DateTime.utc(2026, 7, 20),
  ),
  actorId: 'user-1',
  validationOutcome: RuleValidationOutcome.evaluateFloor(
    rulePrice: Money(amountMinor: 90000, currencyCode: 'VND'),
    floorPrice: Money(amountMinor: 100000, currencyCode: 'VND'),
    acknowledgeFloorWarning: true,
    canOverrideFloor: true,
  ),
);

Map<String, dynamic> _createResultJson() => {
  'rule': {
    'id': 'rule-1',
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
    'price': {'amount_minor': 90000, 'currency_code': 'VND'},
    'effective_period': {
      'effective_from': '2026-07-16',
      'effective_to': '2026-07-20',
    },
    'rule_type': 'special_price',
    'source_type': 'manual',
    'persisted_status': 'active',
    'derived_status': 'applying',
    'note': null,
    'validation_outcome': {
      'outcome': 'warning',
      'warning_codes': ['below_floor_price'],
      'blocking_codes': <String>[],
      'list_price': {'amount_minor': 150000, 'currency_code': 'VND'},
      'floor_price': {'amount_minor': 100000, 'currency_code': 'VND'},
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
    'created_by': 'user-1',
    'created_at': '2026-07-16T00:00:00Z',
    'updated_by': 'user-1',
    'updated_at': '2026-07-16T00:00:00Z',
    'version': 1,
    'available_actions': <String>[],
  },
  'warnings': [
    {'code': 'below_floor_price', 'details': <String, dynamic>{}},
  ],
};
