import 'dart:async';

import 'package:mocktail/mocktail.dart';
import 'package:messaging_worker/messaging_worker_bootstrap.dart';
import 'package:messaging_worker/tenant_discovery_client.dart';
import 'package:messaging_worker/worker_tick_scheduler.dart';
import 'package:supabase/supabase.dart';
import 'package:test/test.dart';
import 'package:vet45_adapters/vet45_adapters.dart';

class _FakeSupabaseClient extends Fake implements SupabaseClient {}

void main() {
  group('WorkerTickScheduler', () {
    test('runs multiple ticks when idle', () async {
      var discoveryCalls = 0;
      final context = await MessagingWorkerBootstrap.bootstrap(
        config: const WorkerEnv(
          supabaseUrl: 'https://example.supabase.co',
          supabaseServiceRoleKey: 'service-role-key',
          tickSecret: 'secret',
          tenantBatchSize: 20,
          moduleBatchSize: 10,
          maxRoundsPerTick: 5,
        ),
        supabaseClient: _FakeSupabaseClient(),
        iamMessagingModule: _NoopModule(),
      );
      final loop = MessagingWorkerLoop(
        context: context,
        discoveryClient: _CountingDiscoveryClient(onCall: () => discoveryCalls++),
      );
      final scheduler = WorkerTickScheduler(
        loop: loop,
        policy: WorkerTickPolicy(
          activeInterval: const Duration(milliseconds: 30),
          idleInterval: const Duration(milliseconds: 30),
          maxIdleInterval: const Duration(milliseconds: 30),
        ),
      );

      scheduler.start();
      await Future<void>.delayed(const Duration(milliseconds: 500));
      scheduler.stop();

      expect(discoveryCalls, greaterThanOrEqualTo(2));
    });
  });
}

final class _NoopModule implements IMessagingModule {
  @override
  String get name => 'iam';

  @override
  Future<MessagingProcessResult> processMessagingOnce({
    required String tenantId,
    int batchSize = 10,
  }) async {
    return MessagingProcessResult.empty;
  }
}

final class _CountingDiscoveryClient implements ITenantDiscoveryClient {
  _CountingDiscoveryClient({required this.onCall});

  final void Function() onCall;

  @override
  Future<List<PendingTenant>> listTenantsWithPendingMessaging({
    required int limit,
  }) async {
    onCall();
    return const [];
  }
}
