import 'package:test/test.dart';
import 'package:vet45_pricing_application/application.dart';
import 'package:vet45_pricing_infrastructure/infrastructure.dart';
import 'package:vet45_shared_testing/shared_testing.dart';

import '../../lib/src/domain/customer_price_rule_import/excel_customer_price_rule_import_file_adapter.dart';
import '../support/fake_pricing_rpc_supabase.dart';

void main() {
  test(
    'startup executes import template query through scoped mediator',
    () async {
      final supabase = FakePricingRpcSupabase();
      final module = PricingStartup.initializeForTesting(
        supabase: supabase,
        executionContext: FakeExecutionContext(
          userId: 'user-1',
          tenantId: 'tenant-1',
        ),
        permissionChecker: FakePermissionChecker(),
        tenantAccessChecker: FakeTenantAccessChecker(),
      );

      final template = await module.executeQueryAsync(
        GetCustomerPriceRuleImportTemplateQuery(tenantId: 'tenant-1'),
      );

      expect(template.templateVersion, 'customer_price_rules_v1');
      expect(template.fileName, 'customer_price_rules_v1.xlsx');
      expect(supabase.calls, isEmpty);
    },
  );

  test('startup executes start import through parser and create RPC', () async {
    final supabase = FakePricingRpcSupabase()
      ..registerHandler('create_customer_price_rule_import', (_) async {
        return {
          'batch': {
            'id': 'import-1',
            'template_version': 'customer_price_rules_v1',
            'original_file_name': 'customer_price_rules_v1.xlsx',
            'import_mode': 'upsert',
            'status': 'ready_to_import',
            'version': 1,
            'total_rows': 1,
            'valid_rows': 1,
            'warning_rows': 0,
            'error_rows': 0,
            'imported_rows': 0,
            'skipped_rows': 0,
            'failed_rows': 0,
            'file_error_codes': [],
            'created_at': '2026-07-16T10:00:00Z',
          },
          'rows': {'items': [], 'has_more': false},
        };
      });
    final module = PricingStartup.initializeForTesting(
      supabase: supabase,
      executionContext: FakeExecutionContext(
        userId: 'user-1',
        tenantId: 'tenant-1',
      ),
      permissionChecker: FakePermissionChecker(),
      tenantAccessChecker: FakeTenantAccessChecker(),
    );
    const adapter = ExcelCustomerPriceRuleImportFileAdapter();
    final bytes = adapter.createTemplateV1().bytes;

    final detail = await module.executeCommandAsync(
      StartCustomerPriceRuleImportCommand(
        tenantId: 'tenant-1',
        actorId: 'user-1',
        templateVersion: 'customer_price_rules_v1',
        originalFileName: 'customer_price_rules_v1.xlsx',
        fileBytes: bytes,
        importMode: CustomerPriceRuleImportMode.upsert,
      ),
    );

    expect(detail.batch.id, 'import-1');
    expect(
      supabase.calls.single.functionName,
      'create_customer_price_rule_import',
    );
    expect(supabase.calls.single.params?['p_parse_result'], isNotNull);
  });
}
