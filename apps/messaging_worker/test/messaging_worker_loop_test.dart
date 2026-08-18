import 'dart:async';
import 'dart:convert';

import 'package:mocktail/mocktail.dart';
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
  misaAppId: 'test-app-id',
  misaBaseUrl: 'https://testapi.meinvoice.vn/api/integration',
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
      final logger = _RecordingLogger();
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
        logger: logger,
      );

      final result = await loop.runOnce();

      expect(mediator.commands, isEmpty);
      expect(result.tenantsProcessed, 1);
      expect(result.queuesSkipped, 1);
      expect(result.tickId, isNotEmpty);
      final skip = logger.infoEvents.singleWhere((e) => e['event'] == 'queue_skip');
      expect(skip['module'], 'partner');
      expect(skip['tenantId'], 'tenant-1');
      expect(skip['tickId'], result.tickId);
    });

    test('counts unknown queue types as errors', () async {
      final mediator = _RecordingMediator();
      final logger = _RecordingLogger();
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
        logger: logger,
      );

      final result = await loop.runOnce();

      expect(mediator.commands, isEmpty);
      expect(result.errorsCount, 1);
      expect(result.queuesUnknown, 1);
      expect(
        logger.warningEvents.singleWhere((e) => e['event'] == 'queue_unknown')['queue'],
        'dead_letter',
      );
    });

    test('enriches tick summary with queue metrics and correlation id', () async {
      final mediator = _RecordingMediator();
      final logger = _RecordingLogger();
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
        ]),
        logger: logger,
      );

      final result = await loop.runOnce();

      expect(result.tickId, startsWith('t'));
      expect(result.workDiscovered, 2);
      expect(result.partitions, 2);
      expect(result.queuesSucceeded, 2);
      expect(result.hadWorkTrue, 2);
      expect(result.byModule, {'iam': 2});
      expect(result.byQueue, {'iam.outbox': 1, 'iam.inbox': 1});
      expect(result.discoveryMs, greaterThanOrEqualTo(0));
      expect(result.processMs, greaterThanOrEqualTo(0));

      final tickEnd = logger.infoEvents.singleWhere((e) => e['event'] == 'tick_end');
      expect(tickEnd['tickId'], result.tickId);
      expect(tickEnd['queuesSucceeded'], 2);
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
          misaAppId: 'test-app-id',
          misaBaseUrl: 'https://testapi.meinvoice.vn/api/integration',
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
          misaAppId: 'test-app-id',
          misaBaseUrl: 'https://testapi.meinvoice.vn/api/integration',
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
          misaAppId: 'test-app-id',
          misaBaseUrl: 'https://testapi.meinvoice.vn/api/integration',
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

final class _RecordingLogger implements ILogger {
  final List<Map<String, dynamic>> fineEvents = <Map<String, dynamic>>[];
  final List<Map<String, dynamic>> infoEvents = <Map<String, dynamic>>[];
  final List<Map<String, dynamic>> warningEvents = <Map<String, dynamic>>[];
  final List<Map<String, dynamic>> severeEvents = <Map<String, dynamic>>[];

  @override
  void fine(Object? message, [Object? error, StackTrace? stackTrace]) {
    fineEvents.add(jsonDecode(message! as String) as Map<String, dynamic>);
  }

  @override
  void info(Object? message, [Object? error, StackTrace? stackTrace]) {
    infoEvents.add(jsonDecode(message! as String) as Map<String, dynamic>);
  }

  @override
  void warning(Object? message, [Object? error, StackTrace? stackTrace]) {
    warningEvents.add(jsonDecode(message! as String) as Map<String, dynamic>);
  }

  @override
  void severe(Object? message, [Object? error, StackTrace? stackTrace]) {
    severeEvents.add(jsonDecode(message! as String) as Map<String, dynamic>);
  }
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
