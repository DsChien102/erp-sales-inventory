import 'package:test/test.dart';
import 'package:vet45_partner_application/application.dart';
import 'package:vet45_partner_domain/domain.dart';
import 'package:vet45_partner_infrastructure/infrastructure.dart';
import 'package:vet45_partner_integration_events/integration_events.dart';
import 'package:vet45_shared_application/application.dart';

final class _FakeInboxClient implements IPartnerInboxClient {
  _FakeInboxClient({required this.rows});

  final List<PartnerInboxMessage> rows;
  final List<String> completed = [];
  final List<String> failed = [];

  @override
  Future<List<PartnerInboxMessage>> claimBatch({
    required String tenantId,
    int batchSize = 10,
  }) async =>
      rows;

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
  }) async {
    failed.add(messageId);
  }
}

final class _RecordingScheduler implements ICommandScheduler {
  final List<InternalCommandBase<void>> enqueued = [];
  Object? throwOnEnqueue;

  @override
  Future<String> enqueue(
    ICommand<void> command, {
    String? sourceEventId,
  }) async {
    if (throwOnEnqueue != null) {
      throw throwOnEnqueue!;
    }
    enqueued.add(command as InternalCommandBase<void>);
    return command.id;
  }
}

PartnerInboxMessage _message({
  required String eventType,
  String messageId = 'event-1',
  String claimToken = 'claim-1',
  Map<String, dynamic>? payload,
}) {
  return PartnerInboxMessage(
    messageId: messageId,
    claimToken: claimToken,
    eventType: eventType,
    occurredOn: DateTime.parse('2026-06-30T12:00:00Z'),
    payload: payload ??
        {
          'tenant_id': 'tenant-1',
          'business_partner_id': 'partner-1',
          'order_id': 'order-1',
          'order_code': 'SO-001',
        },
  );
}

ProcessInboxCommandHandler _handler(
  IPartnerInboxClient inboxClient,
  ICommandScheduler scheduler,
) {
  final eventDispatcher = PartnerIntegrationEventDispatcher()
    ..register<SalesOrderCheckedOutIntegrationEvent>(
      SalesOrderCheckedOutIntegrationEventHandler(
        commandScheduler: scheduler,
      ),
    );
  return ProcessInboxCommandHandler(
    inboxClient: inboxClient,
    integrationEventDispatcher: eventDispatcher,
  );
}

void main() {
  test('returns false when inbox batch is empty', () async {
    final client = _FakeInboxClient(rows: const []);
    final handler = _handler(client, _RecordingScheduler());

    final hadWork = await handler.handle(ProcessInboxCommand(tenantId: 'tenant-1'));

    expect(hadWork, isFalse);
  });

  test('enqueues via consumer handler and completes the message', () async {
    final client = _FakeInboxClient(
      rows: [_message(eventType: SalesOrderCheckedOutIntegrationEvent.type)],
    );
    final scheduler = _RecordingScheduler();
    final handler = _handler(client, scheduler);

    final hadWork = await handler.handle(ProcessInboxCommand(tenantId: 'tenant-1'));

    expect(hadWork, isTrue);
    expect(client.completed, ['event-1']);
    expect(client.failed, isEmpty);
    final command = scheduler.enqueued.single as RecordPartnerTransactionHistoryCommand;
    expect(command.sourceId, 'order-1');
    expect(command.sourceCode, 'SO-001');
    expect(command.transactionRole, PartnerRole.customer);
  });

  test('fails unknown event types without enqueueing', () async {
    final client = _FakeInboxClient(rows: [_message(eventType: 'unknown.event')]);
    final scheduler = _RecordingScheduler();
    final handler = _handler(client, scheduler);

    final hadWork = await handler.handle(ProcessInboxCommand(tenantId: 'tenant-1'));

    expect(hadWork, isTrue);
    expect(client.failed, ['event-1']);
    expect(client.completed, isEmpty);
    expect(scheduler.enqueued, isEmpty);
  });

  test('fails message and rethrows when the consumer handler throws', () async {
    final client = _FakeInboxClient(
      rows: [_message(eventType: SalesOrderCheckedOutIntegrationEvent.type)],
    );
    final scheduler = _RecordingScheduler()
      ..throwOnEnqueue = StateError('projection failed');
    final handler = _handler(client, scheduler);

    await expectLater(
      handler.handle(ProcessInboxCommand(tenantId: 'tenant-1')),
      throwsA(isA<StateError>()),
    );
    expect(client.failed, ['event-1']);
    expect(client.completed, isEmpty);
  });
}
