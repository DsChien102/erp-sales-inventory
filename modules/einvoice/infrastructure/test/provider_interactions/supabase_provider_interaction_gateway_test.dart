import 'package:test/test.dart';
import 'package:vet45_adapters/vet45_adapters.dart';
import 'package:vet45_einvoice_application/application.dart';
import 'package:vet45_einvoice_infrastructure/src/provider_interactions/supabase_provider_interaction_gateway.dart';
import 'package:vet45_shared_infrastructure/infrastructure.dart';

import '../support/fake_einvoice_rpc_supabase.dart';

SupabaseSchemaRpcClient _rpcClient(FakeEinvoiceRpcSupabase supabase) {
  return SupabaseSchemaRpcClient(
    supabase: supabase,
    schema: 'einvoice',
    mapError: (error, [stackTrace]) => RpcException(error.toString()),
  );
}

void main() {
  group('SupabaseProviderInteractionGateway', () {
    test('start sends exact RPC params', () async {
      final supabase = FakeEinvoiceRpcSupabase()
        ..registerHandler('start_provider_interaction', (params) async {
          expect(params, {
            'p_tenant_id': 'tenant-1',
            'p_provider_connection_id': 'conn-1',
            'p_direction': 'OUTBOUND',
            'p_operation_type': 'POLL_PROVIDER_OBSERVATION',
            'p_target_type': 'ELECTRONIC_INVOICE',
            'p_target_id': 'invoice-1',
            'p_correlation_id': 'corr-1',
            'p_request_reference': 'cmd-1',
          });
          return [
            {
              'interaction_reference': 'interaction-1',
              'tenant_id': 'tenant-1',
              'version': 0,
              'provider_connection_id': 'conn-1',
              'direction': 'OUTBOUND',
              'operation_type': 'POLL_PROVIDER_OBSERVATION',
              'target_type': 'ELECTRONIC_INVOICE',
              'target_id': 'invoice-1',
              'correlation_id': 'corr-1',
              'request_reference': 'cmd-1',
              'response_reference': null,
              'provider_reference': null,
              'status': 'STARTED',
              'outcome': null,
              'safe_error_code': null,
              'started_at': '2026-08-31T09:00:00.000Z',
              'completed_at': null,
            },
          ];
        });
      final gateway = SupabaseProviderInteractionGateway(
        rpcClient: _rpcClient(supabase),
      );

      final record = await gateway.start(
        tenantId: 'tenant-1',
        providerConnectionId: 'conn-1',
        direction: ProviderInteractionDirection.outbound,
        operationType: 'POLL_PROVIDER_OBSERVATION',
        targetType: 'ELECTRONIC_INVOICE',
        targetId: 'invoice-1',
        correlationId: 'corr-1',
        requestReference: 'cmd-1',
      );

      expect(supabase.calls.single.functionName, 'start_provider_interaction');
      expect(record.interactionReference, 'interaction-1');
      expect(record.status, ProviderInteractionStatus.started);
      expect(record.version, 0);
    });

    test('finalize sends exact timeout params', () async {
      final supabase = FakeEinvoiceRpcSupabase()
        ..registerHandler('record_provider_interaction_result', (params) async {
          expect(params, {
            'p_tenant_id': 'tenant-1',
            'p_interaction_reference': 'interaction-1',
            'p_expected_version': 0,
            'p_outcome': 'TIMEOUT',
            'p_response_reference': null,
            'p_provider_reference': null,
            'p_safe_error_code': 'PROVIDER_TIMEOUT',
          });
          return [
            {
              'interaction_reference': 'interaction-1',
              'tenant_id': 'tenant-1',
              'version': 1,
              'provider_connection_id': 'conn-1',
              'direction': 'OUTBOUND',
              'operation_type': 'POLL_PROVIDER_OBSERVATION',
              'target_type': 'ELECTRONIC_INVOICE',
              'target_id': 'invoice-1',
              'correlation_id': 'corr-1',
              'request_reference': 'cmd-1',
              'response_reference': null,
              'provider_reference': null,
              'status': 'COMPLETED',
              'outcome': 'TIMEOUT',
              'safe_error_code': 'PROVIDER_TIMEOUT',
              'started_at': '2026-08-31T09:00:00.000Z',
              'completed_at': '2026-08-31T09:01:00.000Z',
            },
          ];
        });
      final gateway = SupabaseProviderInteractionGateway(
        rpcClient: _rpcClient(supabase),
      );

      final record = await gateway.finalize(
        tenantId: 'tenant-1',
        interactionReference: 'interaction-1',
        expectedVersion: 0,
        outcome: ProviderInteractionOutcome.timeout,
        safeErrorCode: 'PROVIDER_TIMEOUT',
      );

      expect(
        supabase.calls.single.functionName,
        'record_provider_interaction_result',
      );
      expect(record.status, ProviderInteractionStatus.completed);
      expect(record.outcome, ProviderInteractionOutcome.timeout);
      expect(record.safeErrorCode, 'PROVIDER_TIMEOUT');
    });
  });
}
