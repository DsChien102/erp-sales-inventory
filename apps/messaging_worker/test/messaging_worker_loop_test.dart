import 'dart:async';

import 'package:mocktail/mocktail.dart';
import 'package:messaging_worker/iam_messaging_command_factory.dart';
import 'package:messaging_worker/messaging_module_binding.dart';
import 'package:messaging_worker/messaging_worker_bootstrap.dart';
import 'package:messaging_worker/tenant_discovery_client.dart';
import 'package:supabase/supabase.dart';
import 'package:test/test.dart';
import 'package:vet45_iam_infrastructure/infrastructure.dart';
import 'package:vet45_shared_application/application.dart';
import 'package:vet45_shared_infrastructure/infrastructure.dart';

class _FakeSupabaseClient extends Fake implements SupabaseClient {}

List<MessagingModuleBinding> _iamBinding(IModuleMediator mediator) {
  return [
    MessagingModuleBinding(
      moduleSchema: 'iam',
      mediator: mediator,
      commands: const IamMessagingCommandFactory(),
    ),
  ];
}

const _baseConfig = WorkerEnv(
  supabaseUrl: 'https://example.supabase.co',
  supabaseServiceRoleKey: 'service-role-key',
  tickSecret: 'secret',
  tenantBatchSize: 20,
  moduleBatchSize: 10,
  maxRoundsPerTick: 5,
  concurrency: 4,
);

void main() {
  group('MessagingWorkerBootstrap', () {
    test('wires shared integration bus with IAM module binding', () async {
      final sharedBus = InMemoryEventBusClient();
      final mediator = _RecordingMediator();
      final context = await MessagingWorkerBootstrap.bootstrap(
        config: _baseConfig,
        supabaseClient: _FakeSupabaseClient(),
        integrationEventBus: sharedBus,
        modules: _iamBinding(mediator),
      );

      expect(identical(context.integrationEventBus, sharedBus), isTrue);
      expect(context.modules, hasLength(1));
      expect(context.modules.single.moduleSchema, 'iam');
      expect(identical(context.modules.single.mediator, mediator), isTrue);
      expect(context.boundModuleSchemas, ['iam']);
    });
  });

  group('MessagingWorkerLoop', () {
    test('returns no-op metrics when discovery finds no work', () async {
      final context = await MessagingWorkerBootstrap.bootstrap(
        config: _baseConfig,
        supabaseClient: _FakeSupabaseClient(),
        modules: _iamBinding(_RecordingMediator()),
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

    test('dispatches queue-specific IAM commands in discovery order', () async {
      final mediator = _RecordingMediator();
      final context = await MessagingWorkerBootstrap.bootstrap(
        config: _baseConfig,
        supabaseClient: _FakeSupabaseClient(),
        integrationEventBus: InMemoryEventBusClient(),
        modules: _iamBinding(mediator),
      );
      final loop = MessagingWorkerLoop(
        context: context,
        discoveryClient: _SingleRoundDiscoveryClient([
          PendingMessagingWork(
            tenantId: 'tenant-1',
            moduleSchema: 'iam',
            queueType: 'outbox',
            pendingCount: 2,
            oldestCreatedAt: DateTime.utc(2026, 1, 1),
          ),
          PendingMessagingWork(
            tenantId: 'tenant-1',
            moduleSchema: 'iam',
            queueType: 'inbox',
            pendingCount: 1,
            oldestCreatedAt: DateTime.utc(2026, 1, 1, 0, 1),
          ),
          PendingMessagingWork(
            tenantId: 'tenant-2',
            moduleSchema: 'iam',
            queueType: 'internal_commands',
            pendingCount: 3,
            oldestCreatedAt: DateTime.utc(2026, 1, 1, 0, 2),
          ),
        ]),
      );

      final result = await loop.runOnce();

      expect(mediator.commands, hasLength(3));
      expect(mediator.commands[0], isA<ProcessOutboxCommand>());
      expect((mediator.commands[0] as ProcessOutboxCommand).tenantId, 'tenant-1');
      expect(mediator.commands[1], isA<ProcessInboxCommand>());
      expect((mediator.commands[1] as ProcessInboxCommand).tenantId, 'tenant-1');
      expect(mediator.commands[2], isA<ProcessInternalCommandsCommand>());
      expect(
        (mediator.commands[2] as ProcessInternalCommandsCommand).tenantId,
        'tenant-2',
      );
      expect(result.tenantsProcessed, 2);
      expect(result.errorsCount, 0);
    });

    test('passes bound module schemas to discovery client', () async {
      final discovery = _RecordingDiscoveryClient(rows: const []);
      final context = await MessagingWorkerBootstrap.bootstrap(
        config: _baseConfig,
        supabaseClient: _FakeSupabaseClient(),
        modules: _iamBinding(_RecordingMediator()),
      );
      final loop = MessagingWorkerLoop(
        context: context,
        discoveryClient: discovery,
      );

      await loop.runOnce();

      expect(discovery.lastModules, ['iam']);
    });

    test('skips unbound module backlog rows', () async {
      final mediator = _RecordingMediator();
      final logs = <String>[];
      final context = await MessagingWorkerBootstrap.bootstrap(
        config: _baseConfig,
        supabaseClient: _FakeSupabaseClient(),
        modules: _iamBinding(mediator),
      );
      final loop = MessagingWorkerLoop(
        context: context,
        discoveryClient: _SingleRoundDiscoveryClient([
          PendingMessagingWork(
            tenantId: 'tenant-1',
            moduleSchema: 'partner',
            queueType: 'outbox',
            pendingCount: 1,
            oldestCreatedAt: DateTime.utc(2026, 1, 1),
          ),
        ]),
        log: logs.add,
      );

      final result = await loop.runOnce();

      expect(mediator.commands, isEmpty);
      expect(result.tenantsProcessed, 1);
      expect(logs.single, contains('tick skip tenant=tenant-1 module=partner'));
    });

    test('counts unknown queue types as errors', () async {
      final mediator = _RecordingMediator();
      final logs = <String>[];
      final context = await MessagingWorkerBootstrap.bootstrap(
        config: _baseConfig,
        supabaseClient: _FakeSupabaseClient(),
        modules: _iamBinding(mediator),
      );
      final loop = MessagingWorkerLoop(
        context: context,
        discoveryClient: _SingleRoundDiscoveryClient([
          PendingMessagingWork(
            tenantId: 'tenant-1',
            moduleSchema: 'iam',
            queueType: 'dead_letter',
            pendingCount: 1,
            oldestCreatedAt: DateTime.utc(2026, 1, 1),
          ),
        ]),
        log: logs.add,
      );

      final result = await loop.runOnce();

      expect(mediator.commands, isEmpty);
      expect(result.errorsCount, 1);
      expect(logs.single, contains('tick unknown queue tenant=tenant-1'));
    });

    test('processes different partition keys concurrently', () async {
      final mediator = _ConcurrencyTrackingMediator(delay: const Duration(milliseconds: 80));
      final context = await MessagingWorkerBootstrap.bootstrap(
        config: const WorkerEnv(
          supabaseUrl: 'https://example.supabase.co',
          supabaseServiceRoleKey: 'service-role-key',
          tickSecret: 'secret',
          tenantBatchSize: 20,
          moduleBatchSize: 10,
          maxRoundsPerTick: 5,
          concurrency: 4,
        ),
        supabaseClient: _FakeSupabaseClient(),
        modules: _iamBinding(mediator),
      );
      final loop = MessagingWorkerLoop(
        context: context,
        discoveryClient: _SingleRoundDiscoveryClient([
          PendingMessagingWork(
            tenantId: 'tenant-1',
            moduleSchema: 'iam',
            queueType: 'outbox',
            pendingCount: 1,
            oldestCreatedAt: DateTime.utc(2026, 1, 1),
          ),
          PendingMessagingWork(
            tenantId: 'tenant-1',
            moduleSchema: 'iam',
            queueType: 'inbox',
            pendingCount: 1,
            oldestCreatedAt: DateTime.utc(2026, 1, 1, 0, 1),
          ),
        ]),
      );

      await loop.runOnce();

      expect(mediator.commands, hasLength(2));
      expect(mediator.maxInFlight, greaterThanOrEqualTo(2));
    });

    test('serializes work items with the same partition key', () async {
      final mediator = _ConcurrencyTrackingMediator(delay: const Duration(milliseconds: 40));
      final context = await MessagingWorkerBootstrap.bootstrap(
        config: const WorkerEnv(
          supabaseUrl: 'https://example.supabase.co',
          supabaseServiceRoleKey: 'service-role-key',
          tickSecret: 'secret',
          tenantBatchSize: 20,
          moduleBatchSize: 10,
          maxRoundsPerTick: 5,
          concurrency: 4,
        ),
        supabaseClient: _FakeSupabaseClient(),
        modules: _iamBinding(mediator),
      );
      final loop = MessagingWorkerLoop(
        context: context,
        discoveryClient: _SingleRoundDiscoveryClient([
          PendingMessagingWork(
            tenantId: 'tenant-1',
            moduleSchema: 'iam',
            queueType: 'outbox',
            pendingCount: 1,
            oldestCreatedAt: DateTime.utc(2026, 1, 1),
          ),
          PendingMessagingWork(
            tenantId: 'tenant-1',
            moduleSchema: 'iam',
            queueType: 'outbox',
            pendingCount: 2,
            oldestCreatedAt: DateTime.utc(2026, 1, 1, 0, 1),
          ),
        ]),
      );

      await loop.runOnce();

      expect(mediator.commands, hasLength(2));
      expect(mediator.maxInFlight, 1);
    });

    test('stops after maxRoundsPerTick even if backlog remains', () async {
      var discoveryCalls = 0;
      final context = await MessagingWorkerBootstrap.bootstrap(
        config: const WorkerEnv(
          supabaseUrl: 'https://example.supabase.co',
          supabaseServiceRoleKey: 'service-role-key',
          tickSecret: 'secret',
          tenantBatchSize: 20,
          moduleBatchSize: 10,
          maxRoundsPerTick: 2,
          concurrency: 4,
        ),
        supabaseClient: _FakeSupabaseClient(),
        modules: _iamBinding(_RecordingMediator()),
      );
      final loop = MessagingWorkerLoop(
        context: context,
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

final class _RecordingMediator implements IModuleMediator {
  final List<Object> commands = <Object>[];

  @override
  Future<TResult> executeCommandAsync<TResult>(ICommand<TResult> command) async {
    commands.add(command as Object);
    return true as TResult;
  }

  @override
  Future<TResult> executeQueryAsync<TResult>(IQuery<TResult> query) {
    throw UnimplementedError();
  }
}

final class _ConcurrencyTrackingMediator implements IModuleMediator {
  _ConcurrencyTrackingMediator({required this.delay});

  final Duration delay;
  final List<Object> commands = <Object>[];
  int inFlight = 0;
  int maxInFlight = 0;

  @override
  Future<TResult> executeCommandAsync<TResult>(ICommand<TResult> command) async {
    commands.add(command as Object);
    inFlight++;
    if (inFlight > maxInFlight) {
      maxInFlight = inFlight;
    }
    await Future<void>.delayed(delay);
    inFlight--;
    return true as TResult;
  }

  @override
  Future<TResult> executeQueryAsync<TResult>(IQuery<TResult> query) {
    throw UnimplementedError();
  }
}

final class _EmptyDiscoveryClient implements ITenantDiscoveryClient {
  @override
  Future<List<PendingMessagingWork>> listTenantsWithPendingMessaging({
    required int limit,
    List<String>? modules,
  }) async {
    return const [];
  }
}

final class _RecordingDiscoveryClient implements ITenantDiscoveryClient {
  _RecordingDiscoveryClient({required this.rows});

  final List<PendingMessagingWork> rows;
  List<String>? lastModules;

  @override
  Future<List<PendingMessagingWork>> listTenantsWithPendingMessaging({
    required int limit,
    List<String>? modules,
  }) async {
    lastModules = modules;
    return rows;
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

final class _AlwaysHasBacklogDiscoveryClient implements ITenantDiscoveryClient {
  _AlwaysHasBacklogDiscoveryClient({required this.onCall});

  final void Function() onCall;

  @override
  Future<List<PendingMessagingWork>> listTenantsWithPendingMessaging({
    required int limit,
    List<String>? modules,
  }) async {
    onCall();
    return [
      PendingMessagingWork(
        tenantId: 'tenant-1',
        moduleSchema: 'iam',
        queueType: 'outbox',
        pendingCount: 1,
        oldestCreatedAt: DateTime.utc(2026, 1, 1),
      ),
    ];
  }
}
