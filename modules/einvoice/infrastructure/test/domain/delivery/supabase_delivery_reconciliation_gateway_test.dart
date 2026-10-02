import 'package:test/test.dart';
import 'package:vet45_adapters/vet45_adapters.dart';
import 'package:vet45_einvoice_application/application.dart';
import 'package:vet45_einvoice_domain/domain.dart';
import 'package:vet45_einvoice_infrastructure/src/domain/delivery/supabase_delivery_reconciliation_gateway.dart';
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
  group('SupabaseDeliveryReconciliationGateway', () {
    late FakeEinvoiceRpcSupabase supabase;
    late SupabaseDeliveryReconciliationGateway gateway;

    const tenantId = '11111111-1111-1111-1111-111111111111';
    const caseId = '44444444-4444-4444-4444-444444444444';
    const deliveryId = '22222222-2222-2222-2222-222222222222';

    setUp(() {
      supabase = FakeEinvoiceRpcSupabase();
      gateway = SupabaseDeliveryReconciliationGateway(
        rpcClient: _rpcClient(supabase),
      );
    });

    test('loadContext maps exact RPC params and capability flag', () async {
      supabase.registerHandler('load_delivery_reconciliation_context', (
        params,
      ) async {
        expect(params, {
          'p_tenant_id': tenantId,
          'p_reconciliation_case_id': caseId,
          'p_check_sequence': 1,
        });
        return [
          {
            'tenant_id': tenantId,
            'reconciliation_case_id': caseId,
            'delivery_id': deliveryId,
            'provider_connection_id': 'conn-1',
            'supports_delivery_result_observation': false,
            'check_sequence': 1,
            'case_version': 0,
            'provider_delivery_reference': null,
          },
        ];
      });

      final context = await gateway.loadContext(
        tenantId: tenantId,
        reconciliationCaseId: caseId,
        checkSequence: 1,
      );

      expect(context, isNotNull);
      expect(context!.supportsDeliveryResultObservation, isFalse);
      expect(context.deliveryId, deliveryId);
      expect(context.caseVersion, 0);
    });

    test('loadContext returns null when RPC yields no rows', () async {
      supabase.registerHandler(
        'load_delivery_reconciliation_context',
        (_) async => <Map<String, dynamic>>[],
      );

      final context = await gateway.loadContext(
        tenantId: tenantId,
        reconciliationCaseId: caseId,
        checkSequence: 1,
      );

      expect(context, isNull);
    });

    test('recordCheck maps exact RPC params and result row', () async {
      supabase.registerHandler('record_delivery_reconciliation_check', (
        params,
      ) async {
        expect(params, {
          'p_tenant_id': tenantId,
          'p_reconciliation_case_id': caseId,
          'p_expected_case_version': 0,
          'p_check_sequence': 1,
          'p_observation_kind': 'UNSUPPORTED',
          'p_provider_reference': null,
          'p_safe_code': 'DELIVERY_RESULT_OBSERVATION_UNSUPPORTED',
        });
        return [
          {
            'case_status': 'UNRESOLVED',
            'delivery_status': 'UNKNOWN',
            'next_check_at': null,
            'has_secondary_attention': true,
          },
        ];
      });

      final result = await gateway.recordCheck(
        const DeliveryReconciliationCheckRecord(
          tenantId: tenantId,
          reconciliationCaseId: caseId,
          expectedCaseVersion: 0,
          checkSequence: 1,
          kind: DeliveryObservationKind.unsupported,
          safeCode: 'DELIVERY_RESULT_OBSERVATION_UNSUPPORTED',
        ),
      );

      expect(result.caseStatus, ReconciliationCaseStatus.unresolved);
      expect(result.deliveryStatus, DeliveryStatus.unknown);
      expect(result.nextCheckAt, isNull);
      expect(result.hasSecondaryAttention, isTrue);
    });
  });
}
