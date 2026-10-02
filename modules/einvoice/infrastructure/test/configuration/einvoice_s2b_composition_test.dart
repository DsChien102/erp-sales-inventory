import 'dart:io';

import 'package:get_it/get_it.dart';
import 'package:test/test.dart';
import 'package:uuid/uuid.dart';
import 'package:vet45_einvoice_application/application.dart';
import 'package:vet45_einvoice_domain/domain.dart';
import 'package:vet45_einvoice_infrastructure/infrastructure.dart';
import 'package:vet45_einvoice_infrastructure/src/configuration/processing/generated/einvoice_internal_command_registry.g.dart';
import 'package:vet45_einvoice_infrastructure/src/configuration/processing/outbox/process_outbox_command_handler.dart';
import 'package:vet45_einvoice_infrastructure/src/configuration/processing/processing_module.dart';
import 'package:vet45_einvoice_infrastructure/src/domain/issuance/supabase_issuance_command_gateway.dart';
import 'package:vet45_einvoice_infrastructure/src/domain/issuance/supabase_issuance_result_gateway.dart';
import 'package:vet45_einvoice_infrastructure/src/domain/issuance/supabase_order_invoice_projection_read_gateway.dart';
import 'package:vet45_einvoice_integration_events/integration_events.dart';
import 'package:vet45_shared_infrastructure/infrastructure.dart';

import '../support/fake_einvoice_rpc_supabase.dart';

void main() {
  group('Einvoice S2b composition', () {
    late GetIt container;
    late FakeEinvoiceRpcSupabase supabase;
    late EinvoiceRuntime runtime;

    setUp(() {
      container = GetIt.asNewInstance();
      supabase = FakeEinvoiceRpcSupabase();
      runtime = EinvoiceStartup.initializeForTesting(
        supabase: supabase,
        container: container,
      );
    });

    tearDown(() => container.reset());

    test('registers issuance command, result, and projection gateways', () {
      expect(
        container.get<IIssuanceCommandGateway>(),
        isA<SupabaseIssuanceCommandGateway>(),
      );
      expect(
        container.get<IIssuanceResultGateway>(),
        isA<SupabaseIssuanceResultGateway>(),
      );
      expect(
        container.get<IOrderInvoiceProjectionReadGateway>(),
        isA<SupabaseOrderInvoiceProjectionReadGateway>(),
      );
    });

    test(
      'client composition refuses worker-only MISA HTTP operations',
      () async {
        await expectLater(
          container.get<IMeInvoiceProviderPort>().authenticateAndListTemplates(
            tenantId: 'tenant-1',
            connectionId: 'connection-1',
          ),
          throwsA(
            isA<StateError>().having(
              (error) => error.message,
              'message',
              contains('worker-only'),
            ),
          ),
        );
      },
    );

    test('deserializes einvoice.fetch_official_view internal command', () {
      final serializer = container.get<InternalCommandSerializer>();

      final command = serializer.deserialize(
        commandType: FetchOfficialInvoiceViewCommand.type,
        payload: {
          'tenant_id': 'tenant-1',
          'electronic_invoice_id': 'ei-1',
          'request_id': 'req-1',
          'correlation_id': 'corr-1',
        },
        id: 'cmd-official-1',
      );

      expect(command, isA<FetchOfficialInvoiceViewCommand>());
      expect((command as FetchOfficialInvoiceViewCommand).requestId, 'req-1');
    });

    test('internal command client has no observation seeder', () {
      final source = File(
        'lib/src/configuration/processing/internal_commands/i_einvoice_internal_command_client.dart',
      ).readAsStringSync();
      expect(source, contains('seedDueReconciliationCommands'));
      expect(source, isNot(contains('seedDueProviderObservationCommands')));
    });

    test('deserializes einvoice.publish_invoice internal command', () {
      final serializer = container.get<InternalCommandSerializer>();
      const commandId = 'cmd-1';

      final command = serializer.deserialize(
        commandType: PublishInvoiceCommand.type,
        payload: {
          'tenant_id': 'tenant-1',
          'attempt_id': 'attempt-1',
          'canonical_invoice': <String, Object?>{'RefID': 'idem-1'},
          'payload_hash': 'hash-1',
          'idempotency_key': 'idem-1',
        },
        id: commandId,
      );

      expect(command, isA<PublishInvoiceCommand>());
      expect((command as PublishInvoiceCommand).attemptId, 'attempt-1');
      expect(command.idempotencyKey, 'idem-1');
    });

    test('internal command registry rejects unknown command type', () {
      final serializer = createGeneratedEinvoiceInternalCommandSerializer();

      expect(
        () => serializer.deserialize(
          commandType: 'einvoice.unknown_command',
          payload: const {},
          id: 'unknown',
        ),
        throwsA(
          isA<StateError>().having(
            (error) => error.toString(),
            'message',
            contains('Unknown command type'),
          ),
        ),
      );
      expect(
        serializer.deserialize(
          commandType: PublishInvoiceCommand.type,
          payload: {
            'tenant_id': 'tenant-1',
            'attempt_id': 'attempt-1',
            'canonical_invoice': const <String, Object?>{},
            'payload_hash': 'hash-1',
            'idempotency_key': 'idem-1',
          },
          id: 'cmd-1',
        ),
        isA<PublishInvoiceCommand>(),
      );
    });

    test('recordUndetermined routes only through typed result RPC', () async {
      const tenantId = 'tenant-1';
      const attemptId = 'attempt-1';
      const idempotencyKey = 'idem-1';
      const payloadHash = 'hash-1';

      supabase.registerHandler('record_issuance_undetermined', (params) async {
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

      final result = await container
          .get<IIssuanceResultGateway>()
          .recordUndetermined(
            tenantId: tenantId,
            attemptId: attemptId,
            evidence: IssuanceResultEvidenceDto.undetermined(
              idempotencyKey: idempotencyKey,
              payloadHash: payloadHash,
              reasonCode: 'PROVIDER_TIMEOUT',
            ),
          );

      expect(result.attemptStatus, IssuanceAttemptStatus.reconciling);
      expect(supabase.calls.map((call) => call.functionName), [
        'record_issuance_undetermined',
      ]);
    });

    test(
      'outbox module maps issuance processing, failed, and registered events',
      () {
        final mapper = EinvoiceOutboxModule.createDefault().mapper;

        expect(
          mapper.getType(IssuanceProcessingIntegrationEvent.type),
          IssuanceProcessingIntegrationEvent,
        );
        expect(
          mapper.getType(IssuanceFailedIntegrationEvent.type),
          IssuanceFailedIntegrationEvent,
        );
        expect(
          mapper.getType(ElectronicInvoiceRegisteredIntegrationEvent.type),
          ElectronicInvoiceRegisteredIntegrationEvent,
        );
      },
    );

    test('outbox serializer maps issuance integration events from payload', () {
      final occurredOn = DateTime.utc(2026, 8, 1, 12);

      final processing = EinvoiceOutboxEventSerializer.fromPayload(
        eventType: IssuanceProcessingIntegrationEvent.type,
        payload: {
          'id': const Uuid().v4(),
          'occurred_on': occurredOn.toIso8601String(),
          'tenant_id': 'tenant-1',
          'sales_order_id': 'order-1',
          'attempt_id': 'attempt-1',
        },
      );
      final failed = EinvoiceOutboxEventSerializer.fromPayload(
        eventType: IssuanceFailedIntegrationEvent.type,
        payload: {
          'id': const Uuid().v4(),
          'occurred_on': occurredOn.toIso8601String(),
          'tenant_id': 'tenant-1',
          'sales_order_id': 'order-1',
          'attempt_id': 'attempt-1',
        },
      );
      final registered = EinvoiceOutboxEventSerializer.fromPayload(
        eventType: ElectronicInvoiceRegisteredIntegrationEvent.type,
        payload: {
          'id': const Uuid().v4(),
          'occurred_on': occurredOn.toIso8601String(),
          'tenant_id': 'tenant-1',
          'electronic_invoice_id': 'invoice-1',
          'sales_order_id': 'order-1',
        },
      );

      expect(processing, isA<IssuanceProcessingIntegrationEvent>());
      expect(failed, isA<IssuanceFailedIntegrationEvent>());
      expect(registered, isA<ElectronicInvoiceRegisteredIntegrationEvent>());
    });

    test('projection query executes through read gateway', () async {
      supabase.registerHandler('get_order_invoice_projection', (params) async {
        expect(params, {
          'p_tenant_id': 'tenant-1',
          'p_actor_id': 'actor-1',
          'p_sales_order_id': 'order-1',
        });
        return [
          {
            'sales_order_id': 'order-1',
            'issuance_display_state': 'processing',
            'actions': <String>[],
          },
        ];
      });

      final projection = await runtime.module.executeQueryAsync(
        GetOrderInvoiceProjectionQuery(
          tenantId: 'tenant-1',
          actorId: 'actor-1',
          salesOrderId: 'order-1',
        ),
      );

      expect(projection.salesOrderId, 'order-1');
      expect(projection.issuanceDisplayState, IssuanceDisplayState.processing);
      expect(projection.actions, isEmpty);
      expect(
        supabase.calls.single.functionName,
        'get_order_invoice_projection',
      );
    });
  });
}
