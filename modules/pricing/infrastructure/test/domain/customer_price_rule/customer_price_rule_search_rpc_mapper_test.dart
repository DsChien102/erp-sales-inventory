import 'package:test/test.dart';
import 'package:vet45_adapters/vet45_adapters.dart';
import 'package:vet45_pricing_application/application.dart';
import 'package:vet45_pricing_domain/domain.dart';
import 'package:vet45_pricing_infrastructure/src/domain/customer_price_rule/customer_price_rule_search_rpc_mapper.dart';
import 'package:vet45_pricing_infrastructure/src/domain/customer_price_rule/supabase_customer_price_rule_read_gateway.dart';
import 'package:vet45_shared_infrastructure/infrastructure.dart';

import '../../support/fake_pricing_rpc_supabase.dart';

void main() {
  test(
    'search params use exact wires, UTC date, opaque cursor, and no actor',
    () {
      final params = CustomerPriceRuleSearchRpcMapper.params(
        SearchCustomerPriceRulesQuery(
          tenantId: 'tenant-1',
          q: '  vaccine  ',
          quickFilter: CustomerPriceRuleQuickFilter.belowFloor,
          statuses: const [
            CustomerPriceRuleDerivedStatus.applying,
            CustomerPriceRuleDerivedStatus.notYetEffective,
            CustomerPriceRuleDerivedStatus.needsReview,
          ],
          sources: const [
            CustomerPriceRuleSourceType.manual,
            CustomerPriceRuleSourceType.excelImport,
            CustomerPriceRuleSourceType.salesOrder,
          ],
          customerId: 'customer-1',
          productId: 'product-1',
          businessDate: DateTime(2026, 7, 16, 23, 59),
          cursor: ' opaque-cursor ',
          limit: 50,
        ),
      );

      expect(params, {
        'p_tenant_id': 'tenant-1',
        'p_business_date': '2026-07-16',
        'p_q': 'vaccine',
        'p_quick_filter': 'below_floor',
        'p_statuses': ['applying', 'not_yet_effective', 'needs_review'],
        'p_sources': ['manual', 'excel_import', 'sales_order'],
        'p_customer_id': 'customer-1',
        'p_product_id': 'product-1',
        'p_cursor': 'opaque-cursor',
        'p_limit': 50,
      });
      expect(params, isNot(contains('p_actor_id')));
    },
  );

  test('default empty status and source filters map to null', () {
    final params = CustomerPriceRuleSearchRpcMapper.params(_query());

    expect(params['p_statuses'], isNull);
    expect(params['p_sources'], isNull);
    expect(params['p_quick_filter'], 'all');
  });

  test('search mapper maps mixed page, snapshots, warning, and actions', () {
    final result = CustomerPriceRuleSearchRpcMapper.resultFromJson(
      _searchResultJson(),
    );

    expect(result.page.hasMore, isTrue);
    expect(result.page.nextCursor, 'cursor-2');
    expect(result.availableActions, ['create_manual', 'import']);
    expect(result.page.items, hasLength(2));
    final first = result.page.items.first;
    expect(first.sourceType, CustomerPriceRuleSourceType.manual);
    expect(first.derivedStatus, CustomerPriceRuleDerivedStatus.applying);
    expect(first.productUnit.productReferenceId, 'VAC-001');
    expect(first.productUnit.sku, 'VAC-BTL');
    expect(first.price.amountMinor, 125000);
    expect(first.validationOutcome.warningCodes, ['below_floor_price']);
    expect(first.validationOutcome.floorPrice, isNull);
    expect(first.validationOutcome.floorPriceHidden, isTrue);
    expect(
      result.page.items.last.derivedStatus,
      CustomerPriceRuleDerivedStatus.notYetEffective,
    );
  });

  test(
    'read gateway calls exact RPC and maps malformed money to SYSTEM_ERROR',
    () async {
      final supabase = FakePricingRpcSupabase()
        ..registerHandler('search_customer_price_rules', (_) async {
          final response = _searchResultJson();
          final items = response['items']! as List<dynamic>;
          final first = items.first as Map<String, dynamic>;
          first['price'] = {'amount_minor': 125000.5, 'currency_code': 'VND'};
          return response;
        });
      final gateway = SupabaseCustomerPriceRuleReadGateway(
        rpcClient: SupabaseSchemaRpcClient(
          supabase: supabase,
          schema: 'pricing',
          mapError: (error, [stackTrace]) => RpcException(error.toString()),
        ),
      );

      await expectLater(
        gateway.searchCustomerPriceRules(_query()),
        throwsA(
          isA<PricingBlockedException>().having(
            (error) => error.code,
            'code',
            PricingBlockedCodes.systemError,
          ),
        ),
      );
      expect(supabase.calls.single.functionName, 'search_customer_price_rules');
      expect(supabase.calls.single.params, isNot(contains('p_actor_id')));
    },
  );

  test('read gateway maps RPC technical errors to SYSTEM_ERROR', () async {
    final supabase = FakePricingRpcSupabase()
      ..registerHandler(
        'search_customer_price_rules',
        (_) async => throw StateError('database unavailable'),
      );
    final gateway = SupabaseCustomerPriceRuleReadGateway(
      rpcClient: SupabaseSchemaRpcClient(
        supabase: supabase,
        schema: 'pricing',
        mapError: (error, [stackTrace]) => RpcException(error.toString()),
      ),
    );

    await expectLater(
      gateway.searchCustomerPriceRules(_query()),
      throwsA(
        isA<PricingBlockedException>().having(
          (error) => error.code,
          'code',
          PricingBlockedCodes.systemError,
        ),
      ),
    );
  });

  test('read gateway maps malformed page envelope to SYSTEM_ERROR', () async {
    final supabase = FakePricingRpcSupabase()
      ..registerHandler(
        'search_customer_price_rules',
        (_) async => {
          'items': <Map<String, dynamic>>[],
          'next_cursor': null,
          'has_more': 'false',
          'available_actions': <String>[],
        },
      );
    final gateway = _gateway(supabase);

    await expectLater(
      gateway.searchCustomerPriceRules(_query()),
      throwsA(
        isA<PricingBlockedException>().having(
          (error) => error.code,
          'code',
          PricingBlockedCodes.systemError,
        ),
      ),
    );
  });

  test(
    'read gateway maps malformed enum and required fields to SYSTEM_ERROR',
    () async {
      final supabase = FakePricingRpcSupabase()
        ..registerHandler('search_customer_price_rules', (_) async {
          final response = _searchResultJson();
          final items = response['items']! as List<dynamic>;
          final first = items.first as Map<String, dynamic>;
          first['derived_status'] = 'unexpected_status';
          first.remove('updated_at');
          return response;
        });
      final gateway = _gateway(supabase);

      await expectLater(
        gateway.searchCustomerPriceRules(_query()),
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

  test('read gateway rejects leaked floor amount as SYSTEM_ERROR', () async {
    final supabase = FakePricingRpcSupabase()
      ..registerHandler('search_customer_price_rules', (_) async {
        final response = _searchResultJson();
        final items = response['items']! as List<dynamic>;
        final first = items.first as Map<String, dynamic>;
        final validation = first['validation_outcome']! as Map<String, dynamic>;
        validation['floor_price'] = {
          'amount_minor': 100000,
          'currency_code': 'VND',
        };
        return response;
      });

    await expectLater(
      _gateway(supabase).searchCustomerPriceRules(_query()),
      throwsA(
        isA<PricingBlockedException>().having(
          (error) => error.code,
          'code',
          PricingBlockedCodes.systemError,
        ),
      ),
    );
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

SearchCustomerPriceRulesQuery _query() => SearchCustomerPriceRulesQuery(
  tenantId: 'tenant-1',
  businessDate: DateTime.utc(2026, 7, 16),
);

Map<String, dynamic> _searchResultJson() => {
  'items': [
    {
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
      'price': {'amount_minor': 125000, 'currency_code': 'VND'},
      'effective_period': {
        'effective_from': '2026-07-01',
        'effective_to': '2026-07-31',
      },
      'rule_type': 'special_price',
      'source_type': 'manual',
      'persisted_status': 'active',
      'derived_status': 'applying',
      'validation_outcome': {
        'outcome': 'warning',
        'warning_codes': ['below_floor_price'],
        'blocking_codes': <String>[],
        'list_price': {'amount_minor': 150000, 'currency_code': 'VND'},
        'floor_price': null,
        'floor_price_hidden': true,
      },
      'updated_at': '2026-07-16T10:30:00+07:00',
    },
    {
      'id': 'rule-2',
      'customer': {
        'customer_id': 'customer-2',
        'display_name': 'Clinic B',
        'status': 'active',
      },
      'product_unit': {
        'product_id': 'product-2',
        'product_name': 'Medicine',
        'product_unit_id': 'unit-2',
        'unit_name': 'Box',
        'sellable_status': 'active',
        'product_reference_id': null,
        'sku': null,
      },
      'price': {'amount_minor': 200000, 'currency_code': 'VND'},
      'effective_period': {
        'effective_from': '2026-08-01',
        'effective_to': null,
      },
      'rule_type': 'special_price',
      'source_type': 'excel_import',
      'persisted_status': 'active',
      'derived_status': 'not_yet_effective',
      'validation_outcome': {
        'outcome': 'notChecked',
        'warning_codes': <String>[],
        'blocking_codes': <String>[],
        'list_price': null,
        'floor_price': null,
        'floor_price_hidden': false,
      },
      'updated_at': '2026-07-15T00:00:00Z',
    },
  ],
  'next_cursor': 'cursor-2',
  'has_more': true,
  'available_actions': ['create_manual', 'import'],
};
