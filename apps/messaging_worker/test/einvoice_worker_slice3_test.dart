import 'package:get_it/get_it.dart';
import 'package:messaging_worker/messaging_worker_bootstrap.dart';
import 'package:messaging_worker/tenant_discovery_client.dart';
import 'package:mocktail/mocktail.dart';
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
  final List<(String commandId, String code)> retryOrDeadLetterCalls = [];

  int pendingReconciliationCases = 0;
  bool throwOnClaim = false;

  @override
  Future<int> seedDueReconciliationCommands({
    required String tenantId,
    int limit = 50,
  }) async {
    callLog.add('seedDueReconciliationCommands:$tenantId');
    if (pendingReconciliationCases > 0) {
      final seededCount = pendingReconciliationCases;
      pendingReconciliationCases = 0; // Seeded on first tick, replay won't duplicate
      final token = const Uuid().v4();
      enqueued.add(
        ClaimedInternalCommand(
          commandId: 'cmd-poll-seeded',
          commandType: 'einvoice.poll_issuance_status',
          payload: {
            'tenant_id': tenantId,
            'case_id': 'case-reconcile-1',
            'attempt_id': 'att-reconcile-1',
            'correlation_id': 'corr-1',
            'check_ordinal': 1,
          },
          enqueuedAt: DateTime.utc(2026, 8, 29),
          claimToken: token,
        ),
      );
      return seededCount;
    }
    return 0;
  }

  @override
  Future<List<ClaimedInternalCommand>> claimBatch({
    required String tenantId,
    required int limit,
  }) async {
    callLog.add('claimBatch:$tenantId');
    if (throwOnClaim) {
      throw Exception('DB connection error during claim');
    }
    final batch = List<ClaimedInternalCommand>.from(enqueued);
    enqueued.clear();
    return batch;
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
    callLog.add('retryOrDeadLetter:$commandId:$error');
    retryOrDeadLetterCalls.add((commandId, error));
    return InternalCommandDisposition.retry;
  }

  @override
  Future<void> fail({
    required String tenantId,
    required String commandId,
    required String claimToken,
    required String error,
  }) async {
    callLog.add('fail:$commandId:$error');
  }
}

final class _MockEinvoiceMediator implements IModuleMediator {
  _MockEinvoiceMediator({required this.commandBus});

  final CommandBus commandBus;
  final List<ICommand<dynamic>> executedCommands = [];

  @override
  Future<TResult> executeCommandAsync<TResult>(ICommand<TResult> command) async {
    executedCommands.add(command);
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
    if (_returned) {
      return const [];
    }
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
  group('Einvoice Worker Slice 3 Tests', () {
    const tenantId = 'tenant-slice3-1';
    late InternalCommandSerializer serializer;
    late _TrackingInternalCommandClient fakeInternalCommands;
    late GetIt container;
    late CommandBus commandBus;
    late _MockEinvoiceMediator mediator;
    late MessagingWorkerContext context;

    setUp(() async {
      serializer = createGeneratedEinvoiceInternalCommandSerializer();
      fakeInternalCommands = _TrackingInternalCommandClient(
        serializer: serializer,
      );

      container = GetIt.asNewInstance();
      commandBus = CommandBus(container: container);
      EinvoiceCommandsExecutor.bind(commandBus);

      final processInternalHandler = ProcessInternalCommandsCommandHandler(
        commandClient: fakeInternalCommands,
        serializer: serializer,
      );

      commandBus.register<einvoice.ProcessInternalCommandsCommand, bool>(
        (cmd) => processInternalHandler.handle(cmd),
      );

      mediator = _MockEinvoiceMediator(commandBus: commandBus);

      context = await MessagingWorkerBootstrap.bootstrap(
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

      EinvoiceCommandsExecutor.bind(commandBus);
    });

    test('worker tick calls seedDueReconciliationCommands before claimBatch', () async {
      final loop = MessagingWorkerLoop(
        context: context,
        discoveryClient: _SingleRoundDiscoveryClient([
          PendingMessagingWork(
            tenantId: tenantId,
            moduleSchema: 'einvoice',
            queueType: 'internal_commands',
            pendingCount: 1,
            oldestCreatedAt: DateTime.utc(2026, 8, 29),
          ),
        ]),
      );

      final result = await loop.runOnce();

      expect(result.errorsCount, 0);
      expect(result.queuesSucceeded, 1);
      expect(
        fakeInternalCommands.callLog,
        [
          'seedDueReconciliationCommands:$tenantId',
          'claimBatch:$tenantId',
        ],
      );
    });

    test(
      'existing pending cases without queue rows get seeded on first tick, replay does not duplicate, and never publishes',
      () async {
        fakeInternalCommands.pendingReconciliationCases = 1;

        // Register poll command handler mock
        final pollCalls = <String>[];
        final publishCalls = <String>[];

        // Bind handler for PollIssuanceStatusCommand execution inside EinvoiceCommandsExecutor
        commandBus.register<PollIssuanceStatusCommand, void>((cmd) async {
          pollCalls.add(cmd.commandType);
        });
        commandBus.register<PublishInvoiceCommand, void>((cmd) async {
          publishCalls.add(cmd.commandType);
        });

        // Tick 1: Discovery triggers worker loop
        final loop1 = MessagingWorkerLoop(
          context: context,
          discoveryClient: _SingleRoundDiscoveryClient([
            PendingMessagingWork(
              tenantId: tenantId,
              moduleSchema: 'einvoice',
              queueType: 'internal_commands',
              pendingCount: 1,
              oldestCreatedAt: DateTime.utc(2026, 8, 29),
            ),
          ]),
        );

        final result1 = await loop1.runOnce();
        expect(result1.errorsCount, 0);
        expect(pollCalls, ['einvoice.poll_issuance_status']);
        expect(publishCalls, isEmpty); // Invariant: NEVER publishes during reconciliation poll
        expect(fakeInternalCommands.completedIds, ['cmd-poll-seeded']);

        // Tick 2 (replay): No new pending cases -> no duplicate seeded commands
        final loop2 = MessagingWorkerLoop(
          context: context,
          discoveryClient: _SingleRoundDiscoveryClient([
            PendingMessagingWork(
              tenantId: tenantId,
              moduleSchema: 'einvoice',
              queueType: 'internal_commands',
              pendingCount: 0,
              oldestCreatedAt: DateTime.utc(2026, 8, 29),
            ),
          ]),
        );

        final result2 = await loop2.runOnce();
        expect(result2.errorsCount, 0);
        // No additional poll calls
        expect(pollCalls, ['einvoice.poll_issuance_status']);
        expect(publishCalls, isEmpty);
      },
    );

    test('missing tenant MISA credentials fails one command without crashing tick', () async {
      fakeInternalCommands.enqueued.add(
        ClaimedInternalCommand(
          commandId: 'cmd-poll-no-cred',
          commandType: 'einvoice.poll_issuance_status',
          payload: {
            'tenant_id': tenantId,
            'case_id': 'case-1',
            'attempt_id': 'att-1',
            'correlation_id': 'corr-1',
            'check_ordinal': 1,
          },
          enqueuedAt: DateTime.utc(2026, 8, 29),
          claimToken: 'tok-err',
        ),
      );

      // Register handler that throws PROVIDER_CREDENTIALS_UNAVAILABLE
      commandBus.register<PollIssuanceStatusCommand, void>((cmd) async {
        throw Exception('PROVIDER_CREDENTIALS_UNAVAILABLE');
      });

      final loop = MessagingWorkerLoop(
        context: context,
        discoveryClient: _SingleRoundDiscoveryClient([
          PendingMessagingWork(
            tenantId: tenantId,
            moduleSchema: 'einvoice',
            queueType: 'internal_commands',
            pendingCount: 1,
            oldestCreatedAt: DateTime.utc(2026, 8, 29),
          ),
        ]),
      );

      // Must complete without throwing and crashing tick
      await expectLater(loop.runOnce(), completes);

      expect(fakeInternalCommands.retryOrDeadLetterCalls, hasLength(1));
      expect(
        fakeInternalCommands.retryOrDeadLetterCalls.single.$2,
        contains('PROVIDER_CREDENTIALS_UNAVAILABLE'),
      );
      expect(fakeInternalCommands.completedIds, isEmpty);
    });
  });
}
