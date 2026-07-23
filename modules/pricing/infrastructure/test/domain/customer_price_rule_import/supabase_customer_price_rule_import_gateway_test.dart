import 'package:test/test.dart';
import 'package:vet45_adapters/vet45_adapters.dart';
import 'package:vet45_pricing_application/application.dart';
import 'package:vet45_shared_infrastructure/infrastructure.dart';

import '../../support/fake_pricing_rpc_supabase.dart';
import '../../../lib/src/domain/customer_price_rule_import/supabase_customer_price_rule_import_gateway.dart';

void main() {
  test('import gateway calls exact RPC names and maps response', () async {
    final supabase = FakePricingRpcSupabase()
      ..registerHandler('create_customer_price_rule_import', (params) async {
        expect(params?['p_import_mode'], 'upsert');
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

    final gateway = SupabaseCustomerPriceRuleImportGateway(
      rpcClient: SupabaseSchemaRpcClient(
        supabase: supabase,
        schema: 'pricing',
        mapError: (error, [stackTrace]) => RpcException(error.toString()),
      ),
    );

    final detail = await gateway.create(
      tenantId: 'tenant-1',
      templateVersion: 'customer_price_rules_v1',
      originalFileName: 'customer_price_rules_v1.xlsx',
      importMode: CustomerPriceRuleImportMode.upsert,
      parseResult: const CustomerPriceRuleImportParseResult.parsed([
        CustomerPriceRuleImportParsedRow(
          rowNumber: 2,
          customerId: '00000000-0000-4000-8000-000000000001',
          productId: '00000000-0000-4000-8000-000000000101',
          productUnitId: '00000000-0000-4000-8000-000000000201',
          price: '90000',
        ),
      ]),
    );

    expect(
      supabase.calls.single.functionName,
      'create_customer_price_rule_import',
    );
    final createParams = supabase.calls.single.params;
    final parseResult = createParams?['p_parse_result'] as Map?;
    final row = (parseResult?['rows'] as List?)?.single as Map?;
    expect(
      row?['product_id'],
      '00000000-0000-4000-8000-000000000101',
    );
    expect(
      row?['product_unit_id'],
      '00000000-0000-4000-8000-000000000201',
    );
    expect(detail.batch.id, 'import-1');
  });

  test('import gateway maps PostgreSQL validation error envelope', () async {
    final supabase = FakePricingRpcSupabase()
      ..registerHandler('cancel_customer_price_rule_import', (_) async {
        throw RpcException(
          '{"code":"STATE_CHANGED","message":"Import batch version changed.","details":{}}',
        );
      });

    final gateway = SupabaseCustomerPriceRuleImportGateway(
      rpcClient: SupabaseSchemaRpcClient(
        supabase: supabase,
        schema: 'pricing',
        mapError: (error, [stackTrace]) => RpcException(error.toString()),
      ),
    );

    await expectLater(
      gateway.cancel(
        tenantId: 'tenant-1',
        importId: 'import-1',
        expectedVersion: 1,
      ),
      throwsA(
        isA<PricingBlockedException>().having(
          (error) => error.code,
          'code',
          PricingBlockedCodes.stateChanged,
        ),
      ),
    );
  });
}
