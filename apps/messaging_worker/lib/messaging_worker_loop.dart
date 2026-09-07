import 'package:vet45_shared_infrastructure/infrastructure.dart';

import 'messaging_worker_bootstrap.dart';
import 'tenant_discovery_client.dart';
import 'work_concurrency_pool.dart';

export 'messaging_worker_bootstrap.dart' show MessagingWorkerBootstrap, MessagingWorkerContext;

/// Processes pending messaging backlog for discovered tenants.
final class MessagingWorkerLoop {
  MessagingWorkerLoop({
    required MessagingWorkerContext context,
    ITenantDiscoveryClient? discoveryClient,
    ILogger? logger,
  }) : _bindings = indexMessagingModuleBindings(context.modules),
       _boundModuleSchemas = context.boundModuleSchemas,
       _config = context.config,
       _discoveryClient = discoveryClient ?? SupabaseTenantDiscoveryClient(context.supabaseClient),
       _pool = WorkConcurrencyPool(context.config.concurrency),
       _log = WorkerStructuredLog(logger ?? createWorkerLogger('loop'));

  final Map<String, MessagingModuleBinding> _bindings;
  final List<String> _boundModuleSchemas;
  final WorkerEnv _config;
  final ITenantDiscoveryClient _discoveryClient;
  final WorkConcurrencyPool _pool;
  final WorkerStructuredLog _log;

  var _tickSequence = 0;

  Future<MessagingWorkerTickResult> runOnce() async {
    final tickId = createWorkerTickId(++_tickSequence);
    final stopwatch = Stopwatch()..start();
    var rounds = 0;
    var errorsCount = 0;
    var hadBacklog = false;
    var workDiscovered = 0;
    var partitions = 0;
    var queuesSucceeded = 0;
    var queuesSkipped = 0;
    var queuesUnknown = 0;
    var hadWorkTrue = 0;
    var discoveryMs = 0;
    var processMs = 0;
    var maxPartitionDurationMs = 0;
    final processedTenants = <String>{};
    final byModule = <String, int>{};
    final byQueue = <String, int>{};

    _log.fine('tick_start', {
      'tickId': tickId,
      'boundModules': _boundModuleSchemas,
      'concurrency': _config.concurrency,
      'tenantBatchSize': _config.tenantBatchSize,
      'moduleBatchSize': _config.moduleBatchSize,
      'maxRoundsPerTick': _config.maxRoundsPerTick,
    });

    for (var round = 0; round < _config.maxRoundsPerTick; round++) {
      final discoveryWatch = Stopwatch()..start();
      final work = await _discoveryClient.listTenantsWithPendingMessaging(
        limit: _config.tenantBatchSize,
        modules: _boundModuleSchemas,
      );
      discoveryMs += discoveryWatch.elapsedMilliseconds;

      if (work.isEmpty) {
        break;
      }

      hadBacklog = true;
      rounds++;
      workDiscovered += work.length;

      final grouped = _groupByPartitionKey(work);
      partitions += grouped.length;

      _log.fine('tick_round', {
        'tickId': tickId,
        'round': round,
        'workDiscovered': work.length,
        'partitions': grouped.length,
      });

      final processWatch = Stopwatch()..start();
      final outcomes = await Future.wait(
        grouped.entries.map(
          (entry) => _pool.run(
            () => _processPartitionGroup(
              tickId: tickId,
              partitionKey: entry.key,
              items: entry.value,
              processedTenants: processedTenants,
            ),
          ),
        ),
      );
      processMs += processWatch.elapsedMilliseconds;

      for (final outcome in outcomes) {
        errorsCount += outcome.errorsCount;
        queuesSucceeded += outcome.queuesSucceeded;
        queuesSkipped += outcome.queuesSkipped;
        queuesUnknown += outcome.queuesUnknown;
        hadWorkTrue += outcome.hadWorkTrue;
        if (outcome.durationMs > maxPartitionDurationMs) {
          maxPartitionDurationMs = outcome.durationMs;
        }
        _mergeCounts(byModule, outcome.byModule);
        _mergeCounts(byQueue, outcome.byQueue);
      }
    }

    final result = MessagingWorkerTickResult(
      tickId: tickId,
      tenantsProcessed: processedTenants.length,
      rounds: rounds,
      durationMs: stopwatch.elapsedMilliseconds,
      errorsCount: errorsCount,
      hadBacklog: hadBacklog,
      workDiscovered: workDiscovered,
      partitions: partitions,
      queuesSucceeded: queuesSucceeded,
      queuesSkipped: queuesSkipped,
      queuesUnknown: queuesUnknown,
      hadWorkTrue: hadWorkTrue,
      byModule: Map<String, int>.unmodifiable(byModule),
      byQueue: Map<String, int>.unmodifiable(byQueue),
      discoveryMs: discoveryMs,
      processMs: processMs,
      maxPartitionDurationMs: maxPartitionDurationMs,
    );

    _log.info('tick_end', {
      'tickId': result.tickId,
      'tenantsProcessed': result.tenantsProcessed,
      'rounds': result.rounds,
      'durationMs': result.durationMs,
      'errorsCount': result.errorsCount,
      'hadBacklog': result.hadBacklog,
      'workDiscovered': result.workDiscovered,
      'partitions': result.partitions,
      'queuesSucceeded': result.queuesSucceeded,
      'queuesSkipped': result.queuesSkipped,
      'queuesUnknown': result.queuesUnknown,
      'hadWorkTrue': result.hadWorkTrue,
      'byModule': result.byModule,
      'byQueue': result.byQueue,
      'discoveryMs': result.discoveryMs,
      'processMs': result.processMs,
      'maxPartitionDurationMs': result.maxPartitionDurationMs,
    });
    return result;
  }

  Map<String, List<PendingMessagingWork>> _groupByPartitionKey(
    List<PendingMessagingWork> work,
  ) {
    final grouped = <String, List<PendingMessagingWork>>{};
    for (final item in work) {
      grouped.putIfAbsent(_partitionKey(item), () => []).add(item);
    }
    return grouped;
  }

  String _partitionKey(PendingMessagingWork work) {
    return '${work.tenantId}|${work.moduleSchema}|${work.queueType}';
  }

  Future<_PartitionOutcome> _processPartitionGroup({
    required String tickId,
    required String partitionKey,
    required List<PendingMessagingWork> items,
    required Set<String> processedTenants,
  }) async {
    final stopwatch = Stopwatch()..start();
    var errorsCount = 0;
    var queuesSucceeded = 0;
    var queuesSkipped = 0;
    var queuesUnknown = 0;
    var hadWorkTrue = 0;
    final byModule = <String, int>{};
    final byQueue = <String, int>{};

    for (final work in items) {
      processedTenants.add(work.tenantId);

      final binding = _bindings[work.moduleSchema];
      if (binding == null) {
        queuesSkipped++;
        _log.info('queue_skip', {
          'tickId': tickId,
          'tenantId': work.tenantId,
          'module': work.moduleSchema,
          'queue': work.queueType,
          'pending': work.pendingCount,
          'partition': partitionKey,
        });
        continue;
      }

      final command = binding.commands.commandFor(
        queueType: work.queueType,
        tenantId: work.tenantId,
        batchSize: _config.moduleBatchSize,
      );
      if (command == null) {
        errorsCount++;
        queuesUnknown++;
        _log.warning('queue_unknown', {
          'tickId': tickId,
          'tenantId': work.tenantId,
          'module': work.moduleSchema,
          'queue': work.queueType,
          'pending': work.pendingCount,
          'partition': partitionKey,
        });
        continue;
      }

      final queueWatch = Stopwatch()..start();
      try {
        final hadWork = await binding.mediator.executeCommandAsync<bool>(command);
        queuesSucceeded++;
        if (hadWork) {
          hadWorkTrue++;
        }
        byModule[work.moduleSchema] = (byModule[work.moduleSchema] ?? 0) + 1;
        final queueKey = '${work.moduleSchema}.${work.queueType}';
        byQueue[queueKey] = (byQueue[queueKey] ?? 0) + 1;

        _log.fine('queue_done', {
          'tickId': tickId,
          'tenantId': work.tenantId,
          'module': work.moduleSchema,
          'queue': work.queueType,
          'pending': work.pendingCount,
          'hadWork': hadWork,
          'durationMs': queueWatch.elapsedMilliseconds,
          'partition': partitionKey,
        });
      } catch (error, stackTrace) {
        errorsCount++;
        _log.severe(
          'queue_error',
          {
            'tickId': tickId,
            'tenantId': work.tenantId,
            'module': work.moduleSchema,
            'queue': work.queueType,
            'pending': work.pendingCount,
            'durationMs': queueWatch.elapsedMilliseconds,
            'partition': partitionKey,
            'error': error.toString(),
          },
          error,
          stackTrace,
        );
      }
    }

    return _PartitionOutcome(
      errorsCount: errorsCount,
      queuesSucceeded: queuesSucceeded,
      queuesSkipped: queuesSkipped,
      queuesUnknown: queuesUnknown,
      hadWorkTrue: hadWorkTrue,
      byModule: byModule,
      byQueue: byQueue,
      durationMs: stopwatch.elapsedMilliseconds,
    );
  }

  static void _mergeCounts(Map<String, int> target, Map<String, int> source) {
    for (final entry in source.entries) {
      target[entry.key] = (target[entry.key] ?? 0) + entry.value;
    }
  }
}

final class _PartitionOutcome {
  const _PartitionOutcome({
    required this.errorsCount,
    required this.queuesSucceeded,
    required this.queuesSkipped,
    required this.queuesUnknown,
    required this.hadWorkTrue,
    required this.byModule,
    required this.byQueue,
    required this.durationMs,
  });

  final int errorsCount;
  final int queuesSucceeded;
  final int queuesSkipped;
  final int queuesUnknown;
  final int hadWorkTrue;
  final Map<String, int> byModule;
  final Map<String, int> byQueue;
  final int durationMs;
}
