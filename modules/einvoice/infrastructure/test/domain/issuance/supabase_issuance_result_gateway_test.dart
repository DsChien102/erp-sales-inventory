import 'package:test/test.dart';
import 'package:vet45_adapters/vet45_adapters.dart';
import 'package:vet45_einvoice_application/application.dart';
import 'package:vet45_einvoice_domain/domain.dart';
import 'package:vet45_einvoice_infrastructure/src/domain/issuance/supabase_issuance_result_gateway.dart';
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
  group('SupabaseIssuanceResultGateway', () {
    late SupabaseIssuanceResultGateway gateway;
    late FakeEinvoiceRpcSupabase supabase;

    const tenantId = 'tenant-1';
    const attemptId = 'att-1';
    const idempotencyKey = '88d18970-380a-4138-bbce-e25049ca9e3c';
    const payloadHash = 'abc123';
    final canonical = <String, Object?>{'modelVersion': '1.0.0'};

    setUp(() {
      supabase = FakeEinvoiceRpcSupabase();
      gateway = SupabaseIssuanceResultGateway(rpcClient: _rpcClient(supabase));
    });

    test(
      'preparePublish maps CALL_PROVIDER, RECONCILE_ONLY, and SKIP',
      () async {
        for (final entry in [
          ('CALL_PROVIDER', PublishPreparationAction.callProvider),
          ('RECONCILE_ONLY', PublishPreparationAction.reconcileOnly),
          ('SKIP', PublishPreparationAction.skip),
        ]) {
          supabase.calls.clear();
          supabase.registerHandler('prepare_issuance_publish', (params) async {
            expect(params?['p_tenant_id'], tenantId);
            expect(params?['p_attempt_id'], attemptId);
            expect(params?['p_idempotency_key'], idempotencyKey);
            expect(params?['p_payload_hash'], payloadHash);
            expect(params?['p_canonical_payload'], canonical);
            return [
              {'action': entry.$1},
            ];
          });

          final result = await gateway.preparePublish(
            tenantId: tenantId,
            attemptId: attemptId,
            idempotencyKey: idempotencyKey,
            payloadHash: payloadHash,
            canonicalInvoice: canonical,
          );

          expect(result.action, entry.$2);
        }
      },
    );

    test('markProviderCallStarted maps exact params', () async {
      supabase.registerHandler('mark_issuance_provider_call_started', (
        params,
      ) async {
        expect(params, {'p_tenant_id': tenantId, 'p_attempt_id': attemptId});
        return null;
      });

      await gateway.markProviderCallStarted(
        tenantId: tenantId,
        attemptId: attemptId,
      );

      expect(
        supabase.calls.single.functionName,
        'mark_issuance_provider_call_started',
      );
    });

    test('recordSuccess maps typed success evidence to RPC params', () async {
      final issuedAt = DateTime.utc(2026, 8, 27, 12, 30);
      supabase.registerHandler('record_issuance_success', (params) async {
        expect(params, {
          'p_tenant_id': tenantId,
          'p_attempt_id': attemptId,
          'p_idempotency_key': idempotencyKey,
          'p_payload_hash': payloadHash,
          'p_provider_reference': 'prov-ref-1',
          'p_invoice_number': 'INV-001',
          'p_invoice_series': 'AA/26E',
          'p_issued_at': issuedAt.toUtc().toIso8601String(),
        });
        return [
          {'attempt_status': 'SUCCEEDED', 'electronic_invoice_id': 'ei-1'},
        ];
      });

      final result = await gateway.recordSuccess(
        tenantId: tenantId,
        attemptId: attemptId,
        evidence: IssuanceResultEvidenceDto.success(
          idempotencyKey: idempotencyKey,
          payloadHash: payloadHash,
          providerReference: 'prov-ref-1',
          invoiceNumber: 'INV-001',
          invoiceSeries: 'AA/26E',
          issuedAt: issuedAt,
        ),
      );

      expect(result.attemptStatus, IssuanceAttemptStatus.succeeded);
      expect(result.electronicInvoiceId, 'ei-1');
    });

    test(
      'recordDefiniteFailure maps typed failure evidence to RPC params',
      () async {
        supabase.registerHandler('record_issuance_failure', (params) async {
          expect(params, {
            'p_tenant_id': tenantId,
            'p_attempt_id': attemptId,
            'p_idempotency_key': idempotencyKey,
            'p_payload_hash': payloadHash,
            'p_provider_code': 'INVALID_TAX_CODE',
            'p_provider_message': 'Buyer tax code rejected',
          });
          return [
            {'attempt_status': 'FAILED'},
          ];
        });

        final result = await gateway.recordDefiniteFailure(
          tenantId: tenantId,
          attemptId: attemptId,
          evidence: IssuanceResultEvidenceDto.definiteFailure(
            idempotencyKey: idempotencyKey,
            payloadHash: payloadHash,
            providerCode: 'INVALID_TAX_CODE',
            providerMessage: 'Buyer tax code rejected',
          ),
        );

        expect(result.attemptStatus, IssuanceAttemptStatus.failed);
      },
    );

    test(
      'recordUndetermined maps typed undetermined evidence to RPC params',
      () async {
        supabase.registerHandler('record_issuance_undetermined', (
          params,
        ) async {
          expect(params, {
            'p_tenant_id': tenantId,
            'p_attempt_id': attemptId,
            'p_idempotency_key': idempotencyKey,
            'p_payload_hash': payloadHash,
            'p_reason_code': 'PROVIDER_TIMEOUT',
          });
          return [
            {'attempt_status': 'RECONCILING'},
          ];
        });

        final result = await gateway.recordUndetermined(
          tenantId: tenantId,
          attemptId: attemptId,
          evidence: IssuanceResultEvidenceDto.undetermined(
            idempotencyKey: idempotencyKey,
            payloadHash: payloadHash,
            reasonCode: 'PROVIDER_TIMEOUT',
          ),
        );

        expect(result.attemptStatus, IssuanceAttemptStatus.reconciling);
      },
    );

    test('retryable rejection maps source command identity to RPC', () async {
      supabase.registerHandler('record_retryable_provider_publish_rejection', (
        params,
      ) async {
        expect(params, {
          'p_tenant_id': tenantId,
          'p_attempt_id': attemptId,
          'p_source_command_id': '44444444-4444-4444-4444-444444444444',
          'p_idempotency_key': idempotencyKey,
          'p_payload_hash': payloadHash,
          'p_provider_code': 'InvoiceNumberNotCotinuous',
          'p_provider_message': 'series gap',
          'p_retry_after_seconds': 30,
        });
        return [
          {'attempt_status': 'PREPARING'},
        ];
      });

      final result = await gateway.recordRetryableProviderRejection(
        tenantId: tenantId,
        attemptId: attemptId,
        sourceCommandId: '44444444-4444-4444-4444-444444444444',
        evidence: IssuanceResultEvidenceDto.retryableProviderRejection(
          idempotencyKey: idempotencyKey,
          payloadHash: payloadHash,
          providerCode: 'InvoiceNumberNotCotinuous',
          providerMessage: 'series gap',
        ),
        retryAfter: const Duration(seconds: 30),
      );

      expect(result.attemptStatus, IssuanceAttemptStatus.preparing);
    });

    test('recordCommandIntegrityFailure maps params to RPC', () async {
      supabase.registerHandler('record_issuance_command_integrity_failure', (
        params,
      ) async {
        expect(params, {
          'p_tenant_id': tenantId,
          'p_attempt_id': attemptId,
          'p_reason_code': 'CANONICAL_INVALID',
        });
        return [
          {'attempt_status': 'FAILED'},
        ];
      });

      final result = await gateway.recordCommandIntegrityFailure(
        tenantId: tenantId,
        attemptId: attemptId,
        reasonCode: 'CANONICAL_INVALID',
      );

      expect(result.attemptStatus, IssuanceAttemptStatus.failed);
    });

    test('recordPublishCommandDeadLetter maps params to RPC', () async {
      supabase.registerHandler('record_publish_command_dead_letter', (
        params,
      ) async {
        expect(params, {
          'p_tenant_id': tenantId,
          'p_attempt_id': attemptId,
          'p_reason_code': 'MAX_RETRIES_EXCEEDED',
        });
        return [
          {'attempt_status': 'FAILED'},
        ];
      });

      final result = await gateway.recordPublishCommandDeadLetter(
        tenantId: tenantId,
        attemptId: attemptId,
        reasonCode: 'MAX_RETRIES_EXCEEDED',
      );

      expect(result.attemptStatus, IssuanceAttemptStatus.failed);
    });
  });
}
