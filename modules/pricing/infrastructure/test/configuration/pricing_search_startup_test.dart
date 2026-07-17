import 'package:get_it/get_it.dart';
import 'package:test/test.dart';
import 'package:vet45_pricing_application/application.dart';
import 'package:vet45_pricing_domain/domain.dart';
import 'package:vet45_pricing_infrastructure/infrastructure.dart';
import 'package:vet45_shared_application/application.dart';
import 'package:vet45_shared_testing/shared_testing.dart';

import '../support/fake_pricing_rpc_supabase.dart';

void main() {
  test(
    'startup binds tenant and checks generated query access before RPC',
    () async {
      final container = GetIt.asNewInstance();
      final supabase = FakePricingRpcSupabase()
        ..registerHandler(
          'search_customer_price_rules',
          (_) async => _emptySearchResult(),
        );
      final permissionChecker = FakePermissionChecker();
      final tenantAccessChecker = FakeTenantAccessChecker();
      final module = PricingStartup.initializeForTesting(
        container: container,
        supabase: supabase,
        executionContext: FakeExecutionContext(
          userId: 'user-1',
          tenantId: 'context-tenant',
        ),
        permissionChecker: permissionChecker,
        tenantAccessChecker: tenantAccessChecker,
      );

      final result = await module.executeQueryAsync(
        SearchCustomerPriceRulesQuery(
          tenantId: 'caller-tenant',
          businessDate: DateTime(2026, 7, 16, 22),
        ),
      );

      expect(result.page.items, isEmpty);
      expect(supabase.calls.single.functionName, 'search_customer_price_rules');
      expect(supabase.calls.single.params?['p_tenant_id'], 'context-tenant');
      expect(supabase.calls.single.params?['p_business_date'], '2026-07-16');
      expect(supabase.calls.single.params, isNot(contains('p_actor_id')));
      expect(permissionChecker.required, [
        PricingPermissions.viewCustomerPriceRule,
      ]);
      expect(tenantAccessChecker.checked, ['context-tenant']);

      final metadata = container.get<IAccessMetadataRegistry>().forType(
        SearchCustomerPriceRulesQuery,
      );
      expect(metadata?.permission, PricingPermissions.viewCustomerPriceRule);
      expect(metadata?.requiresTenant, isTrue);
      expect(
        container.isRegistered<SearchCustomerPriceRulesQueryValidator>(),
        isTrue,
      );
    },
  );

  test('startup binds tenant and checks detail access before RPC', () async {
    final container = GetIt.asNewInstance();
    final supabase = FakePricingRpcSupabase()
      ..registerHandler(
        'get_customer_price_rule_detail',
        (_) async => _detailJson(),
      );
    final permissionChecker = FakePermissionChecker();
    final tenantAccessChecker = FakeTenantAccessChecker();
    final module = PricingStartup.initializeForTesting(
      container: container,
      supabase: supabase,
      executionContext: FakeExecutionContext(
        userId: 'user-1',
        tenantId: 'context-tenant',
      ),
      permissionChecker: permissionChecker,
      tenantAccessChecker: tenantAccessChecker,
    );

    final result = await module.executeQueryAsync(
      GetCustomerPriceRuleDetailQuery(
        tenantId: 'caller-tenant',
        ruleId: '00000000-0000-4000-8000-000000000001',
        businessDate: DateTime(2026, 7, 16, 22),
      ),
    );

    expect(result.id, '00000000-0000-4000-8000-000000000001');
    expect(
      supabase.calls.single.functionName,
      'get_customer_price_rule_detail',
    );
    expect(supabase.calls.single.params?['p_tenant_id'], 'context-tenant');
    expect(supabase.calls.single.params?['p_business_date'], '2026-07-16');
    expect(supabase.calls.single.params, isNot(contains('p_actor_id')));
    expect(permissionChecker.required, [
      PricingPermissions.viewCustomerPriceRule,
    ]);
    expect(tenantAccessChecker.checked, ['context-tenant']);

    final metadata = container.get<IAccessMetadataRegistry>().forType(
      GetCustomerPriceRuleDetailQuery,
    );
    expect(metadata?.permission, PricingPermissions.viewCustomerPriceRule);
    expect(metadata?.requiresTenant, isTrue);
    expect(
      container.isRegistered<GetCustomerPriceRuleDetailQueryValidator>(),
      isTrue,
    );
  });

  test(
    'startup denies detail before RPC when view permission is missing',
    () async {
      final supabase = FakePricingRpcSupabase();
      final module = PricingStartup.initializeForTesting(
        supabase: supabase,
        executionContext: FakeExecutionContext(tenantId: 'tenant-1'),
        permissionChecker: FakePermissionChecker(
          deny: {PricingPermissions.viewCustomerPriceRule},
        ),
        tenantAccessChecker: FakeTenantAccessChecker(),
      );

      await expectLater(
        module.executeQueryAsync(_detailQuery()),
        throwsA(
          isA<PricingBlockedException>().having(
            (error) => error.code,
            'code',
            PricingBlockedCodes.noPermission,
          ),
        ),
      );
      expect(supabase.calls, isEmpty);
    },
  );

  test('startup denies detail before RPC for inaccessible tenant', () async {
    final supabase = FakePricingRpcSupabase();
    final module = PricingStartup.initializeForTesting(
      supabase: supabase,
      executionContext: FakeExecutionContext(tenantId: 'tenant-1'),
      permissionChecker: FakePermissionChecker(),
      tenantAccessChecker: FakeTenantAccessChecker(deny: {'tenant-1'}),
    );

    await expectLater(
      module.executeQueryAsync(_detailQuery()),
      throwsA(
        isA<PricingBlockedException>().having(
          (error) => error.code,
          'code',
          PricingBlockedCodes.noPermission,
        ),
      ),
    );
    expect(supabase.calls, isEmpty);
  });

  test(
    'startup maps missing detail execution context to NO_PERMISSION',
    () async {
      final supabase = FakePricingRpcSupabase();
      final module = PricingStartup.initializeForTesting(
        supabase: supabase,
        executionContext: FakeExecutionContext(failTenant: true),
        permissionChecker: FakePermissionChecker(),
        tenantAccessChecker: FakeTenantAccessChecker(),
      );

      await expectLater(
        module.executeQueryAsync(_detailQuery()),
        throwsA(
          isA<PricingBlockedException>().having(
            (error) => error.code,
            'code',
            PricingBlockedCodes.noPermission,
          ),
        ),
      );
      expect(supabase.calls, isEmpty);
    },
  );

  test(
    'startup denies search before RPC when view permission is missing',
    () async {
      final supabase = FakePricingRpcSupabase();
      final module = PricingStartup.initializeForTesting(
        supabase: supabase,
        executionContext: FakeExecutionContext(tenantId: 'tenant-1'),
        permissionChecker: FakePermissionChecker(
          deny: {PricingPermissions.viewCustomerPriceRule},
        ),
        tenantAccessChecker: FakeTenantAccessChecker(),
      );

      await expectLater(
        module.executeQueryAsync(_query()),
        throwsA(
          isA<PricingBlockedException>().having(
            (error) => error.code,
            'code',
            PricingBlockedCodes.noPermission,
          ),
        ),
      );
      expect(supabase.calls, isEmpty);
    },
  );

  test('startup denies search before RPC for inaccessible tenant', () async {
    final supabase = FakePricingRpcSupabase();
    final module = PricingStartup.initializeForTesting(
      supabase: supabase,
      executionContext: FakeExecutionContext(tenantId: 'tenant-1'),
      permissionChecker: FakePermissionChecker(),
      tenantAccessChecker: FakeTenantAccessChecker(deny: {'tenant-1'}),
    );

    await expectLater(
      module.executeQueryAsync(_query()),
      throwsA(
        isA<PricingBlockedException>().having(
          (error) => error.code,
          'code',
          PricingBlockedCodes.noPermission,
        ),
      ),
    );
    expect(supabase.calls, isEmpty);
  });

  test(
    'startup maps missing query execution context to NO_PERMISSION',
    () async {
      final supabase = FakePricingRpcSupabase();
      final module = PricingStartup.initializeForTesting(
        supabase: supabase,
        executionContext: FakeExecutionContext(failTenant: true),
        permissionChecker: FakePermissionChecker(),
        tenantAccessChecker: FakeTenantAccessChecker(),
      );

      await expectLater(
        module.executeQueryAsync(_query()),
        throwsA(
          isA<PricingBlockedException>().having(
            (error) => error.code,
            'code',
            PricingBlockedCodes.noPermission,
          ),
        ),
      );
      expect(supabase.calls, isEmpty);
    },
  );
}

SearchCustomerPriceRulesQuery _query() => SearchCustomerPriceRulesQuery(
  tenantId: 'caller-tenant',
  businessDate: DateTime.utc(2026, 7, 16),
);

GetCustomerPriceRuleDetailQuery _detailQuery() =>
    GetCustomerPriceRuleDetailQuery(
      tenantId: 'caller-tenant',
      ruleId: '00000000-0000-4000-8000-000000000001',
      businessDate: DateTime.utc(2026, 7, 16),
    );

Map<String, dynamic> _emptySearchResult() => {
  'items': <Map<String, dynamic>>[],
  'next_cursor': null,
  'has_more': false,
  'available_actions': <String>[],
};

Map<String, dynamic> _detailJson() => {
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
  },
  'price': {'amount_minor': 90000, 'currency_code': 'VND'},
  'effective_period': {'effective_from': '2026-07-01', 'effective_to': null},
  'rule_type': 'special_price',
  'source_type': 'manual',
  'persisted_status': 'active',
  'derived_status': 'applying',
  'validation_outcome': {
    'outcome': 'notChecked',
    'warning_codes': <String>[],
    'blocking_codes': <String>[],
    'floor_price_hidden': true,
  },
  'reference_health': {
    'customer_state': 'valid',
    'product_unit_state': 'valid',
    'price_band_state': 'current',
    'issue_codes': <String>[],
    'used_stored_price_band_snapshot': false,
  },
  'source_trace': {'hidden': false},
  'created_by': 'user-1',
  'created_at': '2026-07-16T00:00:00Z',
  'updated_by': 'user-1',
  'updated_at': '2026-07-16T00:00:00Z',
  'version': 1,
  'available_actions': [
    CustomerPriceRuleAvailableActions.edit,
    CustomerPriceRuleAvailableActions.disable,
    CustomerPriceRuleAvailableActions.history,
  ],
};
