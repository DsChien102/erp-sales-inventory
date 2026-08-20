import 'messaging_worker_bootstrap.dart';
import 'messaging_worker_tick_result.dart';
import 'tenant_discovery_client.dart';
import 'work_concurrency_pool.dart';

export 'messaging_worker_bootstrap.dart' show MessagingWorkerBootstrap, MessagingWorkerContext;

/// Processes pending messaging backlog for discovered tenants.
final class MessagingWorkerLoop {
  MessagingWorkerLoop({
    required MessagingWorkerContext context,
    ITenantDiscoveryClient? discoveryClient,
    void Function(String message)? log,
  }) : _bindings = indexMessagingModuleBindings(context.modules),
       _boundModuleSchemas = context.boundModuleSchemas,
       _config = context.config,
       _discoveryClient = discoveryClient ?? SupabaseTenantDiscoveryClient(context.supabaseClient),
       _pool = WorkConcurrencyPool(context.config.concurrency),
       _log = log ?? _defaultLog;

  final Map<String, MessagingModuleBinding> _bindings;
  final List<String> _boundModuleSchemas;
  final WorkerEnv _config;
  final ITenantDiscoveryClient _discoveryClient;
  final WorkConcurrencyPool _pool;
  final void Function(String message) _log;

  static void _defaultLog(String message) {
    // ignore: avoid_print
    print(message);
  }

  Future<MessagingWorkerTickResult> runOnce() async {
    final stopwatch = Stopwatch()..start();
    var rounds = 0;
    var errorsCount = 0;
    var hadBacklog = false;
    final processedTenants = <String>{};

    for (var round = 0; round < _config.maxRoundsPerTick; round++) {
      final work = await _discoveryClient.listTenantsWithPendingMessaging(
        limit: _config.tenantBatchSize,
        modules: _boundModuleSchemas,
      );
      if (work.isEmpty) {
        break;
      }

      hadBacklog = true;
      rounds++;

      final grouped = _groupByPartitionKey(work);
      final roundErrors = await Future.wait(
        grouped.entries.map(
          (entry) => _pool.run(
            () => _processPartitionGroup(
              entry.key,
              entry.value,
              processedTenants,
            ),
          ),
        ),
      );
      errorsCount += roundErrors.fold<int>(0, (sum, count) => sum + count);
    }

    return MessagingWorkerTickResult(
      tenantsProcessed: processedTenants.length,
      rounds: rounds,
      durationMs: stopwatch.elapsedMilliseconds,
      errorsCount: errorsCount,
      hadBacklog: hadBacklog,
    );
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

  Future<int> _processPartitionGroup(
    String partitionKey,
    List<PendingMessagingWork> items,
    Set<String> processedTenants,
  ) async {
    var errorsCount = 0;

    for (final work in items) {
      processedTenants.add(work.tenantId);

      final binding = _bindings[work.moduleSchema];
      if (binding == null) {
        _log(
          'tick skip tenant=${work.tenantId} module=${work.moduleSchema} '
          'queue=${work.queueType} pending=${work.pendingCount}',
        );
        continue;
      }

      final command = binding.commands.commandFor(
        queueType: work.queueType,
        tenantId: work.tenantId,
        batchSize: _config.moduleBatchSize,
      );
      if (command == null) {
        errorsCount++;
        _log(
          'tick unknown queue tenant=${work.tenantId} module=${work.moduleSchema} '
          'queue=${work.queueType} pending=${work.pendingCount}',
        );
        continue;
      }

      try {
        final hadWork = await binding.mediator.executeCommandAsync<bool>(command);
        _log(
          'tick queue done tenant=${work.tenantId} module=${work.moduleSchema} '
          'queue=${work.queueType} pending=${work.pendingCount} hadWork=$hadWork '
          'partition=$partitionKey',
        );
      } catch (error, stackTrace) {
        errorsCount++;
        _log(
          'tick error tenant=${work.tenantId} module=${work.moduleSchema} '
          'queue=${work.queueType} error=$error stack=$stackTrace',
        );
      }
    }

    return errorsCount;
  }
}
