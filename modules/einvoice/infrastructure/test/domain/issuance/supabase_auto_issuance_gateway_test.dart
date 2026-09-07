import 'package:test/test.dart';
import 'package:vet45_adapters/vet45_adapters.dart';
import 'package:vet45_einvoice_application/application.dart';
import 'package:vet45_einvoice_infrastructure/src/domain/issuance/supabase_auto_issuance_gateway.dart';
import 'package:vet45_shared_infrastructure/infrastructure.dart';

import '../../support/fake_einvoice_rpc_supabase.dart';

SupabaseSchemaRpcClient _rpcClient(FakeEinvoiceRpcSupabase supabase) {
  return SupabaseSchemaRpcClient(
    supabase: supabase,
    schema: 'einvoice',
    mapError: (error, [stackTrace]) => RpcException(error.toString()),
  );
}

void main() {
  group('SupabaseAutoIssuanceGateway', () {
    late SupabaseAutoIssuanceGateway gateway;
    late FakeEinvoiceRpcSupabase supabase;

    const tenantId = 'tenant-1';
    const salesOrderId = 'so-123';
    const triggerKey = 'sales.order.completed:evt-1:so-123:1';
    const idempotencyKey = 'c7e735e5-397c-572e-834c-69550ea04153';

    setUp(() {
      supabase = FakeEinvoiceRpcSupabase();
      gateway = SupabaseAutoIssuanceGateway(rpcClient: _rpcClient(supabase));
    });

    group('start', () {
      test('maps start_auto_issuance success result correctly', () async {
        supabase.registerHandler('start_auto_issuance', (params) async {
          expect(params, {
            'p_tenant_id': tenantId,
            'p_sales_order_id': salesOrderId,
            'p_trigger_key': triggerKey,
            'p_idempotency_key': idempotencyKey,
          });
          return [
            {
              'started': true,
              'skipped': false,
              'process_id': 'proc-1',
              'attempt_id': 'att-1',
              'status': 'ATTEMPT_STARTED',
              'reason': null,
            },
          ];
        });

        final result = await gateway.start(
          const AutoIssuanceStartRequest(
            tenantId: tenantId,
            salesOrderId: salesOrderId,
            triggerKey: triggerKey,
            idempotencyKey: idempotencyKey,
          ),
        );

        expect(result.started, isTrue);
        expect(result.skipped, isFalse);
        expect(result.processId, 'proc-1');
        expect(result.attemptId, 'att-1');
        expect(result.status, 'ATTEMPT_STARTED');
        expect(result.reason, isNull);
      });

      test('maps start_auto_issuance skipped result correctly', () async {
        supabase.registerHandler('start_auto_issuance', (params) async {
          return [
            {
              'started': false,
              'skipped': true,
              'process_id': 'proc-2',
              'attempt_id': null,
              'status': 'SKIPPED',
              'reason': 'AUTOMATION_POLICY_DISABLED',
            },
          ];
        });

        final result = await gateway.start(
          const AutoIssuanceStartRequest(
            tenantId: tenantId,
            salesOrderId: salesOrderId,
            triggerKey: triggerKey,
            idempotencyKey: idempotencyKey,
          ),
        );

        expect(result.started, isFalse);
        expect(result.skipped, isTrue);
        expect(result.processId, 'proc-2');
        expect(result.attemptId, isNull);
        expect(result.status, 'SKIPPED');
        expect(result.reason, 'AUTOMATION_POLICY_DISABLED');
      });

      test('throws when RPC returns empty rows', () async {
        supabase.registerHandler('start_auto_issuance', (params) async => []);

        expect(
          () => gateway.start(
            const AutoIssuanceStartRequest(
              tenantId: tenantId,
              salesOrderId: salesOrderId,
              triggerKey: triggerKey,
              idempotencyKey: idempotencyKey,
            ),
          ),
          throwsA(
            isA<EInvoiceBlockedException>().having(
              (e) => e.code,
              'code',
              EInvoiceBlockedCodes.systemError,
            ),
          ),
        );
      });

      test('throws when started field is missing', () async {
        supabase.registerHandler(
          'start_auto_issuance',
          (params) async => [
            {'skipped': false},
          ],
        );

        expect(
          () => gateway.start(
            const AutoIssuanceStartRequest(
              tenantId: tenantId,
              salesOrderId: salesOrderId,
              triggerKey: triggerKey,
              idempotencyKey: idempotencyKey,
            ),
          ),
          throwsA(
            isA<EInvoiceBlockedException>().having(
              (e) => e.code,
              'code',
              EInvoiceBlockedCodes.systemError,
            ),
          ),
        );
      });
    });

    group('reevaluate', () {
      test('maps reevaluate_auto_issuance result correctly', () async {
        const processId = 'proc-1';
        const sourceEventId = 'evt-partner-update-1';

        supabase.registerHandler('reevaluate_auto_issuance', (params) async {
          expect(params, {
            'p_tenant_id': tenantId,
            'p_process_id': processId,
            'p_source_event_id': sourceEventId,
          });
          return [
            {
              'started': true,
              'skipped': false,
              'process_id': processId,
              'attempt_id': 'att-2',
              'status': 'ATTEMPT_STARTED',
              'reason': null,
            },
          ];
        });

        final result = await gateway.reevaluate(
          const AutoIssuanceReevaluationRequest(
            tenantId: tenantId,
            processId: processId,
            sourceEventId: sourceEventId,
          ),
        );

        expect(result.started, isTrue);
        expect(result.processId, processId);
        expect(result.attemptId, 'att-2');
        expect(result.status, 'ATTEMPT_STARTED');
      });
    });

    group('listOpenProcesses', () {
      test('maps list_open_auto_issuance_processes rows correctly', () async {
        const partnerId = 'partner-1';

        supabase.registerHandler('list_open_auto_issuance_processes', (
          params,
        ) async {
          expect(params, {'p_tenant_id': tenantId, 'p_partner_id': partnerId});
          return [
            {
              'process_id': 'proc-1',
              'sales_order_id': 'so-1',
              'partner_id': partnerId,
              'status': 'PENDING_REEVALUATION',
            },
            {
              'process_id': 'proc-2',
              'sales_order_id': 'so-2',
              'partner_id': partnerId,
              'status': 'PENDING_REEVALUATION',
            },
          ];
        });

        final list = await gateway.listOpenProcesses(
          tenantId: tenantId,
          partnerId: partnerId,
        );

        expect(list.length, 2);
        expect(list[0].processId, 'proc-1');
        expect(list[0].salesOrderId, 'so-1');
        expect(list[0].partnerId, partnerId);
        expect(list[0].status, 'PENDING_REEVALUATION');
        expect(list[1].processId, 'proc-2');
      });

      test('handles empty list from RPC', () async {
        supabase.registerHandler(
          'list_open_auto_issuance_processes',
          (params) async => [],
        );

        final list = await gateway.listOpenProcesses(
          tenantId: tenantId,
          partnerId: 'partner-none',
        );

        expect(list, isEmpty);
      });
    });
  });
}
