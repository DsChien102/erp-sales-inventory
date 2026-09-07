import 'package:test/test.dart';
import 'package:vet45_adapters/vet45_adapters.dart';
import 'package:vet45_einvoice_application/application.dart';
import 'package:vet45_einvoice_domain/domain.dart';
import 'package:vet45_einvoice_infrastructure/src/domain/delivery/supabase_delivery_command_gateway.dart';
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
  group('SupabaseDeliveryCommandGateway', () {
    late FakeEinvoiceRpcSupabase supabase;
    late SupabaseDeliveryCommandGateway gateway;

    const tenantId = '11111111-1111-1111-1111-111111111111';
    const deliveryId = '22222222-2222-2222-2222-222222222222';
    const attemptId = '33333333-3333-3333-3333-333333333333';

    setUp(() {
      supabase = FakeEinvoiceRpcSupabase();
      gateway = SupabaseDeliveryCommandGateway(rpcClient: _rpcClient(supabase));
    });

    test('prepareProviderCall maps CALL_PROVIDER without simulation params', () async {
      supabase.registerHandler('prepare_delivery_provider_call', (params) async {
        expect(params?.containsKey('p_is_simulated'), isFalse);
        return [
          {
            'action': 'CALL_PROVIDER',
            'delivery_version': 2,
            'attempt_version': 2,
            'provider_connection_id': 'pc',
            'provider_transaction_id': 'tx',
            'invoice_series': 'series',
            'recipient_email': 'test@example.com',
          },
        ];
      });
      final result = await gateway.prepareProviderCall(
        tenantId: tenantId,
        deliveryId: deliveryId,
        attemptId: attemptId,
        expectedDeliveryVersion: 1,
        expectedAttemptVersion: 1,
        requestReference: 'request',
      );
      expect(result, isA<PrepareDeliveryCallProvider>());
      expect(
        (result as PrepareDeliveryCallProvider).providerContext.recipientEmail,
        'test@example.com',
      );
    });

    test('startAuto maps exact RPC params and started disposition', () async {
      supabase.registerHandler('start_auto_delivery', (params) async {
        expect(params, {
          'p_tenant_id': tenantId,
          'p_electronic_invoice_id': 'ei-1',
          'p_trigger_id': 'evt-1',
          'p_idempotency_key': 'idem-1',
        });
        return [
          {
            'disposition': 'started',
            'delivery_id': deliveryId,
            'skip_reason': null,
          },
        ];
      });

      final result = await gateway.startAuto(
        const AutoDeliveryStartRequest(
          tenantId: tenantId,
          electronicInvoiceId: 'ei-1',
          triggerId: 'evt-1',
          idempotencyKey: 'idem-1',
        ),
      );

      expect(result.disposition, AutoDeliveryDisposition.started);
      expect(result.deliveryId, deliveryId);
      expect(result.skipReason, isNull);
    });

    test('startAuto maps skip reasons', () async {
      for (final entry in [
        ('POLICY_OFF', AutoDeliverySkipReason.policyOff),
        (
          'INVALID_OR_MISSING_EMAIL',
          AutoDeliverySkipReason.invalidOrMissingEmail,
        ),
        (
          'INITIAL_DELIVERY_ALREADY_CLAIMED',
          AutoDeliverySkipReason.initialDeliveryAlreadyClaimed,
        ),
      ]) {
        supabase.calls.clear();
        supabase.registerHandler('start_auto_delivery', (_) async {
          return [
            {
              'disposition': 'skipped',
              'delivery_id': null,
              'skip_reason': entry.$1,
            },
          ];
        });

        final result = await gateway.startAuto(
          const AutoDeliveryStartRequest(
            tenantId: tenantId,
            electronicInvoiceId: 'ei-1',
            triggerId: 'evt-1',
            idempotencyKey: 'idem-1',
          ),
        );

        expect(result.disposition, AutoDeliveryDisposition.skipped);
        expect(result.skipReason, entry.$2);
      }
    });

    test('startManual maps exact RPC params and status casing', () async {
      supabase.registerHandler('send_electronic_invoice', (params) async {
        expect(params, {
          'p_tenant_id': tenantId,
          'p_actor_id': 'actor-1',
          'p_sales_order_id': 'order-1',
          'p_recipient_email': 'buyer@example.com',
          'p_idempotency_key': 'idem-2',
        });
        return [
          {'delivery_id': deliveryId, 'status': 'PROCESSING'},
        ];
      });

      final result = await gateway.startManual(
        const ManualDeliveryStartRequest(
          tenantId: tenantId,
          actorId: 'actor-1',
          salesOrderId: 'order-1',
          recipientEmail: 'buyer@example.com',
          idempotencyKey: 'idem-2',
        ),
      );

      expect(result.deliveryId, deliveryId);
      expect(result.status, DeliveryStatus.processing);
    });

    test(
      'loadAttemptContext maps nullable recipient name and versions',
      () async {
        supabase.registerHandler('load_delivery_attempt_context', (
          params,
        ) async {
          expect(params, {
            'p_tenant_id': tenantId,
            'p_delivery_id': deliveryId,
            'p_attempt_id': attemptId,
          });
          return [
            {
              'tenant_id': tenantId,
              'delivery_id': deliveryId,
              'attempt_id': attemptId,
              'delivery_version': 2,
              'attempt_version': 1,
              'provider_connection_id': 'pc-1',
              'provider_transaction_id': 'txn-1',
              'invoice_series': '1C22T',
              'recipient_email': 'buyer@example.com',
              'recipient_name': null,
            },
          ];
        });

        final context = await gateway.loadAttemptContext(
          tenantId: tenantId,
          deliveryId: deliveryId,
          attemptId: attemptId,
        );

        expect(context, isNotNull);
        expect(context!.deliveryVersion, 2);
        expect(context.attemptVersion, 1);
        expect(context.recipientName, isNull);
        expect(context.recipientEmail, 'buyer@example.com');
      },
    );

    test('loadAttemptContext returns null when RPC yields no rows', () async {
      supabase.registerHandler('load_delivery_attempt_context', (_) async {
        return <Map<String, dynamic>>[];
      });

      final context = await gateway.loadAttemptContext(
        tenantId: tenantId,
        deliveryId: deliveryId,
        attemptId: attemptId,
      );

      expect(context, isNull);
    });

    test('prepareProviderCall maps CALL_PROVIDER with typed context', () async {
      supabase.registerHandler('prepare_delivery_provider_call', (
        params,
      ) async {
        expect(params, {
          'p_tenant_id': tenantId,
          'p_delivery_id': deliveryId,
          'p_attempt_id': attemptId,
          'p_expected_delivery_version': 1,
          'p_expected_attempt_version': 0,
          'p_request_reference': 'req-1',
        });
        return [
          {
            'action': 'CALL_PROVIDER',
            'delivery_version': 2,
            'attempt_version': 1,
            'provider_connection_id': 'pc-1',
            'provider_transaction_id': 'txn-1',
            'invoice_series': '1C22T',
            'recipient_email': 'buyer@example.com',
            'recipient_name': 'Buyer',
            'interaction_reference': null,
          },
        ];
      });

      final result = await gateway.prepareProviderCall(
        tenantId: tenantId,
        deliveryId: deliveryId,
        attemptId: attemptId,
        expectedDeliveryVersion: 1,
        expectedAttemptVersion: 0,
        requestReference: 'req-1',
      );

      expect(result, isA<PrepareDeliveryCallProvider>());
      final call = result as PrepareDeliveryCallProvider;
      expect(call.deliveryVersion, 2);
      expect(call.attemptVersion, 1);
      expect(call.providerContext.providerConnectionId, 'pc-1');
      expect(call.providerContext.recipientName, 'Buyer');
    });

    test('prepareProviderCall maps SKIP and RECORD_UNKNOWN', () async {
      supabase.registerHandler('prepare_delivery_provider_call', (_) async {
        return [
          {
            'action': 'SKIP',
            'delivery_version': 1,
            'attempt_version': 1,
            'provider_connection_id': null,
            'provider_transaction_id': null,
            'invoice_series': null,
            'recipient_email': null,
            'recipient_name': null,
            'interaction_reference': null,
          },
        ];
      });
      expect(
        await gateway.prepareProviderCall(
          tenantId: tenantId,
          deliveryId: deliveryId,
          attemptId: attemptId,
          expectedDeliveryVersion: 1,
          expectedAttemptVersion: 1,
          requestReference: 'req-1',
        ),
        isA<PrepareDeliverySkip>(),
      );

      supabase.registerHandler('prepare_delivery_provider_call', (_) async {
        return [
          {
            'action': 'RECORD_UNKNOWN',
            'delivery_version': 3,
            'attempt_version': 2,
            'provider_connection_id': 'pc-1',
            'provider_transaction_id': 'txn-1',
            'invoice_series': '1C22T',
            'recipient_email': 'buyer@example.com',
            'recipient_name': null,
            'interaction_reference': 'ix-1',
          },
        ];
      });
      final unknown = await gateway.prepareProviderCall(
        tenantId: tenantId,
        deliveryId: deliveryId,
        attemptId: attemptId,
        expectedDeliveryVersion: 2,
        expectedAttemptVersion: 1,
        requestReference: 'req-2',
      );
      expect(unknown, isA<PrepareDeliveryRecordUnknown>());
      final recordUnknown = unknown as PrepareDeliveryRecordUnknown;
      expect(recordUnknown.interactionReference, 'ix-1');
      expect(recordUnknown.deliveryVersion, 3);
    });

    test('recordResult maps typed evidence and optimistic versions', () async {
      supabase.registerHandler('record_delivery_result', (params) async {
        expect(params, {
          'p_tenant_id': tenantId,
          'p_delivery_id': deliveryId,
          'p_attempt_id': attemptId,
          'p_expected_delivery_version': 2,
          'p_expected_attempt_version': 1,
          'p_interaction_reference': 'ix-1',
          'p_outcome_kind': 'SUCCESS',
          'p_provider_reference': 'prov-ref',
          'p_safe_code': null,
        });
        return [
          {
            'delivery_status': 'SUCCEEDED',
            'display_state': 'SENT',
            'has_secondary_attention': false,
          },
        ];
      });

      final result = await gateway.recordResult(
        const DeliveryResultRecord(
          tenantId: tenantId,
          deliveryId: deliveryId,
          attemptId: attemptId,
          expectedDeliveryVersion: 2,
          expectedAttemptVersion: 1,
          interactionReference: 'ix-1',
          evidence: DeliveryResultEvidence(
            kind: DeliveryResultKind.success,
            providerReference: 'prov-ref',
          ),
        ),
      );

      expect(result.deliveryStatus, DeliveryStatus.succeeded);
      expect(result.displayState, DeliveryDisplayState.sent);
      expect(result.hasSecondaryAttention, isFalse);
    });

    test(
      'recordResult maps all outcome kinds and undetermined display',
      () async {
        for (final entry in [
          (
            DeliveryResultKind.definiteFailure,
            'DEFINITE_FAILURE',
            'FAILED',
            'FAILED',
            false,
          ),
          (
            DeliveryResultKind.retryableFailure,
            'RETRYABLE_FAILURE',
            'PROCESSING',
            'SENDING',
            false,
          ),
          (
            DeliveryResultKind.undetermined,
            'UNDETERMINED',
            'UNKNOWN',
            'SENDING',
            false,
          ),
        ]) {
          supabase.calls.clear();
          supabase.registerHandler('record_delivery_result', (params) async {
            expect(params?['p_outcome_kind'], entry.$2);
            expect(params?['p_safe_code'], 'SAFE_CODE');
            return [
              {
                'delivery_status': entry.$3,
                'display_state': entry.$4,
                'has_secondary_attention': entry.$5,
              },
            ];
          });

          final result = await gateway.recordResult(
            DeliveryResultRecord(
              tenantId: tenantId,
              deliveryId: deliveryId,
              attemptId: attemptId,
              expectedDeliveryVersion: 1,
              expectedAttemptVersion: 1,
              interactionReference: 'ix-1',
              evidence: DeliveryResultEvidence(
                kind: entry.$1,
                safeCode: 'SAFE_CODE',
              ),
            ),
          );

          expect(result.deliveryStatus.name.toUpperCase(), entry.$3);
          expect(result.displayState, switch (entry.$4) {
            'FAILED' => DeliveryDisplayState.failed,
            'SENDING' => DeliveryDisplayState.sending,
            _ => fail('unexpected'),
          });
        }
      },
    );

    test('recordCommandDeadLetter maps exact params', () async {
      supabase.registerHandler('record_delivery_command_dead_letter', (
        params,
      ) async {
        expect(params, {
          'p_tenant_id': tenantId,
          'p_delivery_id': deliveryId,
          'p_attempt_id': attemptId,
          'p_safe_failure_code': 'WORKER_EXHAUSTED_BEFORE_DISPATCH',
        });
        return null;
      });

      await gateway.recordCommandDeadLetter(
        tenantId: tenantId,
        deliveryId: deliveryId,
        attemptId: attemptId,
        safeFailureCode: 'WORKER_EXHAUSTED_BEFORE_DISPATCH',
      );

      expect(
        supabase.calls.single.functionName,
        'record_delivery_command_dead_letter',
      );
    });

    test('maps STATE_CHANGED to EInvoiceBlockedException', () async {
      supabase.registerHandler('prepare_delivery_provider_call', (_) async {
        throw RpcException('STATE_CHANGED: expected version mismatch');
      });

      await expectLater(
        gateway.prepareProviderCall(
          tenantId: tenantId,
          deliveryId: deliveryId,
          attemptId: attemptId,
          expectedDeliveryVersion: 1,
          expectedAttemptVersion: 0,
          requestReference: 'req-1',
        ),
        throwsA(
          isA<EInvoiceBlockedException>().having(
            (e) => e.code,
            'code',
            EInvoiceBlockedCodes.stateChanged,
          ),
        ),
      );
    });
  });
}
