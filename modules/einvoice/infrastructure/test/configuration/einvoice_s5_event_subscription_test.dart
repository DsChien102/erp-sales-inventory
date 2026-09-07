import 'package:get_it/get_it.dart';
import 'package:supabase/supabase.dart';
import 'package:test/test.dart';
import 'package:vet45_einvoice_application/application.dart';
import 'package:vet45_einvoice_infrastructure/infrastructure.dart';
import 'package:vet45_einvoice_infrastructure/src/configuration/outbox/outbox_module.dart';
import 'package:vet45_einvoice_infrastructure/src/configuration/processing/einvoice_integration_event_dispatcher.dart';
import 'package:vet45_einvoice_infrastructure/src/configuration/processing/generated/einvoice_integration_event_registry.g.dart'
    hide EinvoiceOutboxEventSerializer;
import 'package:vet45_einvoice_infrastructure/src/configuration/processing/inbox/i_einvoice_inbox_client.dart';
import 'package:vet45_einvoice_infrastructure/src/configuration/processing/inbox/process_inbox_command.dart';
import 'package:vet45_einvoice_infrastructure/src/configuration/processing/inbox/process_inbox_command_handler.dart';
import 'package:vet45_einvoice_infrastructure/src/configuration/processing/outbox/i_einvoice_outbox_client.dart';
import 'package:vet45_einvoice_infrastructure/src/configuration/processing/outbox/process_outbox_command.dart';
import 'package:vet45_einvoice_infrastructure/src/configuration/processing/outbox/process_outbox_command_handler.dart'
    show EinvoiceOutboxEventSerializer, ProcessOutboxCommandHandler;
import 'package:vet45_einvoice_integration_events/integration_events.dart';
import 'package:vet45_shared_application/application.dart';
import 'package:vet45_shared_infrastructure/infrastructure.dart';

final class _TrackingInboxClient implements IEinvoiceInboxClient {
  final List<Map<String, dynamic>> received = [];
  final List<ClaimedInboxMessage> _pending = [];

  @override
  Future<String> receive({
    required String tenantId,
    required String messageId,
    required String eventType,
    required Map<String, dynamic> payload,
    required DateTime occurredAt,
  }) async {
    received.add({
      'tenantId': tenantId,
      'messageId': messageId,
      'eventType': eventType,
      'payload': payload,
    });
    _pending.add(
      ClaimedInboxMessage(
        messageId: messageId,
        eventType: eventType,
        payload: Map<String, dynamic>.from(payload),
        occurredAt: occurredAt,
        claimToken: 'tok-$messageId',
      ),
    );
    return messageId;
  }

  @override
  Future<List<ClaimedInboxMessage>> claimBatch({
    required String tenantId,
    required int limit,
  }) async {
    final batch = _pending.take(limit).toList(growable: false);
    _pending.removeRange(0, batch.length);
    return batch;
  }

  @override
  Future<void> complete({
    required String tenantId,
    required String messageId,
    required String claimToken,
  }) async {}

  @override
  Future<void> fail({
    required String tenantId,
    required String messageId,
    required String claimToken,
    required String error,
  }) async {}
}

final class _FakeOutboxClient implements IEinvoiceOutboxClient {
  _FakeOutboxClient(this.messages);

  final List<ClaimedOutboxMessage> messages;
  final List<String> completed = [];

  @override
  Future<List<ClaimedOutboxMessage>> claimBatch({
    required String tenantId,
    required int limit,
  }) async => messages.take(limit).toList(growable: false);

  @override
  Future<void> complete({
    required String tenantId,
    required String messageId,
    required String claimToken,
  }) async {
    completed.add(messageId);
  }

  @override
  Future<void> fail({
    required String tenantId,
    required String messageId,
    required String claimToken,
    required String error,
  }) async {}
}

final class _TrackingCommandDispatcher implements IEinvoiceCommandDispatcher {
  final List<ICommand<dynamic>> commands = [];

  @override
  Future<TResult> execute<TResult>(ICommand<TResult> command) async {
    commands.add(command);
    if (command is StartAutoDeliveryCommand) {
      return const AutoDeliveryResultDto(
            disposition: AutoDeliveryDisposition.started,
            deliveryId: 'del-1',
          )
          as TResult;
    }
    throw UnimplementedError(command.runtimeType.toString());
  }
}

void main() {
  group('Einvoice S5 event subscription', () {
    test('outbox module maps registered and delivery events', () {
      final mapper = OutboxModule.createDefault().mapper;
      expect(
        mapper.getType(ElectronicInvoiceRegisteredIntegrationEvent.type),
        ElectronicInvoiceRegisteredIntegrationEvent,
      );
      expect(
        mapper.getType(DeliveryResultRecordedIntegrationEvent.type),
        DeliveryResultRecordedIntegrationEvent,
      );
      expect(
        mapper.getType(DeliveryAttentionRequiredIntegrationEvent.type),
        DeliveryAttentionRequiredIntegrationEvent,
      );
    });

    test('registered outbox → bus → inbox → StartAutoDelivery', () async {
      final eventBus = InMemoryEventBusClient();
      final inbox = _TrackingInboxClient();
      final commands = _TrackingCommandDispatcher();

      registerGeneratedEinvoiceIntegrationEventSubscriptions(
        eventBus: eventBus,
        inboxClient: inbox,
        logger: const NullLoggerFactory().named('einvoice.events_bus'),
      );

      final messageId = 'evt-registered-1';
      final outbox = _FakeOutboxClient([
        ClaimedOutboxMessage(
          messageId: messageId,
          eventType: ElectronicInvoiceRegisteredIntegrationEvent.type,
          payload: {
            'electronic_invoice_id': 'ei-1',
            'sales_order_id': 'order-1',
          },
          occurredAt: DateTime.utc(2026, 9, 2, 10),
          claimToken: 'outbox-tok-1',
        ),
      ]);

      final processOutbox = ProcessOutboxCommandHandler(
        outboxClient: outbox,
        eventTypeMapper: OutboxModule.createDefault().mapper,
        eventsBus: eventBus,
      );

      final hadOutboxWork = await processOutbox.handle(
        ProcessOutboxCommand(tenantId: 'tenant-1', batchSize: 10),
      );
      expect(hadOutboxWork, isTrue);
      expect(outbox.completed, contains(messageId));
      expect(inbox.received, hasLength(1));
      expect(
        inbox.received.single['eventType'],
        ElectronicInvoiceRegisteredIntegrationEvent.type,
      );

      final dispatcher = EinvoiceIntegrationEventDispatcher();
      dispatcher.register<ElectronicInvoiceRegisteredIntegrationEvent>(
        ElectronicInvoiceRegisteredIntegrationEventHandler(commands: commands),
      );

      final hadInboxWork = await ProcessInboxCommandHandler(
        inboxClient: inbox,
        integrationEventDispatcher: dispatcher,
      ).handle(ProcessInboxCommand(tenantId: 'tenant-1', batchSize: 10));

      expect(hadInboxWork, isTrue);
      expect(commands.commands, hasLength(1));
      final start = commands.commands.single as StartAutoDeliveryCommand;
      expect(start.electronicInvoiceId, 'ei-1');
      expect(start.triggerId, messageId);
    });

    test(
      'startup wires OutboxModule mapper and inbox client for subscriptions',
      () {
        final container = GetIt.asNewInstance();
        EinvoiceStartup.initializeForTesting(
          supabase: SupabaseClient('https://dummy.supabase.co', 'dummy-key'),
          container: container,
          integrationEventBus: InMemoryEventBusClient(),
        );

        final mapper = container.get<IDomainNotificationMapper>();
        expect(
          mapper.getType(ElectronicInvoiceRegisteredIntegrationEvent.type),
          ElectronicInvoiceRegisteredIntegrationEvent,
        );
        expect(
          mapper.getType(DeliveryResultRecordedIntegrationEvent.type),
          DeliveryResultRecordedIntegrationEvent,
        );
        expect(
          mapper.getType(DeliveryAttentionRequiredIntegrationEvent.type),
          DeliveryAttentionRequiredIntegrationEvent,
        );
        expect(container.isRegistered<IEinvoiceInboxClient>(), isTrue);

        final registered = EinvoiceOutboxEventSerializer.fromPayload(
          eventType: ElectronicInvoiceRegisteredIntegrationEvent.type,
          payload: {
            'id': 'evt-startup-1',
            'occurred_on': '2026-09-02T11:00:00.000Z',
            'tenant_id': 'tenant-1',
            'electronic_invoice_id': 'ei-2',
            'sales_order_id': 'order-2',
          },
        );
        expect(registered, isA<ElectronicInvoiceRegisteredIntegrationEvent>());

        container.reset();
      },
    );
  });
}
