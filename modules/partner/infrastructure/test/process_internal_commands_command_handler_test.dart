import 'package:get_it/get_it.dart';
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
  Future<void> enqueue({
    required String tenantId,
    required String commandId,
    required String commandType,
    required Map<String, dynamic> payload,
    String? sourceEventId,
  }) async {}

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
  String commandType = RecordPartnerTransactionHistoryCommand.type,
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

void _registerBus({
  required CommandBus commandBus,
  required GetIt container,
  required IPartnerInternalCommandClient client,
  required Future<void> Function(RecordPartnerTransactionHistoryCommand command) inner,
}) {
  commandBus.register<RecordPartnerTransactionHistoryCommand, void>((command) {
    final pipeline = PartnerCommandPipeline.buildInternalPipeline<
        RecordPartnerTransactionHistoryCommand>(
      container: container,
      inner: inner,
      commandClient: client,
    );
    return pipeline(command);
  });
}

void main() {
  test('returns false when internal command batch is empty', () async {
    final handler = ProcessInternalCommandsCommandHandler(
      commandClient: _FakeInternalCommandClient(rows: const []),
      serializer: createGeneratedPartnerInternalCommandSerializer(),
    );

    final hadWork = await handler.handle(
      ProcessInternalCommandsCommand(tenantId: 'tenant-1'),
    );

    expect(hadWork, isFalse);
  });

  test('executes command through the bus and completes the row', () async {
    final executed = <RecordPartnerTransactionHistoryCommand>[];
    final container = GetIt.asNewInstance();
    final client = _FakeInternalCommandClient(rows: [_recordRow()]);
    final commandBus = CommandBus(container: container);
    container.registerSingleton<CommandBus>(commandBus);
    container.registerSingleton<IPartnerInternalCommandClient>(client);
    _registerBus(
      commandBus: commandBus,
      container: container,
      client: client,
      inner: (command) async => executed.add(command),
    );
    PartnerCompositionRoot.setContainer(container);

    final handler = ProcessInternalCommandsCommandHandler(
      commandClient: client,
      serializer: createGeneratedPartnerInternalCommandSerializer(),
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
    final container = GetIt.asNewInstance();
    final client = _FakeInternalCommandClient(
      rows: [_recordRow(commandType: 'partner.unknown')],
    );
    final commandBus = CommandBus(container: container);
    container.registerSingleton<CommandBus>(commandBus);
    PartnerCompositionRoot.setContainer(container);

    final handler = ProcessInternalCommandsCommandHandler(
      commandClient: client,
      serializer: createGeneratedPartnerInternalCommandSerializer(),
    );

    final hadWork = await handler.handle(
      ProcessInternalCommandsCommand(tenantId: 'tenant-1'),
    );

    expect(hadWork, isTrue);
    expect(client.failed, ['cmd-1']);
    expect(client.completed, isEmpty);
  });

  test('fails the row and rethrows when execution throws', () async {
    final container = GetIt.asNewInstance();
    final client = _FakeInternalCommandClient(rows: [_recordRow()]);
    final commandBus = CommandBus(container: container);
    container.registerSingleton<CommandBus>(commandBus);
    container.registerSingleton<IPartnerInternalCommandClient>(client);
    _registerBus(
      commandBus: commandBus,
      container: container,
      client: client,
      inner: (command) async => throw StateError('write failed'),
    );
    PartnerCompositionRoot.setContainer(container);

    final handler = ProcessInternalCommandsCommandHandler(
      commandClient: client,
      serializer: createGeneratedPartnerInternalCommandSerializer(),
    );

    await expectLater(
      handler.handle(ProcessInternalCommandsCommand(tenantId: 'tenant-1')),
      throwsA(isA<StateError>()),
    );
    expect(client.failed, ['cmd-1']);
    expect(client.completed, isEmpty);
  });
}
