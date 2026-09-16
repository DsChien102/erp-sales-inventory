import 'package:messaging_worker/messaging_worker_bootstrap.dart';
import 'package:messaging_worker/tenant_discovery_client.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase/supabase.dart';
import 'package:test/test.dart';
import 'package:vet45_einvoice_application/application.dart';
import 'package:vet45_einvoice_infrastructure/src/configuration/events_bus/einvoice_integration_event_generic_handler.dart';
import 'package:vet45_einvoice_infrastructure/src/configuration/processing/einvoice_integration_event_dispatcher.dart';
import 'package:vet45_einvoice_infrastructure/src/configuration/processing/generated/einvoice_integration_event_registry.g.dart';
import 'package:vet45_einvoice_infrastructure/src/configuration/processing/inbox/i_einvoice_inbox_client.dart';
import 'package:vet45_einvoice_infrastructure/src/configuration/processing/inbox/process_inbox_command.dart';
import 'package:vet45_einvoice_infrastructure/src/configuration/processing/inbox/process_inbox_command_handler.dart';
import 'package:vet45_sales_infrastructure/infrastructure.dart' as sales;
import 'package:vet45_sales_infrastructure/src/configuration/processing/outbox/i_sales_outbox_client.dart';
import 'package:vet45_sales_infrastructure/src/configuration/processing/outbox/process_outbox_command_handler.dart';
import 'package:vet45_sales_integration_events/integration_events.dart';
import 'package:vet45_shared_application/application.dart';
import 'package:vet45_shared_infrastructure/infrastructure.dart';

class _FakeSupabaseClient extends Fake implements SupabaseClient {}

const _baseConfig = WorkerEnv(
  supabaseUrl: 'https://example.supabase.co',
  supabaseServiceRoleKey: 'service-role-key',
  tickSecret: 'secret',
  tenantBatchSize: 20,
  moduleBatchSize: 10,
  maxRoundsPerTick: 5,
  concurrency: 4,
  misaAppId: 'test-app-id',
  misaBaseUrl: 'https://testapi.meinvoice.vn/api/integration',
);

void main() {
  group('Sales outbox → E-invoice inbox → auto-issue transport', () {
    late _FakeSalesOutboxClient fakeSalesOutbox;
    late _TransportEinvoiceInboxClient fakeEinvoiceInbox;
    late _RecordingEinvoiceCommandDispatcher recordingDispatcher;
    late InMemoryEventBusClient sharedBus;
    late ProcessOutboxCommandHandler salesOutboxHandler;
    late ProcessInboxCommandHandler einvoiceInboxHandler;

    setUp(() {
      IntegrationEventTypeRegistry.clear();
      IntegrationEventTypeRegistry.registerAll(
        EinvoiceIntegrationEventRegistry.eventTypes,
      );

      fakeSalesOutbox = _FakeSalesOutboxClient();
      fakeEinvoiceInbox = _TransportEinvoiceInboxClient();
      recordingDispatcher = _RecordingEinvoiceCommandDispatcher();
      sharedBus = InMemoryEventBusClient();

      sharedBus.subscribe(
        EinvoiceIntegrationEventGenericHandler<SalesOrderFinalizedIntegrationEvent>(
          inboxClient: fakeEinvoiceInbox,
        ),
      );

      salesOutboxHandler = ProcessOutboxCommandHandler(
        outboxClient: fakeSalesOutbox,
        eventsBus: sharedBus,
      );

      final dispatcher = EinvoiceIntegrationEventDispatcher()
        ..register<SalesOrderFinalizedIntegrationEvent>(
          SalesOrderFinalizedIntegrationEventHandler(
            commands: recordingDispatcher,
          ),
        );
      einvoiceInboxHandler = ProcessInboxCommandHandler(
        inboxClient: fakeEinvoiceInbox,
        integrationEventDispatcher: dispatcher,
      );
    });

    tearDown(IntegrationEventTypeRegistry.clear);

    test(
      'raw Sales finalized outbox reaches StartAutoIssuance without inbox inject',
      () async {
        fakeSalesOutbox.add(
          eventType: SalesOrderFinalizedIntegrationEvent.type,
          messageId: 'event-001',
          occurredAt: DateTime.utc(2026, 9, 15, 10, 2, 57),
          payload: const {
            'salesOrderId': 'order-123',
            'salesOrderVersion': 1,
          },
        );

        await salesOutboxHandler.handle(
          sales.ProcessOutboxCommand(tenantId: 'tenant-1'),
        );
        await einvoiceInboxHandler.handle(
          ProcessInboxCommand(tenantId: 'tenant-1'),
        );

        expect(fakeSalesOutbox.completedIds, ['event-001']);
        expect(fakeSalesOutbox.failedIds, isEmpty);
        expect(fakeEinvoiceInbox.completedIds, ['event-001']);
        expect(fakeEinvoiceInbox.directlyInjectedIds, isEmpty);
        expect(recordingDispatcher.startCalls, hasLength(1));
        expect(recordingDispatcher.startCalls.single.salesOrderId, 'order-123');
        expect(
          recordingDispatcher.startCalls.single.triggerKey,
          'sales_order_finalized.v1:event-001:order-123:1',
        );
      },
    );

    test('replay of same outbox message starts auto-issue only once', () async {
      fakeSalesOutbox.add(
        eventType: SalesOrderFinalizedIntegrationEvent.type,
        messageId: 'event-001',
        occurredAt: DateTime.utc(2026, 9, 15, 10, 2, 57),
        payload: const {
          'salesOrderId': 'order-123',
          'salesOrderVersion': 1,
        },
      );

      await salesOutboxHandler.handle(
        sales.ProcessOutboxCommand(tenantId: 'tenant-1'),
      );
      // Re-queue same business identity after first complete (inbox receive dedupe).
      fakeSalesOutbox.add(
        eventType: SalesOrderFinalizedIntegrationEvent.type,
        messageId: 'event-001',
        occurredAt: DateTime.utc(2026, 9, 15, 10, 2, 57),
        payload: const {
          'salesOrderId': 'order-123',
          'salesOrderVersion': 1,
        },
      );
      await salesOutboxHandler.handle(
        sales.ProcessOutboxCommand(tenantId: 'tenant-1'),
      );
      await einvoiceInboxHandler.handle(
        ProcessInboxCommand(tenantId: 'tenant-1'),
      );
      await einvoiceInboxHandler.handle(
        ProcessInboxCommand(tenantId: 'tenant-1'),
      );

      expect(fakeEinvoiceInbox.uniqueReceivedIds, 1);
      expect(recordingDispatcher.startCalls, hasLength(1));
      expect(
        recordingDispatcher.startCalls.single.triggerKey,
        'sales_order_finalized.v1:event-001:order-123:1',
      );
    });

    test('legacy finalized payload resolves source version 1', () async {
      fakeSalesOutbox.add(
        eventType: SalesOrderFinalizedIntegrationEvent.type,
        messageId: 'event-legacy',
        occurredAt: DateTime.utc(2026, 9, 15, 10, 2, 57),
        payload: const {'salesOrderId': 'order-legacy'},
      );

      await salesOutboxHandler.handle(
        sales.ProcessOutboxCommand(tenantId: 'tenant-1'),
      );
      await einvoiceInboxHandler.handle(
        ProcessInboxCommand(tenantId: 'tenant-1'),
      );

      expect(recordingDispatcher.startCalls, hasLength(1));
      expect(
        recordingDispatcher.startCalls.single.triggerKey,
        'sales_order_finalized.v1:event-legacy:order-legacy:1',
      );
      expect(
        recordingDispatcher.startCalls.single.idempotencyKey,
        AutoIssuanceIdempotencyKey.generate(
          tenantId: 'tenant-1',
          salesOrderId: 'order-legacy',
          sourceVersion: '1',
        ),
      );
    });

    test('non-finalized Sales fact does not create E-invoice inbox work', () async {
      fakeSalesOutbox.add(
        eventType: 'sales_payment_recorded.v1',
        messageId: 'event-pay',
        occurredAt: DateTime.utc(2026, 9, 15, 10, 2, 57),
        payload: const {'salesOrderId': 'order-pay'},
      );

      await salesOutboxHandler.handle(
        sales.ProcessOutboxCommand(tenantId: 'tenant-1'),
      );
      await einvoiceInboxHandler.handle(
        ProcessInboxCommand(tenantId: 'tenant-1'),
      );

      expect(fakeSalesOutbox.completedIds, ['event-pay']);
      expect(fakeEinvoiceInbox.uniqueReceivedIds, 0);
      expect(fakeEinvoiceInbox.completedIds, isEmpty);
      expect(recordingDispatcher.startCalls, isEmpty);
    });

    test('sales outbox publish failure fails claim and does not complete', () async {
      final throwingBus = _ThrowingEventsBus();
      final handler = ProcessOutboxCommandHandler(
        outboxClient: fakeSalesOutbox,
        eventsBus: throwingBus,
      );
      fakeSalesOutbox.add(
        eventType: SalesOrderFinalizedIntegrationEvent.type,
        messageId: 'event-fail',
        occurredAt: DateTime.utc(2026, 9, 15, 10, 2, 57),
        payload: const {
          'salesOrderId': 'order-fail',
          'salesOrderVersion': 1,
        },
      );

      await handler.handle(sales.ProcessOutboxCommand(tenantId: 'tenant-1'));

      expect(fakeSalesOutbox.completedIds, isEmpty);
      expect(fakeSalesOutbox.failedIds, ['event-fail']);
      expect(fakeEinvoiceInbox.uniqueReceivedIds, 0);
      expect(recordingDispatcher.startCalls, isEmpty);
    });
  });

  group('MessagingWorkerLoop sales discovery', () {
    test('routes sales/outbox discovery to Sales mediator', () async {
      final salesMediator = _RecordingMediator();
      final context = await MessagingWorkerBootstrap.bootstrap(
        config: _baseConfig,
        supabaseClient: _FakeSupabaseClient(),
        modules: [
          MessagingModuleBinding(
            moduleSchema: 'sales',
            mediator: salesMediator,
            commands: const SalesMessagingCommandFactory(),
          ),
        ],
      );
      final loop = MessagingWorkerLoop(
        context: context,
        discoveryClient: _SingleRoundDiscoveryClient([
          PendingMessagingWork(
            tenantId: 'tenant-1',
            moduleSchema: 'sales',
            queueType: 'outbox',
            pendingCount: 1,
            oldestCreatedAt: DateTime.utc(2026, 9, 15),
          ),
        ]),
      );

      final result = await loop.runOnce();

      expect(result.errorsCount, 0);
      expect(salesMediator.commands, hasLength(1));
      expect(salesMediator.commands.single, isA<sales.ProcessOutboxCommand>());
      expect(
        (salesMediator.commands.single as sales.ProcessOutboxCommand).tenantId,
        'tenant-1',
      );
    });
  });
}

final class _RecordingMediator implements IModuleMediator {
  final List<ICommand<dynamic>> commands = <ICommand<dynamic>>[];

  @override
  Future<TResult> executeCommandAsync<TResult>(ICommand<TResult> command) async {
    commands.add(command);
    return true as TResult;
  }

  @override
  Future<TResult> executeQueryAsync<TResult>(IQuery<TResult> query) {
    throw UnimplementedError();
  }
}

final class _SingleRoundDiscoveryClient implements ITenantDiscoveryClient {
  _SingleRoundDiscoveryClient(this._rows);

  final List<PendingMessagingWork> _rows;
  var _served = false;

  @override
  Future<List<PendingMessagingWork>> listTenantsWithPendingMessaging({
    required int limit,
    List<String>? modules,
  }) async {
    if (_served) {
      return const [];
    }
    _served = true;
    final allowed = modules;
    return _rows
        .where(
          (row) => allowed == null || allowed.contains(row.moduleSchema),
        )
        .take(limit)
        .toList(growable: false);
  }
}

final class _ThrowingEventsBus implements IEventsBus {
  @override
  void subscribe<T extends IntegrationEvent>(
    IIntegrationEventHandler<T> handler,
  ) {}

  @override
  Future<void> publish(IntegrationEvent event) {
    throw StateError('bus publish failed');
  }
}

final class _RecordingEinvoiceCommandDispatcher implements IEinvoiceCommandDispatcher {
  final List<StartAutoIssuanceCommand> startCalls = <StartAutoIssuanceCommand>[];

  @override
  Future<TResult> execute<TResult>(ICommand<TResult> command) async {
    switch (command) {
      case StartAutoIssuanceCommand c:
        startCalls.add(c);
        return const AutoIssuanceResultDto(
              started: true,
              skipped: false,
              processId: 'proc-1',
              attemptId: 'att-1',
            )
            as TResult;
      default:
        throw UnsupportedError('Unsupported ${command.runtimeType}');
    }
  }
}

final class _FakeSalesOutboxClient implements ISalesOutboxClient {
  final List<ClaimedSalesOutboxMessage> _pending = <ClaimedSalesOutboxMessage>[];
  final List<String> completedIds = <String>[];
  final List<String> failedIds = <String>[];

  void add({
    required String eventType,
    required String messageId,
    required DateTime occurredAt,
    required Map<String, dynamic> payload,
  }) {
    _pending.add(
      ClaimedSalesOutboxMessage(
        messageId: messageId,
        eventType: eventType,
        payload: Map<String, dynamic>.from(payload),
        occurredAt: occurredAt,
        claimToken: 'claim-$messageId',
      ),
    );
  }

  @override
  Future<List<ClaimedSalesOutboxMessage>> claimBatch({
    required String tenantId,
    required int limit,
  }) async {
    final claimed = _pending.take(limit).toList(growable: false);
    _pending.removeRange(0, claimed.length);
    return claimed;
  }

  @override
  Future<void> complete({
    required String tenantId,
    required String messageId,
    required String claimToken,
  }) async {
    completedIds.add(messageId);
  }

  @override
  Future<void> fail({
    required String tenantId,
    required String messageId,
    required String claimToken,
    required String error,
  }) async {
    failedIds.add(messageId);
  }
}

/// Inbox that becomes claimable only via [receive] (bus path), not direct inject.
final class _TransportEinvoiceInboxClient implements IEinvoiceInboxClient {
  final List<ClaimedInboxMessage> _pending = <ClaimedInboxMessage>[];
  final Set<String> _receivedIds = <String>{};
  final List<String> completedIds = <String>[];
  final List<String> directlyInjectedIds = <String>[];

  int get uniqueReceivedIds => _receivedIds.length;

  @override
  Future<String> receive({
    required String tenantId,
    required String messageId,
    required String eventType,
    required Map<String, dynamic> payload,
    required DateTime occurredAt,
  }) async {
    if (_receivedIds.contains(messageId)) {
      return messageId;
    }
    _receivedIds.add(messageId);
    _pending.add(
      ClaimedInboxMessage(
        messageId: messageId,
        eventType: eventType,
        payload: Map<String, dynamic>.from(payload),
        occurredAt: occurredAt,
        claimToken: 'inbox-$messageId',
      ),
    );
    return messageId;
  }

  /// Test-only escape hatch — tracking proves E2E did not use it.
  void injectDirectly(ClaimedInboxMessage message) {
    directlyInjectedIds.add(message.messageId);
    _pending.add(message);
  }

  @override
  Future<List<ClaimedInboxMessage>> claimBatch({
    required String tenantId,
    required int limit,
  }) async {
    final claimed = _pending.take(limit).toList(growable: false);
    _pending.removeRange(0, claimed.length);
    return claimed;
  }

  @override
  Future<void> complete({
    required String tenantId,
    required String messageId,
    required String claimToken,
  }) async {
    completedIds.add(messageId);
  }

  @override
  Future<void> fail({
    required String tenantId,
    required String messageId,
    required String claimToken,
    required String error,
  }) async {
    // Keep pending empty after claim; failures are tracked via completedIds absence.
  }
}
