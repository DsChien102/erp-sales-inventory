import 'package:test/test.dart';
import 'package:vet45_adapters/vet45_adapters.dart';
import 'package:vet45_pricing_application/application.dart';
import 'package:vet45_pricing_domain/domain.dart';
import 'package:vet45_pricing_infrastructure/src/domain/customer_price_rule/customer_price_rule_detail_rpc_mapper.dart';
import 'package:vet45_pricing_infrastructure/src/domain/customer_price_rule/supabase_customer_price_rule_read_gateway.dart';
import 'package:vet45_shared_infrastructure/infrastructure.dart';

import '../../support/fake_pricing_rpc_supabase.dart';

void main() {
  test('detail params use exact wires and never send actor id', () {
    final params = CustomerPriceRuleDetailRpcMapper.params(
      GetCustomerPriceRuleDetailQuery(
        tenantId: 'tenant-1',
        ruleId: '00000000-0000-4000-8000-000000000001',
        businessDate: DateTime.utc(2026, 7, 16, 18),
      ),
    );

    expect(params, {
      'p_tenant_id': 'tenant-1',
      'p_rule_id': '00000000-0000-4000-8000-000000000001',
      'p_business_date': '2026-07-16',
    });
    expect(params, isNot(contains('p_actor_id')));
  });

  test('maps active applying detail with edit-disable-history', () {
    final detail = CustomerPriceRuleDetailRpcMapper.detailFromJson(
      _detailJson(),
    );

    expect(detail.persistedStatus, CustomerPriceRuleStatus.active);
    expect(detail.derivedStatus, CustomerPriceRuleDerivedStatus.applying);
    expect(detail.availableActions, [
      CustomerPriceRuleAvailableActions.edit,
      CustomerPriceRuleAvailableActions.disable,
      CustomerPriceRuleAvailableActions.history,
    ]);
    expect(detail.validationOutcome.listPrice?.amountMinor, 150000);
    expect(detail.validationOutcome.floorPrice?.amountMinor, 100000);
    expect(detail.createdAt.isUtc, isTrue);
    expect(detail.version, 1);
  });

  test('maps disabled detail with edit-reenable-history', () {
    final detail = CustomerPriceRuleDetailRpcMapper.detailFromJson(
      _detailJson(
        persistedStatus: 'disabled',
        derivedStatus: 'disabled',
        actions: const [
          CustomerPriceRuleAvailableActions.edit,
          CustomerPriceRuleAvailableActions.reenable,
          CustomerPriceRuleAvailableActions.history,
        ],
        disabledAt: '2026-07-16T09:00:00Z',
        disabledBy: 'context-user',
        disabledReason: 'Kết thúc thỏa thuận',
      ),
    );

    expect(detail.derivedStatus, CustomerPriceRuleDerivedStatus.disabled);
    expect(detail.disabledAt, DateTime.utc(2026, 7, 16, 9));
    expect(detail.disabledBy, 'context-user');
    expect(detail.disabledReason, 'Kết thúc thỏa thuận');
    expect(detail.availableActions, [
      CustomerPriceRuleAvailableActions.edit,
      CustomerPriceRuleAvailableActions.reenable,
      CustomerPriceRuleAvailableActions.history,
    ]);
  });

  for (final entry in {
    'expired': CustomerPriceRuleDerivedStatus.expired,
    'not_yet_effective': CustomerPriceRuleDerivedStatus.notYetEffective,
  }.entries) {
    test('maps derived status ${entry.key}', () {
      final detail = CustomerPriceRuleDetailRpcMapper.detailFromJson(
        _detailJson(derivedStatus: entry.key),
      );
      expect(detail.derivedStatus, entry.value);
    });
  }

  test('maps hidden floor with null amount and below-floor warning', () {
    final detail = CustomerPriceRuleDetailRpcMapper.detailFromJson(
      _detailJson(
        floorPrice: null,
        floorPriceHidden: true,
        warningCodes: const ['below_floor_price'],
      ),
    );

    expect(detail.validationOutcome.floorPriceHidden, isTrue);
    expect(detail.validationOutcome.floorPrice, isNull);
    expect(
      detail.validationOutcome.warningCodes,
      contains('below_floor_price'),
    );
  });

  test('maps stale customer/product health with stored snapshot fallback', () {
    final detail = CustomerPriceRuleDetailRpcMapper.detailFromJson(
      _detailJson(
        customerState: 'inactive',
        productUnitState: 'missing',
        priceBandState: 'unavailable',
        issueCodes: const [
          'customer_reference_inactive',
          'product_unit_reference_missing',
        ],
        usedStoredPriceBandSnapshot: true,
      ),
    );

    expect(
      detail.referenceHealth.customerState,
      CustomerPriceRuleReferenceState.inactive,
    );
    expect(
      detail.referenceHealth.productUnitState,
      CustomerPriceRuleReferenceState.missing,
    );
    expect(detail.referenceHealth.usedStoredPriceBandSnapshot, isTrue);
    expect(detail.customer.displayName, 'Clinic A');
  });

  test('maps hidden source trace with all identifiers null', () {
    final detail = CustomerPriceRuleDetailRpcMapper.detailFromJson(
      _detailJson(sourceTraceHidden: true),
    );

    expect(detail.sourceTrace.hidden, isTrue);
    expect(detail.sourceTrace.sourceImportId, isNull);
    expect(detail.sourceTrace.sourceOrderId, isNull);
  });

  test('maps visible import/order/memory source trace', () {
    final detail = CustomerPriceRuleDetailRpcMapper.detailFromJson(
      _detailJson(
        sourceTraceHidden: false,
        sourceImportId: 'import-1',
        sourceImportRowId: 'row-1',
        sourceOrderId: 'order-1',
        sourceOrderLineId: 'line-1',
        sourceMemoryRequestId: 'request-1',
      ),
    );

    expect(detail.sourceTrace.hidden, isFalse);
    expect(detail.sourceTrace.sourceImportId, 'import-1');
    expect(detail.sourceTrace.sourceOrderLineId, 'line-1');
    expect(detail.sourceTrace.sourceMemoryRequestId, 'request-1');
  });

  for (final caseData in [
    (
      'fractional money',
      () =>
          _detailJson()
            ..['price'] = {'amount_minor': 1.5, 'currency_code': 'VND'},
    ),
    ('unknown enum', () => _detailJson(derivedStatus: 'weird')),
    ('unknown action', () => _detailJson(actions: const ['view'])),
    ('unknown health', () => _detailJson(customerState: 'ghost')),
    (
      'invalid date',
      () =>
          _detailJson()
            ..['effective_period'] = {'effective_from': '2026-13-40'},
    ),
    (
      'invalid timestamp',
      () => _detailJson()..['created_at'] = 'not-a-timestamp',
    ),
    ('non-positive version', () => _detailJson()..['version'] = 0),
    (
      'hidden floor leak',
      () => _detailJson(
        floorPriceHidden: true,
        floorPrice: {'amount_minor': 100000, 'currency_code': 'VND'},
      ),
    ),
    (
      'hidden source-trace leak',
      () => _detailJson(sourceTraceHidden: true, sourceImportId: 'import-1'),
    ),
    (
      'hidden memory request leak',
      () => _detailJson(
        sourceTraceHidden: true,
        sourceMemoryRequestId: 'request-1',
      ),
    ),
    (
      'deleted status in success payload',
      () => _detailJson(persistedStatus: 'deleted'),
    ),
    (
      'disabled without actor/time',
      () => _detailJson(
        persistedStatus: 'disabled',
        derivedStatus: 'disabled',
        actions: const [
          CustomerPriceRuleAvailableActions.edit,
          CustomerPriceRuleAvailableActions.reenable,
          CustomerPriceRuleAvailableActions.history,
        ],
      ),
    ),
  ]) {
    test('rejects ${caseData.$1} as malformed detail', () {
      expect(
        () => CustomerPriceRuleDetailRpcMapper.detailFromJson(caseData.$2()),
        throwsA(isA<FormatException>()),
      );
    });
  }

  test(
    'gateway maps NOT_FOUND envelope and hides technical RPC errors',
    () async {
      final notFound = FakePricingRpcSupabase()
        ..registerHandler('get_customer_price_rule_detail', (_) async {
          throw Exception(
            '{"code":"NOT_FOUND","message":"Rule not found","details":{}}',
          );
        });
      final technical = FakePricingRpcSupabase()
        ..registerHandler('get_customer_price_rule_detail', (_) async {
          throw Exception(
            'relation pricing.customer_price_rule does not exist',
          );
        });
      final malformed = FakePricingRpcSupabase()
        ..registerHandler('get_customer_price_rule_detail', (_) async {
          return {'id': 'rule-1'};
        });

      await expectLater(
        _gateway(notFound).getCustomerPriceRuleDetail(_query()),
        throwsA(
          isA<PricingBlockedException>().having(
            (error) => error.code,
            'code',
            PricingBlockedCodes.notFound,
          ),
        ),
      );
      await expectLater(
        _gateway(technical).getCustomerPriceRuleDetail(_query()),
        throwsA(
          isA<PricingBlockedException>().having(
            (error) => error.code,
            'code',
            PricingBlockedCodes.systemError,
          ),
        ),
      );
      await expectLater(
        _gateway(malformed).getCustomerPriceRuleDetail(_query()),
        throwsA(
          isA<PricingBlockedException>().having(
            (error) => error.code,
            'code',
            PricingBlockedCodes.systemError,
          ),
        ),
      );
    },
  );

  test('gateway decodes a successful detail response', () async {
    final supabase = FakePricingRpcSupabase()
      ..registerHandler(
        'get_customer_price_rule_detail',
        (_) async => _detailJson(),
      );

    final detail = await _gateway(
      supabase,
    ).getCustomerPriceRuleDetail(_query());

    expect(detail.id, '00000000-0000-4000-8000-000000000001');
    expect(detail.derivedStatus, CustomerPriceRuleDerivedStatus.applying);
  });
}

SupabaseCustomerPriceRuleReadGateway _gateway(
  FakePricingRpcSupabase supabase,
) => SupabaseCustomerPriceRuleReadGateway(
  rpcClient: SupabaseSchemaRpcClient(
    supabase: supabase,
    schema: 'pricing',
    mapError: (error, [stackTrace]) => RpcException(error.toString()),
  ),
);

GetCustomerPriceRuleDetailQuery _query() => GetCustomerPriceRuleDetailQuery(
  tenantId: 'tenant-1',
  ruleId: '00000000-0000-4000-8000-000000000001',
  businessDate: DateTime.utc(2026, 7, 16),
);

Map<String, dynamic> _detailJson({
  String persistedStatus = 'active',
  String derivedStatus = 'applying',
  List<String> actions = const [
    CustomerPriceRuleAvailableActions.edit,
    CustomerPriceRuleAvailableActions.disable,
    CustomerPriceRuleAvailableActions.history,
  ],
  String customerState = 'valid',
  String productUnitState = 'valid',
  String priceBandState = 'current',
  List<String> issueCodes = const [],
  bool usedStoredPriceBandSnapshot = false,
  bool floorPriceHidden = false,
  Object? floorPrice = const {'amount_minor': 100000, 'currency_code': 'VND'},
  List<String> warningCodes = const ['below_floor_price'],
  bool sourceTraceHidden = false,
  String? sourceImportId,
  String? sourceImportRowId,
  String? sourceOrderId,
  String? sourceOrderLineId,
  String? sourceMemoryRequestId,
  Object? disabledAt,
  Object? disabledBy,
  Object? disabledReason,
}) => {
  'id': '00000000-0000-4000-8000-000000000001',
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
    'effective_from': '2026-07-01',
    'effective_to': '2026-07-31',
  },
  'rule_type': 'special_price',
  'source_type': 'manual',
  'persisted_status': persistedStatus,
  'derived_status': derivedStatus,
  'note': null,
  'validation_outcome': {
    'outcome': 'warning',
    'warning_codes': warningCodes,
    'blocking_codes': <String>[],
    'list_price': {'amount_minor': 150000, 'currency_code': 'VND'},
    'floor_price': floorPrice,
    'floor_price_hidden': floorPriceHidden,
  },
  'reference_health': {
    'customer_state': customerState,
    'product_unit_state': productUnitState,
    'price_band_state': priceBandState,
    'issue_codes': issueCodes,
    'used_stored_price_band_snapshot': usedStoredPriceBandSnapshot,
  },
  'source_trace': {
    'hidden': sourceTraceHidden,
    'source_import_id': sourceImportId,
    'source_import_row_id': sourceImportRowId,
    'source_order_id': sourceOrderId,
    'source_order_line_id': sourceOrderLineId,
    'source_memory_request_id': sourceMemoryRequestId,
  },
  'created_by': 'user-1',
  'created_at': '2026-07-16T00:00:00Z',
  'updated_by': 'user-1',
  'updated_at': '2026-07-16T10:30:00+07:00',
  'version': 1,
  'available_actions': actions,
  'disabled_at': disabledAt,
  'disabled_by': disabledBy,
  'disabled_reason': disabledReason,
};
