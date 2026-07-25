import 'package:get_it/get_it.dart';
import 'package:test/test.dart';
import 'package:vet45_pricing_application/application.dart';
import 'package:vet45_pricing_domain/domain.dart';
import 'package:vet45_pricing_infrastructure/infrastructure.dart';
import 'package:vet45_shared_application/application.dart';
import 'package:vet45_shared_testing/shared_testing.dart';

import '../support/fake_pricing_rpc_supabase.dart';
import '../support/pricing_reenable_fixtures.dart';

const _ruleId = '00000000-0000-4000-8000-000000000001';

void main() {
  test(
    'startup binds precheck context and executes one S7 precheck RPC',
    () async {
      final container = GetIt.asNewInstance();
      final supabase = FakePricingRpcSupabase()
        ..registerHandler(
          'precheck_customer_price_rule_reenable',
          (_) async => reenablePrecheckJson(),
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

      final result = await module.executeQueryAsync(
        PrecheckCustomerPriceRuleReenableQuery(
          tenantId: 'caller-tenant',
          ruleId: _ruleId,
          expectedVersion: 4,
          businessDate: DateTime.utc(2026, 7, 16),
        ),
      );

      expect(result.precheckToken, reenableToken);
      expect(result.ruleVersion, 4);
      expect(permissionChecker.required, [
        PricingPermissions.reenableCustomerPriceRule,
      ]);
      expect(tenantAccessChecker.checked, ['context-tenant']);
      expect(
        supabase.calls.single.functionName,
        'precheck_customer_price_rule_reenable',
      );
      expect(supabase.calls.single.params?['p_tenant_id'], 'context-tenant');
      expect(supabase.calls.single.params, isNot(contains('p_actor_id')));
      expect(
        container
            .isRegistered<PrecheckCustomerPriceRuleReenableQueryValidator>(),
        isTrue,
      );
      final metadata = container.get<IAccessMetadataRegistry>().forType(
        PrecheckCustomerPriceRuleReenableQuery,
      );
      expect(
        metadata?.permission,
        PricingPermissions.reenableCustomerPriceRule,
      );
      expect(metadata?.requiresTenant, isTrue);
    },
  );

  test(
    'startup binds reenable context and executes one S7 commit RPC',
    () async {
      final supabase = FakePricingRpcSupabase()
        ..registerHandler(
          'reenable_customer_price_rule',
          (_) async => reenableDetailJson(),
        );
      final module = PricingStartup.initializeForTesting(
        supabase: supabase,
        executionContext: FakeExecutionContext(
          userId: 'context-user',
          tenantId: 'context-tenant',
        ),
        permissionChecker: FakePermissionChecker(),
        tenantAccessChecker: FakeTenantAccessChecker(),
      );

      final result = await module.executeCommandAsync(
        ReenableCustomerPriceRuleCommand(
          tenantId: 'caller-tenant',
          actorId: 'caller-user',
          ruleId: _ruleId,
          expectedVersion: 4,
          businessDate: DateTime.utc(2026, 7, 16),
          precheckToken: reenableToken,
          acknowledgeFloorWarning: true,
        ),
      );

      expect(result.persistedStatus, CustomerPriceRuleStatus.active);
      expect(result.version, 5);
      expect(
        supabase.calls.single.functionName,
        'reenable_customer_price_rule',
      );
      expect(supabase.calls.single.params?['p_tenant_id'], 'context-tenant');
      expect(supabase.calls.single.params, isNot(contains('p_actor_id')));
    },
  );

  test(
    'startup denies precheck before RPC when permission is missing',
    () async {
      final supabase = FakePricingRpcSupabase();
      final module = PricingStartup.initializeForTesting(
        supabase: supabase,
        executionContext: FakeExecutionContext(
          userId: 'user-1',
          tenantId: 'tenant-1',
        ),
        permissionChecker: FakePermissionChecker(
          deny: {PricingPermissions.reenableCustomerPriceRule},
        ),
        tenantAccessChecker: FakeTenantAccessChecker(),
      );

      await expectLater(
        module.executeQueryAsync(_precheckQuery()),
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
    'startup denies reenable before RPC when permission is missing',
    () async {
      final supabase = FakePricingRpcSupabase();
      final module = PricingStartup.initializeForTesting(
        supabase: supabase,
        executionContext: FakeExecutionContext(
          userId: 'user-1',
          tenantId: 'tenant-1',
        ),
        permissionChecker: FakePermissionChecker(
          deny: {PricingPermissions.reenableCustomerPriceRule},
        ),
        tenantAccessChecker: FakeTenantAccessChecker(),
      );

      await expectLater(
        module.executeCommandAsync(_reenableCommand()),
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

  test('startup denies precheck before RPC for inaccessible tenant', () async {
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
      module.executeQueryAsync(_precheckQuery()),
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

  test('startup denies reenable before RPC for inaccessible tenant', () async {
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
      module.executeCommandAsync(_reenableCommand()),
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

PrecheckCustomerPriceRuleReenableQuery _precheckQuery() =>
    PrecheckCustomerPriceRuleReenableQuery(
      tenantId: 'caller-tenant',
      ruleId: _ruleId,
      expectedVersion: 4,
      businessDate: DateTime.utc(2026, 7, 16),
    );

ReenableCustomerPriceRuleCommand _reenableCommand() =>
    ReenableCustomerPriceRuleCommand(
      tenantId: 'caller-tenant',
      actorId: 'caller-user',
      ruleId: _ruleId,
      expectedVersion: 4,
      businessDate: DateTime.utc(2026, 7, 16),
      precheckToken: reenableToken,
      acknowledgeFloorWarning: true,
    );
