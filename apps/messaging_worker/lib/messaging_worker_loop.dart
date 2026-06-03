import 'package:vet45_adapters/vet45_adapters.dart';
// import 'package:vet45_shared_infrastructure/infrastructure.dart';

import 'messaging_worker_bootstrap.dart';
import 'messaging_worker_tick_result.dart';
import 'tenant_discovery_client.dart';

export 'messaging_worker_bootstrap.dart' show MessagingWorkerBootstrap, MessagingWorkerContext;

/// Processes pending messaging backlog for discovered tenants.
final class MessagingWorkerLoop {
  MessagingWorkerLoop({
    required MessagingWorkerContext context,
    ITenantDiscoveryClient? discoveryClient,
    void Function(String message)? log,
  }) : _registry = context.registry,
       _config = context.config,
       _discoveryClient =
           discoveryClient ?? SupabaseTenantDiscoveryClient(context.supabaseClient),
       _log = log ?? _defaultLog;

  final MessagingModuleRegistry _registry;
  final WorkerEnv _config;
  final ITenantDiscoveryClient _discoveryClient;
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
      final tenants = await _discoveryClient.listTenantsWithPendingMessaging(
        limit: _config.tenantBatchSize,
      );
      if (tenants.isEmpty) {
        break;
      }

      hadBacklog = true;
      rounds++;

      for (final tenant in tenants) {
        processedTenants.add(tenant.tenantId);

        for (final module in _registry.modules) {
          try {
            await module.processMessagingOnce(
              tenantId: tenant.tenantId,
              batchSize: _config.moduleBatchSize,
            );
          } catch (error, stackTrace) {
            errorsCount++;
            _log(
              'tick error tenant=${tenant.tenantId} module=${module.name} '
              'error=$error stack=$stackTrace',
            );
          }
        }
      }
    }

    return MessagingWorkerTickResult(
      tenantsProcessed: processedTenants.length,
      rounds: rounds,
      durationMs: stopwatch.elapsedMilliseconds,
      errorsCount: errorsCount,
      hadBacklog: hadBacklog,
    );
  }
}
