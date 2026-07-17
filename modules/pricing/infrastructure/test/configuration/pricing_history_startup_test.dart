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
    'startup binds tenant and checks history access before RPC',
    () async {
      final container = GetIt.asNewInstance();
      final supabase = FakePricingRpcSupabase()
        ..registerHandler(
          'get_customer_price_rule_history',
          (_) async => _emptyHistoryPage(),
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
        GetCustomerPriceRuleHistoryQuery(
          tenantId: 'caller-tenant',
          ruleId: '00000000-0000-4000-8000-000000000001',
          cursor: 'opaque-cursor',
          limit: 25,
        ),
      );

      expect(result.items, isEmpty);
      expect(
        supabase.calls.single.functionName,
        'get_customer_price_rule_history',
      );
      expect(supabase.calls.single.params?['p_tenant_id'], 'context-tenant');
      expect(
        supabase.calls.single.params?['p_rule_id'],
        '00000000-0000-4000-8000-000000000001',
      );
      expect(supabase.calls.single.params?['p_cursor'], 'opaque-cursor');
      expect(supabase.calls.single.params?['p_limit'], 25);
      expect(permissionChecker.required, [
        PricingPermissions.viewCustomerPriceRuleHistory,
      ]);
      expect(tenantAccessChecker.checked, ['context-tenant']);

      final metadata = container.get<IAccessMetadataRegistry>().forType(
        GetCustomerPriceRuleHistoryQuery,
      );
      expect(
        metadata?.permission,
        PricingPermissions.viewCustomerPriceRuleHistory,
      );
      expect(metadata?.requiresTenant, isTrue);
      expect(
        container.isRegistered<GetCustomerPriceRuleHistoryQueryValidator>(),
        isTrue,
      );
      expect(container.isRegistered<IPricingReadGateway>(), isTrue);
    },
  );

  test(
    'startup denies history before RPC when view_history permission is missing',
    () async {
      final supabase = FakePricingRpcSupabase();
      final module = PricingStartup.initializeForTesting(
        supabase: supabase,
        executionContext: FakeExecutionContext(tenantId: 'tenant-1'),
        permissionChecker: FakePermissionChecker(
          deny: {PricingPermissions.viewCustomerPriceRuleHistory},
        ),
        tenantAccessChecker: FakeTenantAccessChecker(),
      );

      await expectLater(
        module.executeQueryAsync(_historyQuery()),
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

GetCustomerPriceRuleHistoryQuery _historyQuery() =>
    GetCustomerPriceRuleHistoryQuery(
      tenantId: 'caller-tenant',
      ruleId: '00000000-0000-4000-8000-000000000001',
    );

Map<String, dynamic> _emptyHistoryPage() => {
  'items': <Map<String, dynamic>>[],
  'next_cursor': null,
  'has_more': false,
};
