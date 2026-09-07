import 'package:test/test.dart';
import 'package:vet45_einvoice_infrastructure/src/configuration/processing/einvoice_integration_event_dispatcher.dart';
import 'package:vet45_einvoice_infrastructure/src/configuration/processing/inbox/i_einvoice_inbox_client.dart';
import 'package:vet45_einvoice_infrastructure/src/configuration/processing/inbox/process_inbox_command.dart';
import 'package:vet45_einvoice_infrastructure/src/configuration/processing/inbox/process_inbox_command_handler.dart';
import 'package:vet45_partner_integration_events/integration_events.dart';
import 'package:vet45_sales_integration_events/integration_events.dart';
import 'package:vet45_shared_infrastructure/infrastructure.dart';

final class _FakeEinvoiceInboxClient implements IEinvoiceInboxClient {
  final List<ClaimedInboxMessage> messages;
  final List<String> completedIds = [];
  final List<(String id, String error)> failedIds = [];
  final List<Map<String, dynamic>> receivedMessages = [];

  _FakeEinvoiceInboxClient(this.messages);

  @override
  Future<String> receive({
    required String tenantId,
    required String messageId,
    required String eventType,
    required Map<String, dynamic> payload,
    required DateTime occurredAt,
  }) async {
    receivedMessages.add({
      'tenantId': tenantId,
      'messageId': messageId,
      'eventType': eventType,
      'payload': payload,
      'occurredAt': occurredAt,
    });
    return messageId;
  }

  @override
  Future<List<ClaimedInboxMessage>> claimBatch({
    required String tenantId,
    required int limit,
  }) async {
    return messages;
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
    failedIds.add((messageId, error));
  }
}

final class _RecordingHandler<T extends TenantScopedIntegrationEvent>
    implements IIntegrationEventNotificationHandler<T> {
  final List<T> handled = [];
  bool shouldThrow = false;

  @override
  Future<void> handle(T event) async {
    if (shouldThrow) {
      throw Exception('Handler failure');
    }
    handled.add(event);
  }
}

void main() {
  group('ProcessInboxCommandHandler & EinvoiceIntegrationEventDispatcher', () {
    test(
      'dispatches sales.order.completed from inbox and completes message',
      () async {
        final dispatcher = EinvoiceIntegrationEventDispatcher();
        final salesHandler =
            _RecordingHandler<SalesOrderCompletedIntegrationEvent>();
        dispatcher.register<SalesOrderCompletedIntegrationEvent>(salesHandler);

        final message = ClaimedInboxMessage(
          messageId: 'msg-001',
          eventType: SalesOrderCompletedIntegrationEvent.type,
          payload: {
            'id': 'msg-001',
            'occurred_on': '2026-08-29T10:00:00.000Z',
            'tenant_id': 'tenant-1',
            'sales_order_id': 'order-100',
            'source_version': 'sales-v1',
          },
          occurredAt: DateTime.utc(2026, 8, 29, 10, 0, 0),
          claimToken: 'tok-1',
        );

        final client = _FakeEinvoiceInboxClient([message]);
        final handler = ProcessInboxCommandHandler(
          inboxClient: client,
          integrationEventDispatcher: dispatcher,
        );

        final hadWork = await handler.handle(
          ProcessInboxCommand(tenantId: 'tenant-1', batchSize: 10),
        );

        expect(hadWork, isTrue);
        expect(salesHandler.handled, hasLength(1));
        expect(salesHandler.handled.single.salesOrderId, 'order-100');
        expect(client.completedIds, contains('msg-001'));
        expect(client.failedIds, isEmpty);
      },
    );

    test(
      'dispatches partner.partner.profile_updated from inbox and completes message',
      () async {
        final dispatcher = EinvoiceIntegrationEventDispatcher();
        final partnerHandler =
            _RecordingHandler<PartnerProfileUpdatedIntegrationEvent>();
        dispatcher.register<PartnerProfileUpdatedIntegrationEvent>(
          partnerHandler,
        );

        final message = ClaimedInboxMessage(
          messageId: 'msg-002',
          eventType: PartnerProfileUpdatedIntegrationEvent.type,
          payload: {
            'id': 'msg-002',
            'occurred_on': '2026-08-29T10:00:00.000Z',
            'tenant_id': 'tenant-1',
            'partner_id': 'partner-200',
          },
          occurredAt: DateTime.utc(2026, 8, 29, 10, 0, 0),
          claimToken: 'tok-2',
        );

        final client = _FakeEinvoiceInboxClient([message]);
        final handler = ProcessInboxCommandHandler(
          inboxClient: client,
          integrationEventDispatcher: dispatcher,
        );

        final hadWork = await handler.handle(
          ProcessInboxCommand(tenantId: 'tenant-1', batchSize: 10),
        );

        expect(hadWork, isTrue);
        expect(partnerHandler.handled, hasLength(1));
        expect(partnerHandler.handled.single.partnerId, 'partner-200');
        expect(client.completedIds, contains('msg-002'));
        expect(client.failedIds, isEmpty);
      },
    );

    test('fails message when event type is unknown', () async {
      final dispatcher = EinvoiceIntegrationEventDispatcher();
      final message = ClaimedInboxMessage(
        messageId: 'msg-003',
        eventType: 'unknown.event.type',
        payload: {
          'id': 'msg-003',
          'occurred_on': '2026-08-29T10:00:00.000Z',
          'tenant_id': 'tenant-1',
        },
        occurredAt: DateTime.utc(2026, 8, 29, 10, 0, 0),
        claimToken: 'tok-3',
      );

      final client = _FakeEinvoiceInboxClient([message]);
      final handler = ProcessInboxCommandHandler(
        inboxClient: client,
        integrationEventDispatcher: dispatcher,
      );

      final hadWork = await handler.handle(
        ProcessInboxCommand(tenantId: 'tenant-1', batchSize: 10),
      );

      expect(hadWork, isTrue);
      expect(client.completedIds, isEmpty);
      expect(client.failedIds, hasLength(1));
      expect(client.failedIds.single.$1, 'msg-003');
      expect(client.failedIds.single.$2, contains('Unknown event type'));
    });

    test(
      'fails message when payload event id does not match messageId',
      () async {
        final dispatcher = EinvoiceIntegrationEventDispatcher();
        final message = ClaimedInboxMessage(
          messageId: 'msg-004',
          eventType: SalesOrderCompletedIntegrationEvent.type,
          payload: {
            'id': 'different-id',
            'occurred_on': '2026-08-29T10:00:00.000Z',
            'tenant_id': 'tenant-1',
            'sales_order_id': 'order-1',
            'source_version': 'sales-v1',
          },
          occurredAt: DateTime.utc(2026, 8, 29, 10, 0, 0),
          claimToken: 'tok-4',
        );

        final client = _FakeEinvoiceInboxClient([message]);
        final handler = ProcessInboxCommandHandler(
          inboxClient: client,
          integrationEventDispatcher: dispatcher,
        );

        await handler.handle(
          ProcessInboxCommand(tenantId: 'tenant-1', batchSize: 10),
        );

        expect(client.completedIds, isEmpty);
        expect(client.failedIds, hasLength(1));
        expect(client.failedIds.single.$2, contains('does not match'));
      },
    );

    test('fails message when handler throws exception', () async {
      final dispatcher = EinvoiceIntegrationEventDispatcher();
      final salesHandler =
          _RecordingHandler<SalesOrderCompletedIntegrationEvent>()
            ..shouldThrow = true;
      dispatcher.register<SalesOrderCompletedIntegrationEvent>(salesHandler);

      final message = ClaimedInboxMessage(
        messageId: 'msg-005',
        eventType: SalesOrderCompletedIntegrationEvent.type,
        payload: {
          'id': 'msg-005',
          'occurred_on': '2026-08-29T10:00:00.000Z',
          'tenant_id': 'tenant-1',
          'sales_order_id': 'order-1',
          'source_version': 'sales-v1',
        },
        occurredAt: DateTime.utc(2026, 8, 29, 10, 0, 0),
        claimToken: 'tok-5',
      );

      final client = _FakeEinvoiceInboxClient([message]);
      final handler = ProcessInboxCommandHandler(
        inboxClient: client,
        integrationEventDispatcher: dispatcher,
      );

      await handler.handle(
        ProcessInboxCommand(tenantId: 'tenant-1', batchSize: 10),
      );

      expect(client.completedIds, isEmpty);
      expect(client.failedIds, hasLength(1));
      expect(client.failedIds.single.$2, contains('Handler failure'));
    });
  });
}
