import 'package:get_it/get_it.dart';
import 'package:quiver/collection.dart';
import 'package:test/test.dart';
import 'package:uuid/uuid.dart';
import 'package:vet45_einvoice_application/application.dart';
import 'package:vet45_einvoice_domain/domain.dart';
import 'package:vet45_einvoice_infrastructure/src/configuration/processing/commands_executor.dart';
import 'package:vet45_einvoice_infrastructure/src/configuration/processing/internal_commands/i_einvoice_internal_command_client.dart';
import 'package:vet45_einvoice_infrastructure/src/configuration/processing/internal_commands/process_internal_commands_command.dart';
import 'package:vet45_einvoice_infrastructure/src/configuration/processing/internal_commands/process_internal_commands_command_handler.dart';
import 'package:vet45_shared_application/application.dart';
import 'package:vet45_shared_infrastructure/infrastructure.dart';

final class _RecordingInternalCommandClient
    implements IEinvoiceInternalCommandClient {
  _RecordingInternalCommandClient({
    required this.serializer,
    required this.events,
  });

  final InternalCommandSerializer serializer;
  final List<String> events;
  final _commands = <_StoredInternalCommand>[];

  void enqueue(ISerializableInternalCommand command) {
    if (command is! CommandBase) {
      throw ArgumentError('command must extend CommandBase');
    }
    final base = command as CommandBase<void>;
    _commands.add(
      _StoredInternalCommand(
        id: base.id,
        tenantId: serializer.tenantIdOf(command),
        commandType: serializer.commandTypeOf(command),
        payload: serializer.toPayload(command),
        enqueuedAt: DateTime.now().toUtc(),
      ),
    );
  }

  @override
  Future<int> seedDueReconciliationCommands({
    required String tenantId,
    int limit = 50,
  }) async {
    return 0;
  }

  @override
  Future<List<ClaimedInternalCommand>> claimBatch({
    required String tenantId,
    required int limit,
  }) async {
    final pending = _commands
        .where(
          (c) =>
              c.tenantId == tenantId &&
              c.processedAt == null &&
              c.failedAt == null &&
              c.claimToken == null,
        )
        .take(limit)
        .toList(growable: false);

    final claimed = <ClaimedInternalCommand>[];
    for (final command in pending) {
      final token = const Uuid().v4();
      command.claimToken = token;
      claimed.add(
        ClaimedInternalCommand(
          commandId: command.id,
          commandType: command.commandType,
          payload: Map<String, dynamic>.from(command.payload),
          enqueuedAt: command.enqueuedAt,
          claimToken: token,
        ),
      );
    }
    return claimed;
  }

  @override
  Future<void> complete({
    required String tenantId,
    required String commandId,
    required String claimToken,
  }) async {
    final command = _findClaimed(
      tenantId: tenantId,
      commandId: commandId,
      claimToken: claimToken,
    );
    if (command == null) {
      return;
    }
    final attemptId = command.payload['attempt_id'] as String;
    events.add('complete-$attemptId');
    command.processedAt = DateTime.now().toUtc();
    command.claimToken = null;
  }

  @override
  Future<InternalCommandDisposition> retryOrDeadLetter({
    required String tenantId,
    required String commandId,
    required String claimToken,
    required String error,
  }) async {
    final command = _findClaimed(
      tenantId: tenantId,
      commandId: commandId,
      claimToken: claimToken,
    );
    if (command == null) {
      throw StateError('Command not found');
    }
    command.retryCount++;
    command.lastError = error;
    command.claimToken = null;
    if (command.retryCount >= 3) {
      command.failedAt = DateTime.now().toUtc();
      return InternalCommandDisposition.deadLetter;
    }
    return InternalCommandDisposition.retry;
  }

  @override
  Future<void> fail({
    required String tenantId,
    required String commandId,
    required String claimToken,
    required String error,
  }) async {
    final command = _findClaimed(
      tenantId: tenantId,
      commandId: commandId,
      claimToken: claimToken,
    );
    if (command == null) {
      return;
    }
    command.failedAt = DateTime.now().toUtc();
    command.lastError = error;
    command.claimToken = null;
  }

  _StoredInternalCommand? _findClaimed({
    required String tenantId,
    required String commandId,
    required String claimToken,
  }) {
    for (final command in _commands) {
      if (command.id == commandId &&
          command.tenantId == tenantId &&
          command.claimToken == claimToken) {
        return command;
      }
    }
    return null;
  }
}

final class _StoredInternalCommand {
  _StoredInternalCommand({
    required this.id,
    required this.tenantId,
    required this.commandType,
    required this.payload,
    required this.enqueuedAt,
  });

  final String id;
  final String tenantId;
  final String commandType;
  final Map<String, dynamic> payload;
  final DateTime enqueuedAt;
  int retryCount = 0;
  String? claimToken;
  DateTime? processedAt;
  DateTime? failedAt;
  String? lastError;
}

final class _WorkerMeInvoiceProviderPort implements IMeInvoiceProviderPort {
  _WorkerMeInvoiceProviderPort({required this.events});

  final List<String> events;

  @override
  Future<MeInvoiceAuthOutcome> authenticateAndListTemplates({
    required String tenantId,
    required String connectionId,
  }) async => throw UnimplementedError();

  @override
  Future<MeInvoicePreviewOutcome> previewUnpublished({
    required String tenantId,
    required Map<String, Object?> canonicalInvoice,
  }) async => throw UnimplementedError();

  @override
  void validateCanonical({required Map<String, Object?> canonicalInvoice}) {}

  @override
  Future<MeInvoiceIssuanceStatusOutcome> getStatus({
    required String tenantId,
    required String idempotencyKey,
    required String payloadHash,
    String? providerReference,
  }) async => throw UnimplementedError();

  @override
  Future<MeInvoicePublishOutcome> publish({
    required String tenantId,
    required Map<String, Object?> canonicalInvoice,
    required String idempotencyKey,
  }) async {
    final attemptId = canonicalInvoice['__attemptId'] as String;
    events.add('publish-$attemptId');
    return MeInvoicePublishSuccess(
      providerReference: 'tx-$attemptId',
      invoiceNumber: '0000001',
      invoiceSeries: '1C25TYY',
      issuedAt: DateTime.utc(2026, 8, 1),
    );
  }
}

final class _WorkerIssuanceResultGateway implements IIssuanceResultGateway {
  _WorkerIssuanceResultGateway({required this.events});

  final List<String> events;

  @override
  Future<PublishPreparationDto> preparePublish({
    required String tenantId,
    required String attemptId,
    required String idempotencyKey,
    required String payloadHash,
    required Map<String, Object?> canonicalInvoice,
  }) async {
    events.add('prepare-$attemptId');
    return const PublishPreparationDto(
      action: PublishPreparationAction.callProvider,
    );
  }

  @override
  Future<void> markProviderCallStarted({
    required String tenantId,
    required String attemptId,
  }) async {
    events.add('markProviderCallStarted-$attemptId');
  }

  @override
  Future<RecordIssuanceResultDto> recordSuccess({
    required String tenantId,
    required String attemptId,
    required IssuanceResultEvidenceDto evidence,
  }) async {
    events.add('result-$attemptId');
    return const RecordIssuanceResultDto(
      attemptStatus: IssuanceAttemptStatus.succeeded,
      electronicInvoiceId: 'ei-1',
    );
  }

  @override
  Future<RecordIssuanceResultDto> recordDefiniteFailure({
    required String tenantId,
    required String attemptId,
    required IssuanceResultEvidenceDto evidence,
  }) async {
    events.add('result-$attemptId');
    return const RecordIssuanceResultDto(
      attemptStatus: IssuanceAttemptStatus.failed,
    );
  }

  @override
  Future<RecordIssuanceResultDto> recordUndetermined({
    required String tenantId,
    required String attemptId,
    required IssuanceResultEvidenceDto evidence,
  }) async {
    events.add('result-$attemptId');
    return const RecordIssuanceResultDto(
      attemptStatus: IssuanceAttemptStatus.reconciling,
    );
  }

  @override
  Future<RecordIssuanceResultDto> recordCommandIntegrityFailure({
    required String tenantId,
    required String attemptId,
    required String reasonCode,
  }) async {
    events.add('integrityFailure-$attemptId');
    return const RecordIssuanceResultDto(
      attemptStatus: IssuanceAttemptStatus.failed,
    );
  }

  @override
  Future<RecordIssuanceResultDto> recordPublishCommandDeadLetter({
    required String tenantId,
    required String attemptId,
    required String reasonCode,
  }) async {
    events.add('deadLetter-$attemptId');
    return const RecordIssuanceResultDto(
      attemptStatus: IssuanceAttemptStatus.failed,
    );
  }
}

Map<String, Object?> _canonicalForAttempt(String attemptId) {
  return <String, Object?>{
    '__attemptId': attemptId,
    'refId': 'ref-$attemptId',
    'invSeries': '1C25TYY',
    'invDate': '2026-08-01',
    'totalAmount': 110000,
  };
}

void main() {
  group('Einvoice publish invoice worker', () {
    test(
      'processes two same-series commands sequentially without republish overlap',
      () async {
        const tenantId = 'tenant-worker-1';
        final events = <String>[];
        final serializer = InternalCommandSerializer(
          mapper: InternalCommandMapper(
            internalCommandMap: BiMap<String, Type>()
              ..[PublishInvoiceCommand.type] = PublishInvoiceCommand,
          ),
          deserializers: {
            PublishInvoiceCommand.type: PublishInvoiceCommand.fromJson,
          },
        );
        final internalClient = _RecordingInternalCommandClient(
          serializer: serializer,
          events: events,
        );

        final container = GetIt.asNewInstance();
        container
          ..registerSingleton<IMeInvoiceProviderPort>(
            _WorkerMeInvoiceProviderPort(events: events),
          )
          ..registerSingleton<IIssuanceResultGateway>(
            _WorkerIssuanceResultGateway(events: events),
          )
          ..registerFactory(
            () => PublishInvoiceCommandHandler(
              providerPort: container.get<IMeInvoiceProviderPort>(),
              resultGateway: container.get<IIssuanceResultGateway>(),
            ),
          );

        final bus = CommandBus(container: container);
        EinvoiceCommandsExecutor.bind(bus);
        bus.register<PublishInvoiceCommand, void>(
          (command) =>
              container.get<PublishInvoiceCommandHandler>().handle(command),
        );
        bus.register<ProcessInternalCommandsCommand, bool>(
          (command) => ProcessInternalCommandsCommandHandler(
            commandClient: internalClient,
            serializer: serializer,
          ).handle(command),
        );

        internalClient.enqueue(
          PublishInvoiceCommand(
            id: 'cmd-1',
            tenantId: tenantId,
            attemptId: '1',
            payloadHash: 'hash-1',
            idempotencyKey: '88d18970-380a-4138-bbce-e25049ca9e3c',
            canonicalInvoice: _canonicalForAttempt('1'),
          ),
        );
        internalClient.enqueue(
          PublishInvoiceCommand(
            id: 'cmd-2',
            tenantId: tenantId,
            attemptId: '2',
            payloadHash: 'hash-2',
            idempotencyKey: 'a1b2c3d4-e5f6-7890-abcd-ef1234567890',
            canonicalInvoice: _canonicalForAttempt('2'),
          ),
        );

        expect(
          await bus.execute(
            ProcessInternalCommandsCommand(tenantId: tenantId, batchSize: 1),
          ),
          isTrue,
        );
        expect(
          await bus.execute(
            ProcessInternalCommandsCommand(tenantId: tenantId, batchSize: 1),
          ),
          isTrue,
        );
        expect(
          await bus.execute(
            ProcessInternalCommandsCommand(tenantId: tenantId, batchSize: 1),
          ),
          isFalse,
        );

        expect(events, [
          'prepare-1',
          'markProviderCallStarted-1',
          'publish-1',
          'result-1',
          'complete-1',
          'prepare-2',
          'markProviderCallStarted-2',
          'publish-2',
          'result-2',
          'complete-2',
        ]);
      },
    );
  });
}
