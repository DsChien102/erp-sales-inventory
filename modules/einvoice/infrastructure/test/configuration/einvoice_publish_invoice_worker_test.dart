import 'dart:async';

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

import '../support/in_memory_publish_series_lease_gateway.dart';

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
    final now = DateTime.now().toUtc();
    final pending = _commands
        .where(
          (c) =>
              c.tenantId == tenantId &&
              c.processedAt == null &&
              c.failedAt == null &&
              c.claimToken == null &&
              !(c.enqueuedAtOverride ?? c.enqueuedAt).isAfter(now),
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

  @override
  Future<void> reschedule({
    required String tenantId,
    required String commandId,
    required String claimToken,
    required Duration delay,
  }) async {
    final command = _findClaimed(
      tenantId: tenantId,
      commandId: commandId,
      claimToken: claimToken,
    );
    if (command == null) {
      return;
    }
    events.add('reschedule-$commandId');
    command.claimToken = null;
    command.enqueuedAtOverride = DateTime.now().toUtc().add(delay);
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
  DateTime? enqueuedAtOverride;
}

final class _WorkerMeInvoiceProviderPort implements IMeInvoiceProviderPort {
  _WorkerMeInvoiceProviderPort({required this.events, this.publishGate});

  final List<String> events;
  Future<void>? publishGate;
  MeInvoicePublishOutcome? nextPublishOutcome;

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
    required String statusLookupKey,
    required String invoiceSeries,
    required String idempotencyKey,
    required String payloadHash,
    IssuanceProviderStatusLookup statusLookup =
        IssuanceProviderStatusLookup.providerTransactionId,
  }) async => throw UnimplementedError();

  @override
  Future<MeInvoicePublishOutcome> publish({
    required String tenantId,
    required Map<String, Object?> canonicalInvoice,
    required String idempotencyKey,
  }) async {
    final attemptId = canonicalInvoice['__attemptId'] as String;
    if (publishGate != null) {
      await publishGate;
    }
    events.add('publish-$attemptId');
    if (nextPublishOutcome != null) {
      return nextPublishOutcome!;
    }
    return MeInvoicePublishSuccess(
      providerReference: 'tx-$attemptId',
      invoiceNumber: '0000001',
      invoiceSeries: '1C25TYY',
      issuedAt: DateTime.utc(2026, 8, 1),
    );
  }
}

final class _DurableRetryIssuanceResultGateway
    implements IIssuanceResultGateway {
  _DurableRetryIssuanceResultGateway({
    required this.events,
    required this.internalClient,
    required this.tenantId,
  });

  final List<String> events;
  final _RecordingInternalCommandClient internalClient;
  final String tenantId;
  final retryCountsByAttempt = <String, int>{};
  final _sourceCommandsById = <String, PublishInvoiceCommand>{};
  final _recordedOutcomesBySourceCommandId =
      <String, RecordIssuanceResultDto>{};
  int terminalFailureCalls = 0;

  void rememberSourceCommand(PublishInvoiceCommand command) {
    _sourceCommandsById[command.id] = command;
  }

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
  Future<RecordIssuanceResultDto> recordRetryableProviderRejection({
    required String tenantId,
    required String attemptId,
    required String sourceCommandId,
    required IssuanceResultEvidenceDto evidence,
    required Duration retryAfter,
  }) async {
    final replay = _recordedOutcomesBySourceCommandId[sourceCommandId];
    if (replay != null) {
      events.add('retryable-replay-$sourceCommandId');
      return replay;
    }

    final source = _sourceCommandsById[sourceCommandId];
    if (source == null || source.attemptId != attemptId) {
      throw StateError(
        'missing source publish command $sourceCommandId for attempt $attemptId',
      );
    }

    final currentCount = retryCountsByAttempt[attemptId] ?? 0;
    if (currentCount >= 3) {
      terminalFailureCalls++;
      events.add('retryable-exhausted-$attemptId');
      const outcome = RecordIssuanceResultDto(
        attemptStatus: IssuanceAttemptStatus.failed,
      );
      _recordedOutcomesBySourceCommandId[sourceCommandId] = outcome;
      return outcome;
    }

    final nextCount = currentCount + 1;
    retryCountsByAttempt[attemptId] = nextCount;
    events.add('retryable-$attemptId-$nextCount');

    final retryCommand = PublishInvoiceCommand(
      id: 'cmd-retry-$attemptId-$nextCount',
      tenantId: this.tenantId,
      attemptId: attemptId,
      payloadHash: source.payloadHash,
      idempotencyKey: source.idempotencyKey,
      canonicalInvoice: source.canonicalInvoice,
    );
    rememberSourceCommand(retryCommand);
    internalClient.enqueue(retryCommand);

    const outcome = RecordIssuanceResultDto(
      attemptStatus: IssuanceAttemptStatus.preparing,
    );
    _recordedOutcomesBySourceCommandId[sourceCommandId] = outcome;
    return outcome;
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

final class _WorkerIssuanceResultGateway implements IIssuanceResultGateway {
  _WorkerIssuanceResultGateway({required this.events});

  final List<String> events;

  @override
  Future<PublishPreparationDto> preparePublish({
    required String tenantId,
    required String attemptId,
    required String idempotencyKey,
    required String payloadHash,
    IssuanceProviderStatusLookup statusLookup =
        IssuanceProviderStatusLookup.providerTransactionId,
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
  Future<RecordIssuanceResultDto> recordRetryableProviderRejection({
    required String tenantId,
    required String attemptId,
    required String sourceCommandId,
    required IssuanceResultEvidenceDto evidence,
    required Duration retryAfter,
  }) async {
    events.add('retryable-$attemptId');
    return const RecordIssuanceResultDto(
      attemptStatus: IssuanceAttemptStatus.preparing,
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

Map<String, Object?> _canonicalForAttempt(
  String attemptId, {
  String invoiceSeries = '1C25TYY',
}) {
  return <String, Object?>{
    '__attemptId': attemptId,
    'refId': 'ref-$attemptId',
    'invSeries': invoiceSeries,
    'signType': 2,
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

        final leaseGateway = InMemoryPublishSeriesLeaseGateway();
        final container = GetIt.asNewInstance();
        container
          ..registerSingleton<IPublishSeriesLeaseGateway>(leaseGateway)
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
              leaseGateway: container.get<IPublishSeriesLeaseGateway>(),
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

    test(
      'two workers same series: second command reschedules while first holds lease',
      () async {
        const tenantId = 'tenant-worker-busy';
        final events = <String>[];
        final publishGate = Completer<void>();
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
        final leaseGateway = InMemoryPublishSeriesLeaseGateway(
          busyRetryAfter: Duration.zero,
        );
        final container = GetIt.asNewInstance();
        container
          ..registerSingleton<IPublishSeriesLeaseGateway>(leaseGateway)
          ..registerSingleton<IMeInvoiceProviderPort>(
            _WorkerMeInvoiceProviderPort(
              events: events,
              publishGate: publishGate.future,
            ),
          )
          ..registerSingleton<IIssuanceResultGateway>(
            _WorkerIssuanceResultGateway(events: events),
          )
          ..registerFactory(
            () => PublishInvoiceCommandHandler(
              providerPort: container.get<IMeInvoiceProviderPort>(),
              resultGateway: container.get<IIssuanceResultGateway>(),
              leaseGateway: container.get<IPublishSeriesLeaseGateway>(),
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

        final firstWorker = bus.execute(
          ProcessInternalCommandsCommand(tenantId: tenantId, batchSize: 1),
        );
        final secondWorker = bus.execute(
          ProcessInternalCommandsCommand(tenantId: tenantId, batchSize: 1),
        );
        await Future<void>.delayed(Duration.zero);
        await secondWorker;
        expect(events, contains('reschedule-cmd-2'));
        expect(events, isNot(contains('publish-2')));

        publishGate.complete();
        await firstWorker;
        expect(events, contains('publish-1'));
        expect(events, contains('complete-1'));

        expect(
          await bus.execute(
            ProcessInternalCommandsCommand(tenantId: tenantId, batchSize: 1),
          ),
          isTrue,
        );
        expect(events, contains('publish-2'));
      },
    );

    test('different series can publish in parallel', () async {
      const tenantId = 'tenant-worker-parallel';
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
      final leaseGateway = InMemoryPublishSeriesLeaseGateway();
      final container = GetIt.asNewInstance();
      container
        ..registerSingleton<IPublishSeriesLeaseGateway>(leaseGateway)
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
            leaseGateway: container.get<IPublishSeriesLeaseGateway>(),
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
          canonicalInvoice: _canonicalForAttempt('1', invoiceSeries: '1C25TYY'),
        ),
      );
      internalClient.enqueue(
        PublishInvoiceCommand(
          id: 'cmd-3',
          tenantId: tenantId,
          attemptId: '3',
          payloadHash: 'hash-3',
          idempotencyKey: 'b1b2c3d4-e5f6-7890-abcd-ef1234567891',
          canonicalInvoice: _canonicalForAttempt('3', invoiceSeries: '2K26TYY'),
        ),
      );

      expect(
        await bus.execute(
          ProcessInternalCommandsCommand(tenantId: tenantId, batchSize: 2),
        ),
        isTrue,
      );
      expect(events, containsAll(['publish-1', 'publish-3']));
      expect(events, isNot(contains('reschedule-cmd-3')));
    });

    test(
      'stale owner cannot release active lease held by another worker',
      () async {
        const tenantId = 'tenant-worker-stale';
        final leaseGateway = InMemoryPublishSeriesLeaseGateway();
        final first = await leaseGateway.tryAcquire(
          tenantId: tenantId,
          attemptId: '1',
          ownerToken: 'owner-a',
        );
        expect(first, isA<PublishSeriesLeaseAcquired>());
        final acquired = first as PublishSeriesLeaseAcquired;

        await leaseGateway.release(
          tenantId: tenantId,
          providerConnectionId: acquired.providerConnectionId,
          invoiceSeries: acquired.invoiceSeries,
          ownerToken: 'owner-b',
          leaseVersion: acquired.leaseVersion,
        );

        final second = await leaseGateway.tryAcquire(
          tenantId: tenantId,
          attemptId: '2',
          ownerToken: 'owner-b',
        );
        expect(second, isA<PublishSeriesLeaseBusy>());

        await leaseGateway.release(
          tenantId: tenantId,
          providerConnectionId: acquired.providerConnectionId,
          invoiceSeries: acquired.invoiceSeries,
          ownerToken: 'owner-a',
          leaseVersion: acquired.leaseVersion,
        );

        final third = await leaseGateway.tryAcquire(
          tenantId: tenantId,
          attemptId: '2',
          ownerToken: 'owner-b',
        );
        expect(third, isA<PublishSeriesLeaseAcquired>());
      },
    );

    test(
      'retryable provider rejection schedules durable retry without dead-letter',
      () async {
        const tenantId = 'tenant-worker-retry';
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
        final leaseGateway = InMemoryPublishSeriesLeaseGateway();
        final provider = _WorkerMeInvoiceProviderPort(events: events)
          ..nextPublishOutcome = const MeInvoicePublishRetryableRejection(
            providerCode: 'InvoiceNumberNotCotinuous',
            providerMessage: 'gap',
            retryAfter: Duration(seconds: 5),
          );
        final container = GetIt.asNewInstance();
        container
          ..registerSingleton<IPublishSeriesLeaseGateway>(leaseGateway)
          ..registerSingleton<IMeInvoiceProviderPort>(provider)
          ..registerSingleton<IIssuanceResultGateway>(
            _WorkerIssuanceResultGateway(events: events),
          )
          ..registerFactory(
            () => PublishInvoiceCommandHandler(
              providerPort: container.get<IMeInvoiceProviderPort>(),
              resultGateway: container.get<IIssuanceResultGateway>(),
              leaseGateway: container.get<IPublishSeriesLeaseGateway>(),
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
            id: 'cmd-retry-1',
            tenantId: tenantId,
            attemptId: '1',
            payloadHash: 'hash-retry-1',
            idempotencyKey: '88d18970-380a-4138-bbce-e25049ca9e3c',
            canonicalInvoice: _canonicalForAttempt('1'),
          ),
        );

        expect(
          await bus.execute(
            ProcessInternalCommandsCommand(tenantId: tenantId, batchSize: 1),
          ),
          isTrue,
        );
        expect(events, contains('retryable-1'));
        expect(events, isNot(contains('dead_letter-cmd-retry-1')));
        expect(events, isNot(contains('retry-cmd-retry-1')));
      },
    );

    test(
      'retryable rejection survives worker restart via durable enqueue',
      () async {
        const tenantId = 'tenant-worker-restart';
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
        final leaseGateway = InMemoryPublishSeriesLeaseGateway();
        final resultGateway = _DurableRetryIssuanceResultGateway(
          events: events,
          internalClient: internalClient,
          tenantId: tenantId,
        );
        final provider = _WorkerMeInvoiceProviderPort(events: events)
          ..nextPublishOutcome = const MeInvoicePublishRetryableRejection(
            providerCode: 'InvoiceNumberNotCotinuous',
            providerMessage: 'gap',
            retryAfter: Duration(seconds: 5),
          );

        Future<CommandBus> buildWorkerBus() {
          final container = GetIt.asNewInstance();
          container
            ..registerSingleton<IPublishSeriesLeaseGateway>(leaseGateway)
            ..registerSingleton<IMeInvoiceProviderPort>(provider)
            ..registerSingleton<IIssuanceResultGateway>(resultGateway)
            ..registerFactory(
              () => PublishInvoiceCommandHandler(
                providerPort: container.get<IMeInvoiceProviderPort>(),
                resultGateway: container.get<IIssuanceResultGateway>(),
                leaseGateway: container.get<IPublishSeriesLeaseGateway>(),
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
          return Future.value(bus);
        }

        const idempotencyKey = '88d18970-380a-4138-bbce-e25049ca9e3c';
        final sourceCommand = PublishInvoiceCommand(
          id: 'cmd-retry-1',
          tenantId: tenantId,
          attemptId: '1',
          payloadHash: 'hash-retry-1',
          idempotencyKey: idempotencyKey,
          canonicalInvoice: _canonicalForAttempt('1'),
        );
        resultGateway.rememberSourceCommand(sourceCommand);
        internalClient.enqueue(sourceCommand);

        final worker1 = await buildWorkerBus();
        expect(
          await worker1.execute(
            ProcessInternalCommandsCommand(tenantId: tenantId, batchSize: 1),
          ),
          isTrue,
        );
        expect(resultGateway.retryCountsByAttempt['1'], 1);
        expect(events, contains('retryable-1-1'));

        provider.nextPublishOutcome = null;

        final worker2 = await buildWorkerBus();
        expect(
          await worker2.execute(
            ProcessInternalCommandsCommand(tenantId: tenantId, batchSize: 1),
          ),
          isTrue,
        );

        expect(events.where((e) => e == 'publish-1'), hasLength(2));
        expect(events, contains('result-1'));
        expect(events, isNot(contains('deadLetter-1')));
      },
    );

    test(
      'replaying the same provider command does not increment or enqueue twice',
      () async {
        const tenantId = 'tenant-worker-replay';
        const sourceCommandId = 'cmd-replay-source';
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
        final gateway = _DurableRetryIssuanceResultGateway(
          events: events,
          internalClient: internalClient,
          tenantId: tenantId,
        );
        gateway.rememberSourceCommand(
          PublishInvoiceCommand(
            id: sourceCommandId,
            tenantId: tenantId,
            attemptId: '1',
            payloadHash: 'hash-replay',
            idempotencyKey: '88d18970-380a-4138-bbce-e25049ca9e3c',
            canonicalInvoice: _canonicalForAttempt('1'),
          ),
        );
        final evidence = IssuanceResultEvidenceDto.retryableProviderRejection(
          idempotencyKey: '88d18970-380a-4138-bbce-e25049ca9e3c',
          payloadHash: 'hash-replay',
          providerCode: 'InvoiceNumberNotCotinuous',
          providerMessage: 'gap',
        );

        final first = await gateway.recordRetryableProviderRejection(
          tenantId: tenantId,
          attemptId: '1',
          sourceCommandId: sourceCommandId,
          evidence: evidence,
          retryAfter: const Duration(seconds: 5),
        );
        final replay = await gateway.recordRetryableProviderRejection(
          tenantId: tenantId,
          attemptId: '1',
          sourceCommandId: sourceCommandId,
          evidence: evidence,
          retryAfter: const Duration(seconds: 5),
        );

        expect(first.attemptStatus, IssuanceAttemptStatus.preparing);
        expect(replay.attemptStatus, IssuanceAttemptStatus.preparing);
        expect(gateway.retryCountsByAttempt['1'], 1);
        expect(internalClient._commands, hasLength(1));
        expect(events, contains('retryable-replay-$sourceCommandId'));
      },
    );

    test(
      'three durable retries then settle failed without a fourth child command',
      () async {
        const tenantId = 'tenant-worker-exhaustion';
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
        final resultGateway = _DurableRetryIssuanceResultGateway(
          events: events,
          internalClient: internalClient,
          tenantId: tenantId,
        );
        final provider = _WorkerMeInvoiceProviderPort(events: events)
          ..nextPublishOutcome = const MeInvoicePublishRetryableRejection(
            providerCode: 'InvoiceNumberNotCotinuous',
            providerMessage: 'gap',
            retryAfter: Duration(seconds: 5),
          );
        final leaseGateway = InMemoryPublishSeriesLeaseGateway();
        final container = GetIt.asNewInstance();
        container
          ..registerSingleton<IPublishSeriesLeaseGateway>(leaseGateway)
          ..registerSingleton<IMeInvoiceProviderPort>(provider)
          ..registerSingleton<IIssuanceResultGateway>(resultGateway)
          ..registerFactory(
            () => PublishInvoiceCommandHandler(
              providerPort: container.get<IMeInvoiceProviderPort>(),
              resultGateway: container.get<IIssuanceResultGateway>(),
              leaseGateway: container.get<IPublishSeriesLeaseGateway>(),
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

        final source = PublishInvoiceCommand(
          id: 'cmd-exhaustion-source',
          tenantId: tenantId,
          attemptId: '1',
          payloadHash: 'hash-exhaustion',
          idempotencyKey: '88d18970-380a-4138-bbce-e25049ca9e3c',
          canonicalInvoice: _canonicalForAttempt('1'),
        );
        resultGateway.rememberSourceCommand(source);
        internalClient.enqueue(source);

        for (var run = 0; run < 4; run++) {
          expect(
            await bus.execute(
              ProcessInternalCommandsCommand(tenantId: tenantId, batchSize: 1),
            ),
            isTrue,
          );
        }

        expect(resultGateway.retryCountsByAttempt['1'], 3);
        expect(resultGateway.terminalFailureCalls, 1);
        expect(internalClient._commands, hasLength(4));
        expect(events.where((event) => event == 'publish-1'), hasLength(4));
        expect(events, contains('retryable-exhausted-1'));
        expect(
          await bus.execute(
            ProcessInternalCommandsCommand(tenantId: tenantId, batchSize: 1),
          ),
          isFalse,
        );
      },
    );

    test('expired lease allows another worker to acquire', () async {
      const tenantId = 'tenant-worker-expiry';
      final leaseGateway = InMemoryPublishSeriesLeaseGateway(
        leaseDuration: const Duration(milliseconds: 1),
      );
      final first = await leaseGateway.tryAcquire(
        tenantId: tenantId,
        attemptId: '1',
        ownerToken: 'owner-a',
      );
      final acquired = first as PublishSeriesLeaseAcquired;
      leaseGateway.expireLease(
        tenantId: tenantId,
        providerConnectionId: acquired.providerConnectionId,
        invoiceSeries: acquired.invoiceSeries,
      );

      final second = await leaseGateway.tryAcquire(
        tenantId: tenantId,
        attemptId: '2',
        ownerToken: 'owner-b',
      );
      expect(second, isA<PublishSeriesLeaseAcquired>());
    });
  });
}
