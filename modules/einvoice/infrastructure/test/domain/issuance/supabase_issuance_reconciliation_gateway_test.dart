import 'package:test/test.dart';
import 'package:vet45_adapters/vet45_adapters.dart';
import 'package:vet45_einvoice_domain/domain.dart';
import 'package:vet45_einvoice_infrastructure/src/domain/issuance/supabase_issuance_reconciliation_gateway.dart';
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
  group('SupabaseIssuanceReconciliationGateway', () {
    late SupabaseIssuanceReconciliationGateway gateway;
    late FakeEinvoiceRpcSupabase supabase;

    setUp(() {
      supabase = FakeEinvoiceRpcSupabase();
      gateway = SupabaseIssuanceReconciliationGateway(
        rpcClient: _rpcClient(supabase),
      );
    });

    test(
      'openReconciliationCase maps params and returns ReconciliationCaseDto',
      () async {
        supabase.registerHandler('open_reconciliation_case', (params) async {
          expect(params?['p_tenant_id'], 'tenant-1');
          expect(params?['p_attempt_id'], 'att-001');
          expect(params?['p_reason'], 'TIMEOUT');
          return [
            {'case_id': 'c-001', 'attempt_id': 'att-001', 'status': 'PENDING'},
          ];
        });

        final result = await gateway.openReconciliationCase(
          tenantId: 'tenant-1',
          attemptId: 'att-001',
          reason: 'TIMEOUT',
        );

        expect(result.caseId, 'c-001');
        expect(result.attemptId, 'att-001');
        expect(result.status, ReconciliationCaseStatus.pending);
      },
    );

    test(
      'claimReconciliationCase returns context when case is found',
      () async {
        supabase.registerHandler('claim_issuance_reconciliation_case', (
          params,
        ) async {
          expect(params?['p_tenant_id'], 'tenant-1');
          expect(params?['p_case_id'], 'c-001');
          expect(params?['p_worker_id'], 'worker-1');
          return [
            {
              'case_id': 'c-001',
              'attempt_id': 'att-001',
              'claim_token': 'token-123',
              'idempotency_key': 'idem-key',
              'payload_hash': 'hash-abc',
              'invoice_series': '1C26TYY',
              'provider_reference': 'misa-ref-1',
              'check_sequence': 2,
              'max_checks': 5,
            },
          ];
        });

        final result = await gateway.claimReconciliationCase(
          tenantId: 'tenant-1',
          caseId: 'c-001',
          workerId: 'worker-1',
        );

        expect(result, isNotNull);
        expect(result!.caseId, 'c-001');
        expect(result.attemptId, 'att-001');
        expect(result.claimToken, 'token-123');
        expect(result.idempotencyKey, 'idem-key');
        expect(result.payloadHash, 'hash-abc');
        expect(result.invoiceSeries, '1C26TYY');
        expect(result.providerReference, 'misa-ref-1');
        expect(result.checkSequence, 2);
        expect(result.maxChecks, 5);
      },
    );

    test(
      'claimReconciliationCase returns null when no rows returned',
      () async {
        supabase.registerHandler(
          'claim_issuance_reconciliation_case',
          (params) async => [],
        );

        final result = await gateway.claimReconciliationCase(
          tenantId: 'tenant-1',
          caseId: 'c-001',
          workerId: 'worker-1',
        );

        expect(result, isNull);
      },
    );

    test('recordPendingCheck maps duration to seconds', () async {
      supabase.registerHandler('record_reconciliation_pending', (params) async {
        expect(params?['p_tenant_id'], 'tenant-1');
        expect(params?['p_case_id'], 'c-001');
        expect(params?['p_claim_token'], 'token-123');
        expect(params?['p_next_delay_seconds'], 30);
        expect(params?['p_check_sequence'], 3);
        return null;
      });

      await gateway.recordPendingCheck(
        tenantId: 'tenant-1',
        caseId: 'c-001',
        claimToken: 'token-123',
        nextDelay: const Duration(seconds: 30),
        checkSequence: 3,
      );
    });

    test(
      'resolveReconciliationCase maps params and returns ReconciliationCaseDto',
      () async {
        supabase.registerHandler('resolve_reconciliation_case', (params) async {
          expect(params?['p_tenant_id'], 'tenant-1');
          expect(params?['p_case_id'], 'c-001');
          expect(params?['p_outcome'], 'SUCCESS');
          expect(params?['p_evidence'], {'invoice_number': '000001'});
          return [
            {'case_id': 'c-001', 'attempt_id': 'att-001', 'status': 'RESOLVED'},
          ];
        });

        final result = await gateway.resolveReconciliationCase(
          tenantId: 'tenant-1',
          caseId: 'c-001',
          outcome: 'SUCCESS',
          evidence: {'invoice_number': '000001'},
        );

        expect(result.status, ReconciliationCaseStatus.resolved);
      },
    );

    test('markUnresolved calls resolve with outcome UNRESOLVED', () async {
      supabase.registerHandler('resolve_reconciliation_case', (params) async {
        expect(params?['p_tenant_id'], 'tenant-1');
        expect(params?['p_case_id'], 'c-001');
        expect(params?['p_outcome'], 'UNRESOLVED');
        return [
          {'case_id': 'c-001', 'attempt_id': 'att-001', 'status': 'UNRESOLVED'},
        ];
      });

      await gateway.markUnresolved(
        tenantId: 'tenant-1',
        caseId: 'c-001',
        claimToken: 'token-123',
        reasonCode: 'POLL_MAX_CHECKS_EXCEEDED',
      );
    });

    test(
      'recoverFinalization maps params and returns RecoverInternalFinalizationResultDto',
      () async {
        supabase.registerHandler('recover_internal_finalization', (
          params,
        ) async {
          expect(params?['p_tenant_id'], 'tenant-1');
          expect(params?['p_attempt_id'], 'att-001');
          return [
            {
              'electronic_invoice_id': 'inv-001',
              'sales_order_id': 'so-001',
              'invoice_number': '000001',
              'provider_invoice_ref': '1C24TYY',
              'status': 'RECOVERED',
            },
          ];
        });

        final result = await gateway.recoverFinalization(
          tenantId: 'tenant-1',
          attemptId: 'att-001',
        );

        expect(result.invoice.electronicInvoiceId, 'inv-001');
        expect(result.invoice.salesOrderId, 'so-001');
        expect(result.invoice.invoiceNumber, '000001');
        expect(result.invoice.providerInvoiceRef, '1C24TYY');
      },
    );

    test(
      'getAttemptStatus maps row to safe IssuanceAttemptStatusDto',
      () async {
        supabase.registerHandler('get_issuance_attempt_status', (params) async {
          expect(params?['p_tenant_id'], 'tenant-1');
          expect(params?['p_actor_id'], 'act-001');
          expect(params?['p_sales_order_id'], 'so-001');
          return [
            {
              'attempt_id': 'att-001',
              'status': 'FAILED',
              'internal_finalization_status': 'pending',
              'has_electronic_invoice': false,
              'has_active_operation': false,
              'failure_code': 'MISA_REJECTED',
              'last_error_message': 'Invalid Tax Code',
            },
          ];
        });

        final result = await gateway.getAttemptStatus(
          tenantId: 'tenant-1',
          actorId: 'act-001',
          salesOrderId: 'so-001',
        );

        expect(result.status, IssuanceAttemptStatus.failed);
        expect(
          result.internalFinalizationStatus,
          InternalFinalizationStatus.pending,
        );
        expect(result.hasElectronicInvoice, isFalse);
        expect(result.hasActiveOperation, isFalse);
        expect(result.failureCode, 'MISA_REJECTED');
        expect(result.lastErrorMessage, 'Invalid Tax Code');
      },
    );
  });
}
