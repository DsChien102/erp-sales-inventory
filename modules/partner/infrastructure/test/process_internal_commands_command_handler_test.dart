import 'package:test/test.dart';
import 'package:vet45_partner_application/application.dart';
import 'package:vet45_partner_infrastructure/infrastructure.dart';
import 'package:vet45_shared_infrastructure/infrastructure.dart';

final class _FakeInternalCommandClient implements IPartnerInternalCommandClient {
  _FakeInternalCommandClient({required this.rows});

  final List<PartnerInternalCommandRow> rows;
  final List<String> completed = [];
  final List<String> failed = [];

  @override
  Future<List<PartnerInternalCommandRow>> claimBatch({
    required String tenantId,
    int batchSize = 10,
  }) async =>
      rows;

  @override
  Future<void> complete({
    required String tenantId,
    required String commandId,
    required String claimToken,
  }) async {
    completed.add(commandId);
  }

  @override
  Future<void> fail({
    required String tenantId,
    required String commandId,
    required String claimToken,
    required String error,
  }) async {
    failed.add(commandId);
  }
}

PartnerInternalCommandRow _recordRow({
  String commandId = 'cmd-1',
  String commandType = RecordPartnerTransactionHistoryCommand.commandType,
}) {
  return PartnerInternalCommandRow(
    commandId: commandId,
    claimToken: 'claim-1',
    commandType: commandType,
    payload: {
      'tenant_id': 'tenant-1',
      'business_partner_id': 'partner-1',
      'transaction_role': 'customer',
      'source_module': 'sales',
      'source_type': 'order',
      'source_id': 'order-1',
      'transaction_date': '2026-06-30T11:00:00Z',
    },
  );
}

void main() {
  test('returns false when internal command batch is empty', () async {
    final handler = ProcessInternalCommandsCommandHandler(
      commandClient: _FakeInternalCommandClient(rows: const []),
      commandBus: CommandBus(),
    );

    final hadWork = await handler.handle(
      ProcessInternalCommandsCommand(tenantId: 'tenant-1'),
    );

    expect(hadWork, isFalse);
  });

  test('executes command through the bus and completes the row', () async {
    final executed = <RecordPartnerTransactionHistoryCommand>[];
    final commandBus = CommandBus()
      ..register<RecordPartnerTransactionHistoryCommand, void>(
        (command) async => executed.add(command),
      );
    final client = _FakeInternalCommandClient(rows: [_recordRow()]);
    final handler = ProcessInternalCommandsCommandHandler(
      commandClient: client,
      commandBus: commandBus,
    );

    final hadWork = await handler.handle(
      ProcessInternalCommandsCommand(tenantId: 'tenant-1'),
    );

    expect(hadWork, isTrue);
    expect(executed.single.sourceId, 'order-1');
    expect(client.completed, ['cmd-1']);
    expect(client.failed, isEmpty);
  });

  test('fails and skips rows with an unsupported command type', () async {
    final commandBus = CommandBus();
    final client = _FakeInternalCommandClient(
      rows: [_recordRow(commandType: 'partner.unknown')],
    );
    final handler = ProcessInternalCommandsCommandHandler(
      commandClient: client,
      commandBus: commandBus,
    );

    final hadWork = await handler.handle(
      ProcessInternalCommandsCommand(tenantId: 'tenant-1'),
    );

    expect(hadWork, isTrue);
    expect(client.failed, ['cmd-1']);
    expect(client.completed, isEmpty);
  });

  test('fails the row and rethrows when execution throws', () async {
    final commandBus = CommandBus()
      ..register<RecordPartnerTransactionHistoryCommand, void>(
        (command) async => throw StateError('write failed'),
      );
    final client = _FakeInternalCommandClient(rows: [_recordRow()]);
    final handler = ProcessInternalCommandsCommandHandler(
      commandClient: client,
      commandBus: commandBus,
    );

    await expectLater(
      handler.handle(ProcessInternalCommandsCommand(tenantId: 'tenant-1')),
      throwsA(isA<StateError>()),
    );
    expect(client.failed, ['cmd-1']);
    expect(client.completed, isEmpty);
  });
}
