import 'package:test/test.dart';
import 'package:vet45_adapters/vet45_adapters.dart';
import 'package:vet45_pricing_application/application.dart';
import 'package:vet45_pricing_domain/domain.dart';
import 'package:vet45_pricing_infrastructure/src/domain/customer_price_rule/customer_price_rule_history_rpc_mapper.dart';
import 'package:vet45_pricing_infrastructure/src/domain/customer_price_rule/supabase_customer_price_rule_read_gateway.dart';
import 'package:vet45_shared_infrastructure/infrastructure.dart';

import '../../support/fake_pricing_rpc_supabase.dart';

void main() {
  test('history params use exact RPC keys', () {
    final params = CustomerPriceRuleHistoryRpcMapper.params(
      GetCustomerPriceRuleHistoryQuery(
        tenantId: 'tenant-1',
        ruleId: '00000000-0000-4000-8000-000000000001',
        cursor: 'opaque-cursor',
        limit: 25,
      ),
    );

    expect(params, {
      'p_tenant_id': 'tenant-1',
      'p_rule_id': '00000000-0000-4000-8000-000000000001',
      'p_cursor': 'opaque-cursor',
      'p_limit': 25,
    });
  });

  test('maps memory activity with traces, UTC, and deep immutability', () {
    final page = CustomerPriceRuleHistoryRpcMapper.pageFromJson(
      _pageJson(
        items: [
          _activityJson(
            activityType: 'memory_updated',
            sourceType: 'sales_order',
            oldValue: {
              'version': 3,
              'nested': {'a': 1},
            },
            newValue: {
              'version': 4,
              'tags': ['x'],
            },
            sourceTrace: {
              'import_id': null,
              'import_row_id': null,
              'order_id': '00000000-0000-4000-8000-000000000201',
              'order_line_id': '00000000-0000-4000-8000-000000000202',
              'memory_request_id': '00000000-0000-4000-8000-000000000203',
              'sold_at': '2026-07-16T09:00:00+07:00',
            },
            sensitiveValuesHidden: true,
          ),
        ],
      ),
    );

    final item = page.items.single;
    expect(item.activityType, CustomerPriceRuleActivityType.memoryUpdated);
    expect(item.sourceType, CustomerPriceRuleSourceType.salesOrder);
    expect(item.sourceTrace.orderId, '00000000-0000-4000-8000-000000000201');
    expect(item.sourceTrace.soldAt, DateTime.utc(2026, 7, 16, 2));
    expect(item.createdAt.isUtc, isTrue);
    expect(() => page.items.add(item), throwsUnsupportedError);
    expect(() => (item.newValue)['version'] = 9, throwsUnsupportedError);
    expect(
      () => (item.newValue['tags'] as List).add('y'),
      throwsUnsupportedError,
    );
    expect(
      () => ((item.oldValue!['nested'] as Map)['a'] = 2),
      throwsUnsupportedError,
    );
  });

  for (final entry in {
    'created': CustomerPriceRuleActivityType.created,
    'updated': CustomerPriceRuleActivityType.updated,
    'disabled': CustomerPriceRuleActivityType.disabled,
    'reenabled': CustomerPriceRuleActivityType.reenabled,
    'import_created': CustomerPriceRuleActivityType.importCreated,
    'import_updated': CustomerPriceRuleActivityType.importUpdated,
    'memory_created': CustomerPriceRuleActivityType.memoryCreated,
    'memory_updated': CustomerPriceRuleActivityType.memoryUpdated,
  }.entries) {
    test('maps activity_type ${entry.key}', () {
      final page = CustomerPriceRuleHistoryRpcMapper.pageFromJson(
        _pageJson(
          items: [
            _activityJson(
              activityType: entry.key,
              oldValue: entry.key == 'created' || entry.key.startsWith('import')
                  ? null
                  : {'version': 1},
            ),
          ],
        ),
      );
      expect(page.items.single.activityType, entry.value);
    });
  }

  test('maps system actor fallback shape', () {
    final page = CustomerPriceRuleHistoryRpcMapper.pageFromJson(
      _pageJson(
        items: [
          _activityJson(
            actor: {
              'actor_id': null,
              'display_name': 'System/Migration',
              'is_system_actor': true,
            },
            sourceType: 'migration',
            oldValue: null,
          ),
        ],
      ),
    );

    expect(page.items.single.actor.actorId, isNull);
    expect(page.items.single.actor.displayName, 'System/Migration');
    expect(page.items.single.actor.isSystemActor, isTrue);
  });

  test('fails closed on unknown activity type', () {
    expect(
      () => CustomerPriceRuleHistoryRpcMapper.pageFromJson(
        _pageJson(items: [_activityJson(activityType: 'unknown')]),
      ),
      throwsFormatException,
    );
  });

  test('fails closed when new_value is null', () {
    expect(
      () => CustomerPriceRuleHistoryRpcMapper.pageFromJson(
        _pageJson(
          items: [
            {..._activityJson(), 'new_value': null},
          ],
        ),
      ),
      throwsFormatException,
    );
  });

  test('fails closed when sensitive hidden but floor key leaks', () {
    expect(
      () => CustomerPriceRuleHistoryRpcMapper.pageFromJson(
        _pageJson(
          items: [
            _activityJson(
              newValue: {'version': 2, 'floor_price_minor': 100},
              sensitiveValuesHidden: true,
            ),
          ],
        ),
      ),
      throwsFormatException,
    );
  });

  test('gateway calls get_customer_price_rule_history and maps page', () async {
    final supabase = FakePricingRpcSupabase();
    supabase.registerHandler('get_customer_price_rule_history', (params) async {
      expect(params, {
        'p_tenant_id': 'tenant-1',
        'p_rule_id': '00000000-0000-4000-8000-000000000001',
        'p_cursor': null,
        'p_limit': 50,
      });
      return _pageJson();
    });
    final gateway = SupabaseCustomerPriceRuleReadGateway(
      rpcClient: SupabaseSchemaRpcClient(
        supabase: supabase,
        schema: 'pricing',
        mapError: (error, [stackTrace]) => RpcException(error.toString()),
      ),
    );

    final page = await gateway.getCustomerPriceRuleHistory(
      GetCustomerPriceRuleHistoryQuery(
        tenantId: 'tenant-1',
        ruleId: '00000000-0000-4000-8000-000000000001',
      ),
    );

    expect(page.items, hasLength(1));
    expect(
      supabase.calls.single.functionName,
      'get_customer_price_rule_history',
    );
  });

  test('gateway maps RpcException to typed blocked code', () async {
    final supabase = FakePricingRpcSupabase();
    supabase.registerHandler('get_customer_price_rule_history', (params) async {
      throw RpcException(
        'rpc failed: {"code":"NOT_FOUND","message":"missing","details":{}}',
      );
    });
    final gateway = SupabaseCustomerPriceRuleReadGateway(
      rpcClient: SupabaseSchemaRpcClient(
        supabase: supabase,
        schema: 'pricing',
        mapError: (error, [stackTrace]) => RpcException(error.toString()),
      ),
    );

    await expectLater(
      gateway.getCustomerPriceRuleHistory(
        GetCustomerPriceRuleHistoryQuery(
          tenantId: 'tenant-1',
          ruleId: '00000000-0000-4000-8000-000000000001',
        ),
      ),
      throwsA(
        isA<PricingBlockedException>().having(
          (error) => error.code,
          'code',
          PricingBlockedCodes.notFound,
        ),
      ),
    );
  });

  test('gateway maps FormatException to SYSTEM_ERROR', () async {
    final supabase = FakePricingRpcSupabase();
    supabase.registerHandler(
      'get_customer_price_rule_history',
      (params) async => {'items': 'bad', 'has_more': false},
    );
    final gateway = SupabaseCustomerPriceRuleReadGateway(
      rpcClient: SupabaseSchemaRpcClient(
        supabase: supabase,
        schema: 'pricing',
        mapError: (error, [stackTrace]) => RpcException(error.toString()),
      ),
    );

    await expectLater(
      gateway.getCustomerPriceRuleHistory(
        GetCustomerPriceRuleHistoryQuery(
          tenantId: 'tenant-1',
          ruleId: '00000000-0000-4000-8000-000000000001',
        ),
      ),
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

Map<String, dynamic> _pageJson({List<Map<String, dynamic>>? items}) => {
  'items': items ?? [_activityJson()],
  'next_cursor': null,
  'has_more': false,
};

Map<String, dynamic> _activityJson({
  String activityType = 'updated',
  String sourceType = 'manual',
  Map<String, Object?>? actor,
  Map<String, Object?>? oldValue = const {'version': 1},
  Map<String, Object?> newValue = const {'version': 2},
  Map<String, Object?>? sourceTrace,
  bool sensitiveValuesHidden = false,
}) => {
  'id': '00000000-0000-4000-8000-000000000010',
  'activity_type': activityType,
  'actor':
      actor ??
      {
        'actor_id': '00000000-0000-4000-8000-000000000099',
        'display_name': '5ef27a1c',
        'is_system_actor': false,
      },
  'source_type': sourceType,
  'old_value': oldValue,
  'new_value': newValue,
  'reason': null,
  'source_trace':
      sourceTrace ??
      {
        'import_id': null,
        'import_row_id': null,
        'order_id': null,
        'order_line_id': null,
        'memory_request_id': null,
        'sold_at': null,
      },
  'sensitive_values_hidden': sensitiveValuesHidden,
  'created_at': '2026-07-16T09:30:00.123456Z',
};
