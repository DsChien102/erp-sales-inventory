import 'package:test/test.dart';
import 'package:vet45_sales_integration_events/integration_events.dart';
import 'package:vet45_shared_infrastructure/infrastructure.dart';

import 'package:vet45_sales_infrastructure/src/configuration/processing/outbox/i_sales_outbox_client.dart';
import 'package:vet45_sales_infrastructure/src/configuration/processing/outbox/process_outbox_command.dart';
import 'package:vet45_sales_infrastructure/src/configuration/processing/outbox/process_outbox_command_handler.dart';
import 'package:vet45_sales_infrastructure/src/configuration/processing/outbox/unrouted_sales_fact_integration_event.dart';

void main() {
  group('ProcessOutboxCommandHandler', () {
    test('publishes finalized row as typed event and completes it', () async {
      final bus = _RecordingEventsBus();
      final client = _FakeSalesOutboxClient()..addFinalizedLegacyRow();
      final handler = ProcessOutboxCommandHandler(
        outboxClient: client,
        eventsBus: bus,
      );

      final hadWork = await handler.handle(
        ProcessOutboxCommand(tenantId: 'tenant-1'),
      );

      expect(hadWork, isTrue);
      expect(bus.events.single, isA<SalesOrderFinalizedIntegrationEvent>());
      final event = bus.events.single as SalesOrderFinalizedIntegrationEvent;
      expect(event.salesOrderId, 'order-1');
      expect(event.sourceVersion, '1');
      expect(client.completedIds, ['event-1']);
      expect(client.failedIds, isEmpty);
    });

    test(
      'completes untyped Sales fact via UnroutedSalesFactIntegrationEvent',
      () async {
        final bus = _RecordingEventsBus();
        final client = _FakeSalesOutboxClient()
          ..addRow(
            messageId: 'event-2',
            eventType: 'sales_payment_recorded.v1',
            payload: const {'salesOrderId': 'order-2'},
          );
        final handler = ProcessOutboxCommandHandler(
          outboxClient: client,
          eventsBus: bus,
        );

        final hadWork = await handler.handle(
          ProcessOutboxCommand(tenantId: 'tenant-1'),
        );

        expect(hadWork, isTrue);
        expect(bus.events.single, isA<UnroutedSalesFactIntegrationEvent>());
        final event = bus.events.single as UnroutedSalesFactIntegrationEvent;
        expect(event.eventType, 'sales_payment_recorded.v1');
        expect(client.completedIds, ['event-2']);
        expect(client.failedIds, isEmpty);
      },
    );

    test('fails claim when publish throws and does not complete', () async {
      final bus = _ThrowingEventsBus();
      final client = _FakeSalesOutboxClient()..addFinalizedLegacyRow();
      final handler = ProcessOutboxCommandHandler(
        outboxClient: client,
        eventsBus: bus,
      );

      final hadWork = await handler.handle(
        ProcessOutboxCommand(tenantId: 'tenant-1'),
      );

      expect(hadWork, isTrue);
      expect(client.completedIds, isEmpty);
      expect(client.failedIds, ['event-1']);
      expect(client.lastFailClaimToken, 'claim-event-1');
    });

    test('returns false when claim batch is empty', () async {
      final handler = ProcessOutboxCommandHandler(
        outboxClient: _FakeSalesOutboxClient(),
        eventsBus: _RecordingEventsBus(),
      );

      final hadWork = await handler.handle(
        ProcessOutboxCommand(tenantId: 'tenant-1'),
      );

      expect(hadWork, isFalse);
    });
  });
}

final class _RecordingEventsBus implements IEventsBus {
  final List<IntegrationEvent> events = <IntegrationEvent>[];

  @override
  void subscribe<T extends IntegrationEvent>(
    IIntegrationEventHandler<T> handler,
  ) {}

  @override
  Future<void> publish(IntegrationEvent event) async {
    events.add(event);
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

final class _FakeSalesOutboxClient implements ISalesOutboxClient {
  final List<ClaimedSalesOutboxMessage> _pending = <ClaimedSalesOutboxMessage>[];
  final List<String> completedIds = <String>[];
  final List<String> failedIds = <String>[];
  String? lastFailClaimToken;

  void addFinalizedLegacyRow() {
    addRow(
      messageId: 'event-1',
      eventType: SalesOrderFinalizedIntegrationEvent.type,
      payload: const {'salesOrderId': 'order-1'},
    );
  }

  void addRow({
    required String messageId,
    required String eventType,
    required Map<String, dynamic> payload,
  }) {
    _pending.add(
      ClaimedSalesOutboxMessage(
        messageId: messageId,
        eventType: eventType,
        payload: Map<String, dynamic>.from(payload),
        occurredAt: DateTime.utc(2026, 9, 15, 10, 2, 57),
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
    lastFailClaimToken = claimToken;
  }
}
