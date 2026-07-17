import 'package:get_it/get_it.dart';
import 'package:test/test.dart';
import 'package:vet45_pricing_application/application.dart';
import 'package:vet45_pricing_domain/domain.dart';
import 'package:vet45_pricing_infrastructure/infrastructure.dart';
import 'package:vet45_shared_application/application.dart';
import 'package:vet45_shared_testing/shared_testing.dart';

import '../support/fake_pricing_rpc_supabase.dart';
import '../support/pricing_update_fixtures.dart';

void main() {
  test('startup binds update context and executes two S5 RPCs', () async {
    final container = GetIt.asNewInstance();
    final supabase = FakePricingRpcSupabase()
      ..registerHandler(
        'get_customer_price_rule_update_context',
        (_) async => updateContextJson(),
      )
      ..registerHandler(
        'update_customer_price_rule',
        (_) async => updateDetailJson(version: 4, amountMinor: 95000),
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
      UpdateCustomerPriceRuleCommand(
        tenantId: 'caller-tenant',
        actorId: 'caller-user',
        ruleId: updateRuleId,
        expectedVersion: 3,
        rulePriceMinor: 95000,
        effectiveFrom: DateTime.utc(2026, 7, 16),
        note: 'Updated note',
        // Fixture context is below floor with override allowed; handler
        // blocks below-floor updates unless acknowledged.
        acknowledgeFloorWarning: true,
      ),
    );

    expect(result.version, 4);
    expect(permissionChecker.required, [
      PricingPermissions.updateCustomerPriceRule,
    ]);
    expect(tenantAccessChecker.checked, ['context-tenant']);
    expect(supabase.calls.map((c) => c.functionName), [
      'get_customer_price_rule_update_context',
      'update_customer_price_rule',
    ]);
    for (final call in supabase.calls) {
      expect(call.params?['p_tenant_id'], 'context-tenant');
      expect(call.params, isNot(contains('p_actor_id')));
    }
    final metadata = container.get<IAccessMetadataRegistry>().forType(
      UpdateCustomerPriceRuleCommand,
    );
    expect(metadata?.permission, PricingPermissions.updateCustomerPriceRule);
    expect(metadata?.requiresTenant, isTrue);
  });

  test('startup denies update before RPC when permission is missing', () async {
    final supabase = FakePricingRpcSupabase();
    final module = PricingStartup.initializeForTesting(
      supabase: supabase,
      executionContext: FakeExecutionContext(
        userId: 'user-1',
        tenantId: 'tenant-1',
      ),
      permissionChecker: FakePermissionChecker(
        deny: {PricingPermissions.updateCustomerPriceRule},
      ),
      tenantAccessChecker: FakeTenantAccessChecker(),
    );

    await expectLater(
      module.executeCommandAsync(_updateCommand()),
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

  test('startup denies update before RPC for inaccessible tenant', () async {
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
      module.executeCommandAsync(_updateCommand()),
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

UpdateCustomerPriceRuleCommand _updateCommand() =>
    UpdateCustomerPriceRuleCommand(
      tenantId: 'caller-tenant',
      actorId: 'caller-user',
      ruleId: updateRuleId,
      expectedVersion: 3,
      rulePriceMinor: 95000,
      effectiveFrom: DateTime.utc(2026, 7, 16),
      note: 'Updated note',
      acknowledgeFloorWarning: false,
    );
