import 'dart:io';

import 'package:test/test.dart';
import 'package:vet45_adapters/vet45_adapters.dart';
import 'package:vet45_einvoice_application/application.dart';
import 'package:vet45_einvoice_domain/domain.dart';
import 'package:vet45_einvoice_infrastructure/src/domain/issuance/issuance_rpc_mapper.dart';
import 'package:vet45_einvoice_infrastructure/src/domain/issuance/supabase_issuance_command_gateway.dart';
import 'package:vet45_einvoice_infrastructure/src/domain/issuance/supabase_issuance_result_gateway.dart';
import 'package:vet45_einvoice_infrastructure/src/domain/issuance/supabase_order_invoice_projection_read_gateway.dart';
import 'package:vet45_einvoice_infrastructure/src/errors/einvoice_error_mapper.dart';
import 'package:vet45_shared_infrastructure/infrastructure.dart';

import '../../support/fake_einvoice_rpc_supabase.dart';

SupabaseSchemaRpcClient _rpcClient(FakeEinvoiceRpcSupabase supabase) {
  return SupabaseSchemaRpcClient(
    supabase: supabase,
    schema: 'einvoice',
    mapError: (error, [stackTrace]) => RpcException(error.toString()),
  );
}

IssueInvoiceStartRequest _startRequest() {
  return const IssueInvoiceStartRequest(
    tenantId: 'tenant-1',
    actorId: 'actor-1',
    salesOrderId: 'order-1',
    sourceVersion: 'etag:7f9d-opaque',
    idempotencyKey: '88d18970-380a-4138-bbce-e25049ca9e3c',
    acknowledgeWarnings: true,
  );
}

void main() {
  group('SupabaseIssuanceCommandGateway', () {
    test('issueInvoice sends exact frozen start params', () async {
      final supabase = FakeEinvoiceRpcSupabase()
        ..registerHandler('issue_invoice', (params) async {
          expect(params, {
            'p_tenant_id': 'tenant-1',
            'p_actor_id': 'actor-1',
            'p_sales_order_id': 'order-1',
            'p_source_version': 'etag:7f9d-opaque',
            'p_idempotency_key': '88d18970-380a-4138-bbce-e25049ca9e3c',
            'p_acknowledge_warnings': true,
          });
          return [
            {
              'issuance_id': 'iss-1',
              'attempt_id': 'att-1',
              'status': 'PREPARING',
            },
          ];
        });
      final gateway = SupabaseIssuanceCommandGateway(
        rpcClient: _rpcClient(supabase),
      );

      final result = await gateway.issueInvoice(_startRequest());

      expect(supabase.calls.single.functionName, 'issue_invoice');
      expect(result.issuanceId, 'iss-1');
      expect(result.attemptId, 'att-1');
      expect(result.status, IssuanceAttemptStatus.preparing);
    });

    test(
      'maps nested ISSUANCE_NOT_READY blockers to IssuanceNotReadyException',
      () async {
        final supabase = FakeEinvoiceRpcSupabase()
          ..registerHandler('issue_invoice', (_) async {
            throw RpcException(
              'ISSUANCE_NOT_READY: {"details":{"blockers":["SOURCE_SNAPSHOT_UNAVAILABLE","BUYER_SOURCE_UNAVAILABLE"]}}',
            );
          });
        final gateway = SupabaseIssuanceCommandGateway(
          rpcClient: _rpcClient(supabase),
        );

        await expectLater(
          gateway.issueInvoice(_startRequest()),
          throwsA(
            isA<IssuanceNotReadyException>()
                .having((error) => error.blockers, 'blockers', [
                  'SOURCE_SNAPSHOT_UNAVAILABLE',
                  'BUYER_SOURCE_UNAVAILABLE',
                ])
                .having(
                  (error) => error.code,
                  'code',
                  EInvoiceBlockedCodes.issuanceNotReady,
                ),
          ),
        );
      },
    );

    test('maps IDEMPOTENCY_CONFLICT to blocked code', () async {
      final supabase = FakeEinvoiceRpcSupabase()
        ..registerHandler('issue_invoice', (_) async {
          throw RpcException(
            'IDEMPOTENCY_CONFLICT: same idempotency key with different business intent',
          );
        });
      final gateway = SupabaseIssuanceCommandGateway(
        rpcClient: _rpcClient(supabase),
      );

      await expectLater(
        gateway.issueInvoice(_startRequest()),
        throwsA(
          isA<EInvoiceBlockedException>().having(
            (error) => error.code,
            'code',
            EInvoiceBlockedCodes.idempotencyConflict,
          ),
        ),
      );
    });
  });

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

    test('preparePublish fails closed on unknown action', () async {
      supabase.registerHandler('prepare_issuance_publish', (_) async {
        return [
          {'action': 'CALL_PROVIDER_TWICE'},
        ];
      });

      await expectLater(
        gateway.preparePublish(
          tenantId: tenantId,
          attemptId: attemptId,
          idempotencyKey: idempotencyKey,
          payloadHash: payloadHash,
          canonicalInvoice: canonical,
        ),
        throwsA(
          isA<EInvoiceBlockedException>().having(
            (error) => error.code,
            'code',
            EInvoiceBlockedCodes.systemError,
          ),
        ),
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

    test('recordSuccess fails closed on malformed evidence subtype', () async {
      await expectLater(
        gateway.recordSuccess(
          tenantId: tenantId,
          attemptId: attemptId,
          evidence: IssuanceResultEvidenceDto.undetermined(
            idempotencyKey: idempotencyKey,
            payloadHash: payloadHash,
            reasonCode: 'PROVIDER_TIMEOUT',
          ),
        ),
        throwsA(isA<RpcException>()),
      );
      expect(supabase.calls, isEmpty);
    });
  });

  group('SupabaseOrderInvoiceProjectionReadGateway', () {
    test('maps projection row to DTO', () async {
      final supabase = FakeEinvoiceRpcSupabase()
        ..registerHandler('get_order_invoice_projection', (params) async {
          expect(params, {
            'p_tenant_id': 'tenant-1',
            'p_actor_id': 'actor-1',
            'p_sales_order_id': 'order-1',
          });
          return [
            {
              'sales_order_id': 'order-1',
              'issuance_display_state': 'processing',
              'delivery_display_state': 'NOT_SENT',
              'has_secondary_attention': false,
              'actions': <String>[],
            },
          ];
        });
      final gateway = SupabaseOrderInvoiceProjectionReadGateway(
        rpcClient: _rpcClient(supabase),
      );

      final projection = await gateway.getBySalesOrder(
        tenantId: 'tenant-1',
        actorId: 'actor-1',
        salesOrderId: 'order-1',
      );

      expect(projection.salesOrderId, 'order-1');
      expect(projection.issuanceDisplayState, IssuanceDisplayState.processing);
      expect(projection.deliveryDisplayState, DeliveryDisplayState.notSent);
      expect(projection.hasSecondaryAttention, isFalse);
      expect(projection.actions, isEmpty);
    });

    test('fails closed on missing projection display state', () async {
      final supabase = FakeEinvoiceRpcSupabase()
        ..registerHandler('get_order_invoice_projection', (_) async {
          return [
            {'sales_order_id': 'order-1', 'actions': <String>[]},
          ];
        });
      final gateway = SupabaseOrderInvoiceProjectionReadGateway(
        rpcClient: _rpcClient(supabase),
      );

      await expectLater(
        gateway.getBySalesOrder(
          tenantId: 'tenant-1',
          actorId: 'actor-1',
          salesOrderId: 'order-1',
        ),
        throwsA(
          isA<EInvoiceBlockedException>().having(
            (error) => error.code,
            'code',
            EInvoiceBlockedCodes.systemError,
          ),
        ),
      );
    });
  });

  group('IssuanceRpcMapper', () {
    test('issueInvoiceParams passes sourceVersion unchanged', () {
      final params = IssuanceRpcMapper.issueInvoiceParams(_startRequest());
      expect(params['p_source_version'], 'etag:7f9d-opaque');
    });
  });

  group('mapEinvoiceRpcError', () {
    test('parses nested blockers from ISSUANCE_NOT_READY envelope', () {
      final error = mapEinvoiceRpcError(
        RpcException(
          'ISSUANCE_NOT_READY: {"details":{"blockers":["SOURCE_SNAPSHOT_UNAVAILABLE"]}}',
        ),
      );

      expect(error, isA<IssuanceNotReadyException>());
      expect((error as IssuanceNotReadyException).blockers, [
        'SOURCE_SNAPSHOT_UNAVAILABLE',
      ]);
    });
  });

  group('S2b boundary guard', () {
    test(
      'does not expose IIssuanceSourceSnapshotPort in application ports',
      () {
        var dir = Directory.current;
        while (!Directory(
          '${dir.path}/modules/einvoice/application/lib/src/ports',
        ).existsSync()) {
          final parent = dir.parent;
          if (parent.path == dir.path) {
            fail('Could not locate einvoice application ports directory');
          }
          dir = parent;
        }
        final portsDir = Directory(
          '${dir.path}/modules/einvoice/application/lib/src/ports',
        );
        final portSources = portsDir
            .listSync(recursive: true)
            .whereType<File>()
            .where((file) => file.path.endsWith('.dart'))
            .map((file) => file.readAsStringSync())
            .join('\n');
        expect(portSources.contains('IIssuanceSourceSnapshotPort'), isFalse);
      },
    );
  });
}
