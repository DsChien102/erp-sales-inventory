import 'package:get_it/get_it.dart';
import 'package:test/test.dart';
import 'package:vet45_pricing_application/application.dart';
import 'package:vet45_pricing_domain/domain.dart';
import 'package:vet45_pricing_infrastructure/infrastructure.dart';
import 'package:vet45_shared_application/application.dart';
import 'package:vet45_shared_testing/shared_testing.dart';

import '../support/fake_pricing_rpc_supabase.dart';
import '../support/pricing_disable_fixtures.dart';

const _disableRuleId = '00000000-0000-4000-8000-000000000001';

void main() {
  test('startup binds disable context and executes one S6 RPC', () async {
    final container = GetIt.asNewInstance();
    final supabase = FakePricingRpcSupabase()
      ..registerHandler(
        'disable_customer_price_rule',
        (_) async => disableDetailJson(),
      );
    final permissionChecker = FakePermissionChecker();
    final tenantAccessChecker = FakeTenantAccessChecker();
    final module = PricingStartup.initializeForTesting(
      container: container,
      supabase: supabase,
      executionContext: FakeExecutionContext(
        userId: 'context-user',
        tenantId: 'context-tenant',
      ),
      permissionChecker: permissionChecker,
      tenantAccessChecker: tenantAccessChecker,
    );

    final result = await module.executeCommandAsync(
      DisableCustomerPriceRuleCommand(
        tenantId: 'caller-tenant',
        actorId: 'caller-user',
        ruleId: _disableRuleId,
        expectedVersion: 3,
        reason: 'Kết thúc thỏa thuận',
      ),
    );

    expect(result.version, 4);
    expect(result.persistedStatus, CustomerPriceRuleStatus.disabled);
    expect(permissionChecker.required, [
      PricingPermissions.disableCustomerPriceRule,
    ]);
    expect(tenantAccessChecker.checked, ['context-tenant']);
    expect(supabase.calls.map((c) => c.functionName), [
      'disable_customer_price_rule',
    ]);
    expect(
      supabase.calls.single.params,
      containsPair('p_tenant_id', 'context-tenant'),
    );
    expect(supabase.calls.single.params, isNot(contains('p_actor_id')));
    final metadata = container.get<IAccessMetadataRegistry>().forType(
      DisableCustomerPriceRuleCommand,
    );
    expect(metadata?.permission, PricingPermissions.disableCustomerPriceRule);
    expect(metadata?.requiresTenant, isTrue);
  });

  test(
    'startup denies disable before RPC when permission is missing',
    () async {
      final supabase = FakePricingRpcSupabase();
      final module = PricingStartup.initializeForTesting(
        supabase: supabase,
        executionContext: FakeExecutionContext(
          userId: 'user-1',
          tenantId: 'tenant-1',
        ),
        permissionChecker: FakePermissionChecker(
          deny: {PricingPermissions.disableCustomerPriceRule},
        ),
        tenantAccessChecker: FakeTenantAccessChecker(),
      );

      await expectLater(
        module.executeCommandAsync(_disableCommand()),
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

  test('startup denies disable before RPC for inaccessible tenant', () async {
    final supabase = FakePricingRpcSupabase();
    final module = PricingStartup.initializeForTesting(
      supabase: supabase,
      executionContext: FakeExecutionContext(
        userId: 'user-1',
        tenantId: 'tenant-1',
      ),
      permissionChecker: FakePermissionChecker(),
      tenantAccessChecker: FakeTenantAccessChecker(deny: {'tenant-1'}),
    );

    await expectLater(
      module.executeCommandAsync(_disableCommand()),
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
}

DisableCustomerPriceRuleCommand _disableCommand() =>
    DisableCustomerPriceRuleCommand(
      tenantId: 'caller-tenant',
      actorId: 'caller-user',
      ruleId: _disableRuleId,
      expectedVersion: 3,
      reason: 'Kết thúc thỏa thuận',
    );
