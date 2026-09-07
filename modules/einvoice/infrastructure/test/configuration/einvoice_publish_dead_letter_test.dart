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
import 'package:vet45_einvoice_infrastructure/src/configuration/processing/internal_commands/publish_invoice_command_dead_letter_handler.dart';
import 'package:vet45_shared_application/application.dart';
import 'package:vet45_shared_infrastructure/infrastructure.dart';

final class _FakeInternalCommandClient
    implements IEinvoiceInternalCommandClient {
  _FakeInternalCommandClient({required this.serializer});

  final InternalCommandSerializer serializer;
  final List<_StoredCommand> commands = [];
  final List<String> events = [];

  void enqueue(ISerializableInternalCommand command) {
    if (command is! CommandBase) {
      throw ArgumentError('command must extend CommandBase');
    }
    final base = command as CommandBase<void>;
    commands.add(
      _StoredCommand(
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
    final pending = commands
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
          retryCount: command.retryCount,
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
    if (command == null) return;
    events.add('complete-${command.id}');
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
    if (command == null) throw StateError('Command not found');

    command.retryCount++;
    command.claimToken = null;
    command.lastError = error;

    if (command.retryCount >= 3) {
      command.failedAt = DateTime.now().toUtc();
      events.add('dead_letter-${command.id}');
      return InternalCommandDisposition.deadLetter;
    } else {
      events.add('retry-${command.id}');
      return InternalCommandDisposition.retry;
    }
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
    if (command == null) return;
    command.failedAt = DateTime.now().toUtc();
    command.lastError = error;
    command.claimToken = null;
  }

  _StoredCommand? _findClaimed({
    required String tenantId,
    required String commandId,
    required String claimToken,
  }) {
    for (final command in commands) {
      if (command.id == commandId &&
          command.tenantId == tenantId &&
          command.claimToken == claimToken) {
        return command;
      }
    }
    return null;
  }
}

final class _StoredCommand {
  _StoredCommand({
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

final class _DeadLetterMockProviderPort implements IMeInvoiceProviderPort {
  int publishCalls = 0;
  int validateCalls = 0;
  bool throwOnValidate = false;

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
  void validateCanonical({required Map<String, Object?> canonicalInvoice}) {
    validateCalls++;
    if (throwOnValidate) {
      throw const MeInvoiceCanonicalValidationException(
        'CANONICAL_INVALID: missing buyerLegalName',
      );
    }
  }

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
    publishCalls++;
    return MeInvoicePublishSuccess(
      providerReference: 'ref-1',
      invoiceNumber: '001',
      invoiceSeries: '1C25TYY',
      issuedAt: DateTime.utc(2026, 8, 1),
    );
  }
}

final class _DeadLetterMockResultGateway implements IIssuanceResultGateway {
  final List<String> log = [];
  int commandIntegrityCalls = 0;
  int deadLetterCalls = 0;
  bool throwOnMarkProviderCallStarted = false;
  String? lastIntegrityReasonCode;
  String? lastDeadLetterReasonCode;

  @override
  Future<PublishPreparationDto> preparePublish({
    required String tenantId,
    required String attemptId,
    required String idempotencyKey,
    required String payloadHash,
    required Map<String, Object?> canonicalInvoice,
  }) async {
    log.add('preparePublish');
    return const PublishPreparationDto(
      action: PublishPreparationAction.callProvider,
    );
  }

  @override
  Future<void> markProviderCallStarted({
    required String tenantId,
    required String attemptId,
  }) async {
    log.add('markProviderCallStarted');
    if (throwOnMarkProviderCallStarted) {
      throw Exception('DB error marking provider call started');
    }
  }

  @override
  Future<RecordIssuanceResultDto> recordSuccess({
    required String tenantId,
    required String attemptId,
    required IssuanceResultEvidenceDto evidence,
  }) async {
    log.add('recordSuccess');
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
    log.add('recordDefiniteFailure');
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
    log.add('recordUndetermined');
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
    log.add('recordCommandIntegrityFailure');
    commandIntegrityCalls++;
    lastIntegrityReasonCode = reasonCode;
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
    log.add('recordPublishCommandDeadLetter');
    deadLetterCalls++;
    lastDeadLetterReasonCode = reasonCode;
    return const RecordIssuanceResultDto(
      attemptStatus: IssuanceAttemptStatus.failed,
    );
  }
}

void main() {
  group('Publish invoice worker dead letter handling', () {
    const tenantId = 'tenant-1';
    late InternalCommandSerializer serializer;
    late _FakeInternalCommandClient client;
    late _DeadLetterMockProviderPort provider;
    late _DeadLetterMockResultGateway gateway;
    late GetIt container;
    late CommandBus bus;

    setUp(() {
      serializer = InternalCommandSerializer(
        mapper: InternalCommandMapper(
          internalCommandMap: BiMap<String, Type>()
            ..[PublishInvoiceCommand.type] = PublishInvoiceCommand,
        ),
        deserializers: {
          PublishInvoiceCommand.type: PublishInvoiceCommand.fromJson,
        },
      );
      client = _FakeInternalCommandClient(serializer: serializer);
      provider = _DeadLetterMockProviderPort();
      gateway = _DeadLetterMockResultGateway();

      container = GetIt.asNewInstance();
      container
        ..registerSingleton<IMeInvoiceProviderPort>(provider)
        ..registerSingleton<IIssuanceResultGateway>(gateway)
        ..registerFactory(
          () => PublishInvoiceCommandHandler(
            providerPort: container.get<IMeInvoiceProviderPort>(),
            resultGateway: container.get<IIssuanceResultGateway>(),
          ),
        );

      bus = CommandBus(container: container);
      EinvoiceCommandsExecutor.bind(bus);
      bus.register<PublishInvoiceCommand, void>(
        (cmd) => container.get<PublishInvoiceCommandHandler>().handle(cmd),
      );

      final deadLetterHandler = PublishInvoiceCommandDeadLetterHandler(
        resultGateway: gateway,
      );

      bus.register<ProcessInternalCommandsCommand, bool>(
        (cmd) => ProcessInternalCommandsCommandHandler(
          commandClient: client,
          serializer: serializer,
          deadLetterHandlers: {PublishInvoiceCommand.type: deadLetterHandler},
        ).handle(cmd),
      );
    });

    test(
      's2b_command_integrity_dead_letter_01: canonical mismatch reaches dead letter on 3rd attempt and marks integrity failure',
      () async {
        provider.throwOnValidate = true;

        client.enqueue(
          PublishInvoiceCommand(
            id: 'cmd-integrity-1',
            tenantId: tenantId,
            attemptId: 'att-integrity-1',
            payloadHash: 'hash-1',
            idempotencyKey: '88d18970-380a-4138-bbce-e25049ca9e3c',
            canonicalInvoice: {'refId': 'ref-1'},
          ),
        );

        // Attempt 1: fails, disposition RETRY
        final run1 = await bus.execute(
          ProcessInternalCommandsCommand(tenantId: tenantId, batchSize: 1),
        );
        expect(run1, isTrue);
        expect(client.events, ['retry-cmd-integrity-1']);
        expect(gateway.commandIntegrityCalls, 0);
        expect(provider.publishCalls, 0);

        // Attempt 2: fails, disposition RETRY
        final run2 = await bus.execute(
          ProcessInternalCommandsCommand(tenantId: tenantId, batchSize: 1),
        );
        expect(run2, isTrue);
        expect(client.events, [
          'retry-cmd-integrity-1',
          'retry-cmd-integrity-1',
        ]);
        expect(gateway.commandIntegrityCalls, 0);
        expect(provider.publishCalls, 0);

        // Attempt 3: fails, disposition DEAD_LETTER -> records command integrity failure exactly once
        final run3 = await bus.execute(
          ProcessInternalCommandsCommand(tenantId: tenantId, batchSize: 1),
        );
        expect(run3, isTrue);
        expect(client.events, [
          'retry-cmd-integrity-1',
          'retry-cmd-integrity-1',
          'dead_letter-cmd-integrity-1',
        ]);
        expect(gateway.commandIntegrityCalls, 1);
        expect(gateway.lastIntegrityReasonCode, 'COMMAND_INTEGRITY');
        expect(provider.publishCalls, 0);

        // No more work
        final run4 = await bus.execute(
          ProcessInternalCommandsCommand(tenantId: tenantId, batchSize: 1),
        );
        expect(run4, isFalse);
      },
    );

    test(
      'generic worker error on 3rd attempt dispatches dead letter to recordPublishCommandDeadLetter',
      () async {
        gateway.throwOnMarkProviderCallStarted = true;

        client.enqueue(
          PublishInvoiceCommand(
            id: 'cmd-generic-1',
            tenantId: tenantId,
            attemptId: 'att-generic-1',
            payloadHash: 'hash-1',
            idempotencyKey: '88d18970-380a-4138-bbce-e25049ca9e3c',
            canonicalInvoice: {'refId': 'ref-1'},
          ),
        );

        // Set command retry count directly to 2 so next run dead-letters
        client.commands.first.retryCount = 2;

        final ran = await bus.execute(
          ProcessInternalCommandsCommand(tenantId: tenantId, batchSize: 1),
        );
        expect(ran, isTrue);
        expect(client.events, ['dead_letter-cmd-generic-1']);
        expect(gateway.deadLetterCalls, 1);
        expect(
          gateway.lastDeadLetterReasonCode,
          contains('DB error marking provider call started'),
        );
        expect(provider.publishCalls, 0);
      },
    );
  });
}
