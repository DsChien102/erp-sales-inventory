import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';
import 'package:messaging_worker/messaging_worker_bootstrap.dart';
import 'package:messaging_worker/tenant_discovery_client.dart';
import 'package:supabase/supabase.dart';
import 'package:test/test.dart';
import 'package:uuid/uuid.dart';
import 'package:vet45_einvoice_application/application.dart';
import 'package:vet45_einvoice_infrastructure/infrastructure.dart' as einvoice;
import 'package:vet45_einvoice_infrastructure/src/configuration/processing/commands_executor.dart';
import 'package:vet45_einvoice_infrastructure/src/configuration/processing/generated/einvoice_internal_command_registry.g.dart';
import 'package:vet45_einvoice_infrastructure/src/configuration/processing/internal_commands/i_einvoice_internal_command_client.dart';
import 'package:vet45_einvoice_infrastructure/src/configuration/processing/internal_commands/process_internal_commands_command_handler.dart';
import 'package:vet45_shared_application/application.dart';
import 'package:vet45_shared_infrastructure/infrastructure.dart';

final class _FakeSupabaseClient extends Fake implements SupabaseClient {}

final class _TrackingInternalCommandClient implements IEinvoiceInternalCommandClient {
  _TrackingInternalCommandClient({required this.serializer});

  final InternalCommandSerializer serializer;
  final List<String> callLog = <String>[];
  final List<ClaimedInternalCommand> enqueued = <ClaimedInternalCommand>[];
  final List<String> completedIds = <String>[];

  void enqueueFetchOfficial({required String tenantId}) {
    final token = const Uuid().v4();
    enqueued.add(
      ClaimedInternalCommand(
        commandId: 'cmd-official-worker-1',
        commandType: FetchOfficialInvoiceViewCommand.type,
        payload: {
          'tenant_id': tenantId,
          'operation_id': 'op-worker-1',
          'electronic_invoice_id': 'ei-s4-1',
          'attempt_ordinal': 1,
          'correlation_id': 'corr-worker-1',
        },
        enqueuedAt: DateTime.utc(2026, 8, 31, 9),
        claimToken: token,
      ),
    );
  }

  @override
  Future<int> seedDueReconciliationCommands({
    required String tenantId,
    int limit = 50,
  }) async {
    callLog.add('seedDueReconciliationCommands:$tenantId');
    return 0;
  }

  @override
  Future<List<ClaimedInternalCommand>> claimBatch({
    required String tenantId,
    required int limit,
  }) async {
    callLog.add('claimBatch:$tenantId');
    final batch = List<ClaimedInternalCommand>.from(enqueued);
    enqueued.clear();
    return batch.take(limit).toList(growable: false);
  }

  @override
  Future<void> complete({
    required String tenantId,
    required String commandId,
    required String claimToken,
  }) async {
    callLog.add('complete:$commandId');
    completedIds.add(commandId);
  }

  @override
  Future<InternalCommandDisposition> retryOrDeadLetter({
    required String tenantId,
    required String commandId,
    required String claimToken,
    required String error,
  }) async {
    callLog.add('retryOrDeadLetter:$commandId');
    return InternalCommandDisposition.retry;
  }

  @override
  Future<void> fail({
    required String tenantId,
    required String commandId,
    required String claimToken,
    required String error,
  }) async {
    callLog.add('fail:$commandId');
  }

  @override
  Future<void> reschedule({
    required String tenantId,
    required String commandId,
    required String claimToken,
    required Duration delay,
  }) async {
    callLog.add('reschedule:$commandId:${delay.inSeconds}');
  }
}

final class _MockEinvoiceMediator implements IModuleMediator {
  _MockEinvoiceMediator({required this.commandBus});

  final CommandBus commandBus;
  int fetchHandlerCalls = 0;

  @override
  Future<TResult> executeCommandAsync<TResult>(ICommand<TResult> command) async {
    return commandBus.execute(command);
  }

  @override
  Future<TResult> executeQueryAsync<TResult>(IQuery<TResult> query) {
    throw UnimplementedError();
  }
}

final class _SingleRoundDiscoveryClient implements ITenantDiscoveryClient {
  _SingleRoundDiscoveryClient(this.rows);

  final List<PendingMessagingWork> rows;
  var _returned = false;

  @override
  Future<List<PendingMessagingWork>> listTenantsWithPendingMessaging({
    required int limit,
    List<String>? modules,
  }) async {
    if (_returned) return const [];
    _returned = true;
    return rows;
  }
}

const _workerConfig = WorkerEnv(
  supabaseUrl: 'https://example.supabase.co',
  supabaseServiceRoleKey: 'service-role-key',
  tickSecret: 'secret',
  tenantBatchSize: 20,
  moduleBatchSize: 10,
  maxRoundsPerTick: 5,
  concurrency: 1,
  misaAppId: 'test-app-id',
  misaBaseUrl: 'https://testapi.meinvoice.vn/api/integration',
);

void main() {
  group('Einvoice Worker Slice 4', () {
    const tenantId = 'tenant-s4-worker';
    late InternalCommandSerializer serializer;
    late _TrackingInternalCommandClient fakeInternalCommands;
    late GetIt container;
    late CommandBus commandBus;
    late _MockEinvoiceMediator mediator;
    late MessagingWorkerContext workerContext;

    late List<String> fetchCalls;

    setUp(() async {
      fetchCalls = <String>[];
      serializer = createGeneratedEinvoiceInternalCommandSerializer();
      fakeInternalCommands = _TrackingInternalCommandClient(
        serializer: serializer,
      );
      fakeInternalCommands.enqueueFetchOfficial(tenantId: tenantId);

      container = GetIt.asNewInstance();
      commandBus = CommandBus(container: container);
      EinvoiceCommandsExecutor.bind(commandBus);

      commandBus.register<FetchOfficialInvoiceViewCommand, void>((cmd) async {
        fetchCalls.add(cmd.operationId);
      });

      final processInternalHandler = ProcessInternalCommandsCommandHandler(
        commandClient: fakeInternalCommands,
        serializer: serializer,
      );

      commandBus.register<einvoice.ProcessInternalCommandsCommand, bool>(
        (cmd) => processInternalHandler.handle(cmd),
      );

      mediator = _MockEinvoiceMediator(commandBus: commandBus);

      workerContext = await MessagingWorkerBootstrap.bootstrap(
        config: _workerConfig,
        supabaseClient: _FakeSupabaseClient(),
        modules: [
          MessagingModuleBinding(
            moduleSchema: 'einvoice',
            mediator: mediator,
            commands: const EinvoiceMessagingCommandFactory(),
          ),
        ],
      );

      // Bootstrap rebinds the executor to the runtime bus; restore test bus wiring.
      EinvoiceCommandsExecutor.bind(commandBus);
      commandBus.register<FetchOfficialInvoiceViewCommand, void>((cmd) async {
        fetchCalls.add(cmd.operationId);
      });
    });

    test('worker tick claims and completes fetch_official_view command', () async {
      final loop = MessagingWorkerLoop(
        context: workerContext,
        discoveryClient: _SingleRoundDiscoveryClient([
          PendingMessagingWork(
            tenantId: tenantId,
            moduleSchema: 'einvoice',
            queueType: 'internal_commands',
            pendingCount: 1,
            oldestCreatedAt: DateTime.utc(2026, 8, 31, 9),
          ),
        ]),
      );

      final result = await loop.runOnce();

      expect(result.errorsCount, 0);
      expect(result.queuesSucceeded, 1);
      expect(fakeInternalCommands.completedIds, ['cmd-official-worker-1']);
      expect(
        fakeInternalCommands.callLog,
        contains('seedDueReconciliationCommands:$tenantId'),
      );
      expect(fakeInternalCommands.callLog, contains('claimBatch:$tenantId'));
    });

    test('worker tick does not invoke observation seeder', () async {
      final loop = MessagingWorkerLoop(
        context: workerContext,
        discoveryClient: _SingleRoundDiscoveryClient([
          PendingMessagingWork(
            tenantId: tenantId,
            moduleSchema: 'einvoice',
            queueType: 'internal_commands',
            pendingCount: 0,
            oldestCreatedAt: DateTime.utc(2026, 8, 31, 9),
          ),
        ]),
      );

      await loop.runOnce();

      expect(
        fakeInternalCommands.callLog.any(
          (entry) => entry.contains('seedDueProviderObservation'),
        ),
        isFalse,
      );
    });
  });
}
