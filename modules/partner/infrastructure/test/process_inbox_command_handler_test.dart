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

final class _RecordingInternalCommandDispatcher
    implements IPartnerInternalCommandDispatcher {
  final List<InternalCommandBase<void>> dispatched = [];
  Object? throwOnDispatch;

  @override
  Future<void> dispatch(InternalCommandBase<void> command) async {
    if (throwOnDispatch != null) {
      throw throwOnDispatch!;
    }
    dispatched.add(command);
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
  IPartnerInternalCommandDispatcher dispatcher,
) {
  final eventDispatcher = PartnerIntegrationEventDispatcher()
    ..register<SalesOrderCheckedOutIntegrationEvent>(
      SalesOrderCheckedOutIntegrationEventHandler(
        internalCommandDispatcher: dispatcher,
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
    final handler = _handler(client, _RecordingInternalCommandDispatcher());

    final hadWork = await handler.handle(ProcessInboxCommand(tenantId: 'tenant-1'));

    expect(hadWork, isFalse);
  });

  test('dispatches to consumer handler and completes the message', () async {
    final client = _FakeInboxClient(
      rows: [_message(eventType: SalesOrderCheckedOutIntegrationEvent.type)],
    );
    final dispatcher = _RecordingInternalCommandDispatcher();
    final handler = _handler(client, dispatcher);

    final hadWork = await handler.handle(ProcessInboxCommand(tenantId: 'tenant-1'));

    expect(hadWork, isTrue);
    expect(client.completed, ['event-1']);
    expect(client.failed, isEmpty);
    final command = dispatcher.dispatched.single as RecordPartnerTransactionHistoryCommand;
    expect(command.sourceId, 'order-1');
    expect(command.sourceCode, 'SO-001');
    expect(command.transactionRole, PartnerRole.customer);
  });

  test('fails unknown event types without dispatching', () async {
    final client = _FakeInboxClient(rows: [_message(eventType: 'unknown.event')]);
    final dispatcher = _RecordingInternalCommandDispatcher();
    final handler = _handler(client, dispatcher);

    final hadWork = await handler.handle(ProcessInboxCommand(tenantId: 'tenant-1'));

    expect(hadWork, isTrue);
    expect(client.failed, ['event-1']);
    expect(client.completed, isEmpty);
    expect(dispatcher.dispatched, isEmpty);
  });

  test('fails message and rethrows when the consumer handler throws', () async {
    final client = _FakeInboxClient(
      rows: [_message(eventType: SalesOrderCheckedOutIntegrationEvent.type)],
    );
    final dispatcher = _RecordingInternalCommandDispatcher()
      ..throwOnDispatch = StateError('projection failed');
    final handler = _handler(client, dispatcher);

    await expectLater(
      handler.handle(ProcessInboxCommand(tenantId: 'tenant-1')),
      throwsA(isA<StateError>()),
    );
    expect(client.failed, ['event-1']);
    expect(client.completed, isEmpty);
  });
}
