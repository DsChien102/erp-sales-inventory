import 'package:mocktail/mocktail.dart';
import 'package:messaging_worker/messaging_worker_bootstrap.dart';
import 'package:messaging_worker/tenant_discovery_client.dart';
import 'package:supabase/supabase.dart';
import 'package:test/test.dart';
import 'package:vet45_adapters/vet45_adapters.dart';
import 'package:vet45_shared_infrastructure/infrastructure.dart';

class _FakeSupabaseClient extends Fake implements SupabaseClient {}

void main() {
  group('MessagingWorkerBootstrap', () {
    test('wires shared integration bus with empty module registry', () {
      final sharedBus = InMemoryEventBusClient();
      final context = MessagingWorkerBootstrap.bootstrap(
        config: const WorkerEnv(
          supabaseUrl: 'https://example.supabase.co',
          supabaseServiceRoleKey: 'service-role-key',
          tickSecret: 'secret',
          tenantBatchSize: 20,
          moduleBatchSize: 10,
          maxRoundsPerTick: 5,
        ),
        supabaseClient: _FakeSupabaseClient(),
        integrationEventBus: sharedBus,
      );

      expect(identical(context.integrationEventBus, sharedBus), isTrue);
      expect(context.registry.modules.map((module) => module.name).toList(), isEmpty);
    });
  });

  group('MessagingWorkerLoop', () {
    test('returns no-op metrics when discovery finds no tenants', () async {
      final context = MessagingWorkerBootstrap.bootstrap(
        config: const WorkerEnv(
          supabaseUrl: 'https://example.supabase.co',
          supabaseServiceRoleKey: 'service-role-key',
          tickSecret: 'secret',
          tenantBatchSize: 20,
          moduleBatchSize: 10,
          maxRoundsPerTick: 5,
        ),
        supabaseClient: _FakeSupabaseClient(),
      );
      final loop = MessagingWorkerLoop(
        context: context,
        discoveryClient: _EmptyDiscoveryClient(),
      );

      final result = await loop.runOnce();

      expect(result.tenantsProcessed, 0);
      expect(result.rounds, 0);
      expect(result.errorsCount, 0);
      expect(result.hadBacklog, isFalse);
      expect(result.durationMs, greaterThanOrEqualTo(0));
    });

    test('processes modules in registry order per tenant', () async {
      final callOrder = <String>[];
      final context = MessagingWorkerBootstrap.bootstrap(
        config: const WorkerEnv(
          supabaseUrl: 'https://example.supabase.co',
          supabaseServiceRoleKey: 'service-role-key',
          tickSecret: 'secret',
          tenantBatchSize: 20,
          moduleBatchSize: 10,
          maxRoundsPerTick: 5,
        ),
        supabaseClient: _FakeSupabaseClient(),
        integrationEventBus: InMemoryEventBusClient(),
      );
      final loop = MessagingWorkerLoop(
        context: MessagingWorkerContext(
          supabaseClient: context.supabaseClient,
          integrationEventBus: context.integrationEventBus,
          registry: MessagingModuleRegistry([
            _RecordingModule('sales', callOrder),
            _RecordingModule('catalog', callOrder),
            _RecordingModule('partner', callOrder),
          ]),
          config: context.config,
        ),
        discoveryClient: _SingleRoundDiscoveryClient(
          PendingTenant(
            tenantId: 'tenant-1',
            oldestCreatedAt: DateTime.utc(2026, 1, 1),
          ),
        ),
      );

      await loop.runOnce();

      expect(callOrder, ['sales', 'catalog', 'partner']);
    });

    test('stops after maxRoundsPerTick even if backlog remains', () async {
      var discoveryCalls = 0;
      final context = MessagingWorkerBootstrap.bootstrap(
        config: const WorkerEnv(
          supabaseUrl: 'https://example.supabase.co',
          supabaseServiceRoleKey: 'service-role-key',
          tickSecret: 'secret',
          tenantBatchSize: 20,
          moduleBatchSize: 10,
          maxRoundsPerTick: 2,
        ),
        supabaseClient: _FakeSupabaseClient(),
      );
      final loop = MessagingWorkerLoop(
        context: MessagingWorkerContext(
          supabaseClient: context.supabaseClient,
          integrationEventBus: context.integrationEventBus,
          registry: MessagingModuleRegistry([
            _RecordingModule('sales', <String>[]),
            _RecordingModule('catalog', <String>[]),
            _RecordingModule('partner', <String>[]),
          ]),
          config: context.config,
        ),
        discoveryClient: _AlwaysHasBacklogDiscoveryClient(
          onCall: () => discoveryCalls++,
        ),
      );

      final result = await loop.runOnce();

      expect(result.rounds, 2);
      expect(discoveryCalls, 2);
      expect(result.hadBacklog, isTrue);
    });
  });
}

final class _RecordingModule implements IMessagingModule {
  _RecordingModule(this.name, this.callOrder);

  @override
  final String name;
  final List<String> callOrder;

  @override
  Future<MessagingProcessResult> processMessagingOnce({
    required String tenantId,
    int batchSize = 10,
  }) async {
    callOrder.add(name);
    return MessagingProcessResult.empty;
  }
}

final class _EmptyDiscoveryClient implements ITenantDiscoveryClient {
  @override
  Future<List<PendingTenant>> listTenantsWithPendingMessaging({
    required int limit,
  }) async {
    return const [];
  }
}

final class _SingleRoundDiscoveryClient implements ITenantDiscoveryClient {
  _SingleRoundDiscoveryClient(this.tenant);

  final PendingTenant tenant;
  var _returned = false;

  @override
  Future<List<PendingTenant>> listTenantsWithPendingMessaging({
    required int limit,
  }) async {
    if (_returned) {
      return const [];
    }
    _returned = true;
    return [tenant];
  }
}

final class _AlwaysHasBacklogDiscoveryClient implements ITenantDiscoveryClient {
  _AlwaysHasBacklogDiscoveryClient({required this.onCall});

  final void Function() onCall;

  @override
  Future<List<PendingTenant>> listTenantsWithPendingMessaging({
    required int limit,
  }) async {
    onCall();
    return [
      PendingTenant(
        tenantId: 'tenant-1',
        oldestCreatedAt: DateTime.utc(2026, 1, 1),
      ),
    ];
  }
}
