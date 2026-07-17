import 'package:get_it/get_it.dart';
import 'package:test/test.dart';
import 'package:vet45_pricing_application/application.dart';
import 'package:vet45_pricing_domain/domain.dart';
import 'package:vet45_pricing_infrastructure/infrastructure.dart';
import 'package:vet45_shared_application/application.dart';
import 'package:vet45_shared_testing/shared_testing.dart';

import '../support/fake_pricing_rpc_supabase.dart';

void main() {
  test('startup resolves remembered price gateway and executes one RPC', () async {
    final container = GetIt.asNewInstance();
    final supabase = FakePricingRpcSupabase()
      ..registerHandler('save_remembered_price_from_order', (_) async {
        return {
          'request_id': '00000000-0000-4000-8000-000000000201',
          'result_type': 'created',
          'rule_id': '00000000-0000-4000-8000-000000000301',
          'rule_version': 1,
          'reason_code': null,
          'warnings': [],
          'is_replay': false,
        };
      });
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

    expect(container.get<IRememberedPriceGateway>(), isA<IRememberedPriceGateway>());

    final outcome = await module.executeCommandAsync(
      SaveRememberedPriceFromOrderCommand(
        tenantId: 'caller-tenant',
        actorId: 'caller-user',
        sourceOrderId: '00000000-0000-4000-8000-000000000101',
        sourceOrderLineId: '00000000-0000-4000-8000-000000000102',
        customerId: '00000000-0000-4000-8000-000000000103',
        productId: '00000000-0000-4000-8000-000000000104',
        productUnitId: '00000000-0000-4000-8000-000000000105',
        soldPriceMinor: 90000,
        currencyCode: 'VND',
        soldAt: DateTime.utc(2026, 7, 16, 1, 30),
        idempotencyKey: 'order-line-102',
      ),
    );

    expect(outcome.resultType, RememberedPriceResultType.created);
    expect(permissionChecker.required, [PricingPermissions.savePriceMemory]);
    expect(tenantAccessChecker.checked, ['context-tenant']);
    expect(supabase.calls.single.functionName, 'save_remembered_price_from_order');
    expect(supabase.calls.single.params?['p_tenant_id'], 'context-tenant');
    expect(supabase.calls.single.params, isNot(contains('p_actor_id')));

    final metadata = container.get<IAccessMetadataRegistry>().forType(
      SaveRememberedPriceFromOrderCommand,
    );
    expect(metadata?.permission, PricingPermissions.savePriceMemory);
    expect(metadata?.requiresTenant, isTrue);
  });

  test('startup denies remembered price before RPC when permission is missing',
      () async {
    final supabase = FakePricingRpcSupabase();
    final module = PricingStartup.initializeForTesting(
      supabase: supabase,
      executionContext: FakeExecutionContext(
        userId: 'user-1',
        tenantId: 'tenant-1',
      ),
      permissionChecker: FakePermissionChecker(
        deny: {PricingPermissions.savePriceMemory},
      ),
      tenantAccessChecker: FakeTenantAccessChecker(),
    );

    await expectLater(
      module.executeCommandAsync(_memoryCommand()),
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

  test('startup denies remembered price before RPC for inaccessible tenant',
      () async {
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
      module.executeCommandAsync(_memoryCommand()),
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

SaveRememberedPriceFromOrderCommand _memoryCommand() =>
    SaveRememberedPriceFromOrderCommand(
      tenantId: 'caller-tenant',
      actorId: 'caller-user',
      sourceOrderId: '00000000-0000-4000-8000-000000000101',
      sourceOrderLineId: '00000000-0000-4000-8000-000000000102',
      customerId: '00000000-0000-4000-8000-000000000103',
      productId: '00000000-0000-4000-8000-000000000104',
      productUnitId: '00000000-0000-4000-8000-000000000105',
      soldPriceMinor: 90000,
      currencyCode: 'VND',
      soldAt: DateTime.utc(2026, 7, 16, 1, 30),
      idempotencyKey: 'order-line-102',
    );
