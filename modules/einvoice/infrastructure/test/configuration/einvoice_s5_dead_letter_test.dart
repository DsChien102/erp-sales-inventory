import 'package:get_it/get_it.dart';
import 'package:quiver/collection.dart';
import 'package:test/test.dart';
import 'package:uuid/uuid.dart';
import 'package:vet45_einvoice_application/application.dart';
import 'package:vet45_einvoice_infrastructure/src/configuration/processing/commands_executor.dart';
import 'package:vet45_einvoice_infrastructure/src/configuration/processing/internal_commands/delivery_command_dead_letter_handler.dart';
import 'package:vet45_einvoice_infrastructure/src/configuration/processing/internal_commands/einvoice_internal_command_attempt_policy.dart';
import 'package:vet45_einvoice_infrastructure/src/configuration/processing/internal_commands/i_einvoice_internal_command_client.dart';
import 'package:vet45_einvoice_infrastructure/src/configuration/processing/internal_commands/process_internal_commands_command.dart';
import 'package:vet45_einvoice_infrastructure/src/configuration/processing/internal_commands/process_internal_commands_command_handler.dart';
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
  }) async => 0;

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
    }
    events.add('retry-${command.id}');
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
    if (command == null) return;
    command.failedAt = DateTime.now().toUtc();
    command.lastError = error;
    command.claimToken = null;
    events.add('fail-${command.id}');
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

final class _TrackingDeliveryCommandGateway implements IDeliveryCommandGateway {
  final List<Map<String, String>> deadLetters = [];

  @override
  Future<void> recordCommandDeadLetter({
    required String tenantId,
    required String deliveryId,
    required String attemptId,
    required String safeFailureCode,
  }) async {
    deadLetters.add({
      'tenantId': tenantId,
      'deliveryId': deliveryId,
      'attemptId': attemptId,
      'safeFailureCode': safeFailureCode,
    });
  }

  @override
  Future<AutoDeliveryResultDto> startAuto(AutoDeliveryStartRequest request) =>
      throw UnimplementedError();

  @override
  Future<SendInvoiceResultDto> startManual(
    ManualDeliveryStartRequest request,
  ) => throw UnimplementedError();

  @override
  Future<DeliveryAttemptContextDto?> loadAttemptContext({
    required String tenantId,
    required String deliveryId,
    required String attemptId,
  }) => throw UnimplementedError();

  @override
  Future<PrepareDeliveryProviderCallResult> prepareProviderCall({
    required String tenantId,
    required String deliveryId,
    required String attemptId,
    required int expectedDeliveryVersion,
    required int expectedAttemptVersion,
    required String requestReference,
  }) => throw UnimplementedError();

  @override
  Future<RecordDeliveryResultDto> recordResult(DeliveryResultRecord record) =>
      throw UnimplementedError();
}

final class _AlwaysFailingSendHandler
    implements ICommandHandler<SendInvoiceEmailCommand, void> {
  @override
  Future<void> handle(SendInvoiceEmailCommand command) async {
    throw Exception('simulated send failure');
  }
}

void main() {
  group('Einvoice S5 delivery dead-letter', () {
    test('attempt policy is max-three for send_invoice_email', () {
      expect(maxAttemptsForCommandType(SendInvoiceEmailCommand.type), 3);
    });

    test(
      'DeliveryCommandDeadLetterHandler records WORKER_EXHAUSTED_BEFORE_DISPATCH',
      () async {
        final gateway = _TrackingDeliveryCommandGateway();
        final handler = DeliveryCommandDeadLetterHandler(
          commandGateway: gateway,
        );

        await handler.handleDeadLetter(
          tenantId: 'tenant-1',
          command: ClaimedInternalCommand(
            commandId: 'cmd-1',
            commandType: SendInvoiceEmailCommand.type,
            payload: {
              'delivery_id': 'del-queued-1',
              'attempt_id': 'att-queued-1',
            },
            enqueuedAt: DateTime.utc(2026, 9, 2),
            claimToken: 'tok-1',
            retryCount: 3,
          ),
          error: Exception('exhausted'),
        );

        expect(gateway.deadLetters, hasLength(1));
        expect(gateway.deadLetters.single['deliveryId'], 'del-queued-1');
        expect(gateway.deadLetters.single['attemptId'], 'att-queued-1');
        expect(
          gateway.deadLetters.single['safeFailureCode'],
          'WORKER_EXHAUSTED_BEFORE_DISPATCH',
        );
      },
    );

    test(
      'legacy camelCase dead-letter identifies attempt after deserialize error',
      () async {
        final gateway = _TrackingDeliveryCommandGateway();
        await DeliveryCommandDeadLetterHandler(
          commandGateway: gateway,
        ).handleDeadLetter(
          tenantId: 'tenant-1',
          command: ClaimedInternalCommand(
            commandId: 'cmd-1',
            commandType: SendInvoiceEmailCommand.type,
            payload: {
              'tenantId': 'tenant-1',
              'deliveryId': 'del-1',
              'attemptId': 'att-1',
            },
            enqueuedAt: DateTime.utc(2026),
            claimToken: 'tok',
            retryCount: 3,
          ),
          error: const FormatException('deserialization'),
        );
        expect(gateway.deadLetters.single['attemptId'], 'att-1');
      },
    );

    test(
      'max-three exhaustion invokes delivery dead-letter once (SQL classifies QUEUED vs SUBMITTED)',
      () async {
        final serializer = InternalCommandSerializer(
          mapper: InternalCommandMapper(
            internalCommandMap: BiMap<String, Type>()
              ..[SendInvoiceEmailCommand.type] = SendInvoiceEmailCommand,
          ),
          deserializers: {
            SendInvoiceEmailCommand.type: SendInvoiceEmailCommand.fromJson,
          },
        );
        final client = _FakeInternalCommandClient(serializer: serializer);
        final gateway = _TrackingDeliveryCommandGateway();
        final container = GetIt.asNewInstance();
        container.registerFactory(() => _AlwaysFailingSendHandler());

        final bus = CommandBus(container: container);
        EinvoiceCommandsExecutor.bind(bus);
        bus.register<SendInvoiceEmailCommand, void>(
          (cmd) => container.get<_AlwaysFailingSendHandler>().handle(cmd),
        );

        final deadLetterHandler = DeliveryCommandDeadLetterHandler(
          commandGateway: gateway,
        );
        bus.register<ProcessInternalCommandsCommand, bool>(
          (cmd) => ProcessInternalCommandsCommandHandler(
            commandClient: client,
            serializer: serializer,
            deadLetterHandlers: {
              SendInvoiceEmailCommand.type: deadLetterHandler,
            },
          ).handle(cmd),
        );

        client.enqueue(
          SendInvoiceEmailCommand(
            id: 'cmd-send-exhaust-1',
            tenantId: 'tenant-1',
            deliveryId: 'del-1',
            attemptId: 'att-1',
          ),
        );

        // Attempt policy forces fail+dead-letter at attempt 3 (retryCount 0,1,2).
        for (var i = 0; i < 3; i++) {
          await bus.execute(
            ProcessInternalCommandsCommand(tenantId: 'tenant-1', batchSize: 1),
          );
        }

        expect(gateway.deadLetters, hasLength(1));
        expect(
          gateway.deadLetters.single['safeFailureCode'],
          'WORKER_EXHAUSTED_BEFORE_DISPATCH',
        );
        // Handler always passes the allow-listed queued code; RPC status branch
        // classifies QUEUED→FAILED vs SUBMITTED→UNKNOWN+PENDING reconcile.
        expect(client.events.where((e) => e.startsWith('fail-')), hasLength(1));
      },
    );
  });
}
