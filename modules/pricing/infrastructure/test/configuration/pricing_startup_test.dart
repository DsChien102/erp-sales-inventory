import 'package:test/test.dart';
import 'package:vet45_pricing_application/application.dart';
import 'package:vet45_pricing_domain/domain.dart';
import 'package:vet45_pricing_infrastructure/infrastructure.dart';
import 'package:vet45_shared_testing/shared_testing.dart';

import '../support/fake_pricing_rpc_supabase.dart';

void main() {
  test(
    'startup executes create through scoped mediator and two RPCs',
    () async {
      final supabase = FakePricingRpcSupabase();
      final permissionChecker = FakePermissionChecker();
      final tenantAccessChecker = FakeTenantAccessChecker();
      supabase
        ..registerHandler('get_customer_price_rule_create_context', (_) async {
          return _createContextJson();
        })
        ..registerHandler('create_customer_price_rule', (_) async {
          return _createResultJson();
        });
      final module = PricingStartup.initializeForTesting(
        supabase: supabase,
        executionContext: FakeExecutionContext(
          userId: 'user-1',
          tenantId: 'tenant-1',
        ),
        permissionChecker: permissionChecker,
        tenantAccessChecker: tenantAccessChecker,
      );

      final result = await module.executeCommandAsync(_command());

      expect(result.rule.id, 'rule-1');
      expect(permissionChecker.required, [
        PricingPermissions.createCustomerPriceRule,
      ]);
      expect(tenantAccessChecker.checked, ['tenant-1']);
      expect(supabase.calls.first.params?['p_tenant_id'], 'tenant-1');
      expect(supabase.calls.map((call) => call.functionName), [
        'get_customer_price_rule_create_context',
        'create_customer_price_rule',
      ]);
      expect(supabase.calls.last.params, isNot(contains('p_actor_id')));
    },
  );

  test('startup denies create before RPC when permission is missing', () async {
    final supabase = FakePricingRpcSupabase();
    final module = PricingStartup.initializeForTesting(
      supabase: supabase,
      executionContext: FakeExecutionContext(
        userId: 'user-1',
        tenantId: 'tenant-1',
      ),
      permissionChecker: FakePermissionChecker(
        deny: {PricingPermissions.createCustomerPriceRule},
      ),
      tenantAccessChecker: FakeTenantAccessChecker(),
    );

    await expectLater(
      module.executeCommandAsync(_command()),
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

  test('startup denies create before RPC for inaccessible tenant', () async {
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
      module.executeCommandAsync(_command()),
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

  test('startup maps malformed RPC result to SYSTEM_ERROR', () async {
    final supabase = FakePricingRpcSupabase()
      ..registerHandler(
        'get_customer_price_rule_create_context',
        (_) async => _createContextJson(),
      )
      ..registerHandler(
        'create_customer_price_rule',
        (_) async => <String, dynamic>{'rule': <String, dynamic>{}},
      );
    final module = PricingStartup.initializeForTesting(
      supabase: supabase,
      executionContext: FakeExecutionContext(
        userId: 'user-1',
        tenantId: 'tenant-1',
      ),
      permissionChecker: FakePermissionChecker(),
      tenantAccessChecker: FakeTenantAccessChecker(),
    );

    await expectLater(
      module.executeCommandAsync(_command()),
      throwsA(
        isA<PricingBlockedException>().having(
          (error) => error.code,
          'code',
          PricingBlockedCodes.systemError,
        ),
      ),
    );
  });

  test('startup maps missing execution context to NO_PERMISSION', () async {
    final module = PricingStartup.initializeForTesting(
      supabase: FakePricingRpcSupabase(),
      executionContext: FakeExecutionContext(failTenant: true),
      permissionChecker: FakePermissionChecker(),
      tenantAccessChecker: FakeTenantAccessChecker(),
    );

    await expectLater(
      module.executeCommandAsync(_command()),
      throwsA(
        isA<PricingBlockedException>().having(
          (error) => error.code,
          'code',
          PricingBlockedCodes.noPermission,
        ),
      ),
    );
  });
}

CreateCustomerPriceRuleCommand _command() => CreateCustomerPriceRuleCommand(
  tenantId: 'caller-controlled-tenant',
  actorId: 'caller-controlled-user',
  customerId: 'customer-1',
  productId: 'product-1',
  productUnitId: 'unit-1',
  rulePriceMinor: 125000,
  currencyCode: 'VND',
  effectiveFrom: DateTime.utc(2026, 7, 16),
  acknowledgeFloorWarning: false,
  idempotencyKey: 'idem-1',
);

Map<String, dynamic> _createContextJson() => {
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
    'floor_price_hidden': false,
    'is_below_floor': false,
  },
  'can_override_floor': false,
  'has_conflicting_rule': false,
  'idempotency_key_exists': false,
  'conflicting_rule_id': null,
};

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
    },
    'price': {'amount_minor': 125000, 'currency_code': 'VND'},
    'effective_period': {'effective_from': '2026-07-16', 'effective_to': null},
    'rule_type': 'special_price',
    'source_type': 'manual',
    'persisted_status': 'active',
    'derived_status': 'applying',
    'validation_outcome': {
      'outcome': 'notChecked',
      'warning_codes': <String>[],
      'blocking_codes': <String>[],
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
  'warnings': <Map<String, dynamic>>[],
};
