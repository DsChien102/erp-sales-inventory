import 'dart:async';

import 'package:mocktail/mocktail.dart';
import 'package:messaging_worker/messaging_worker_bootstrap.dart';
import 'package:messaging_worker/tenant_discovery_client.dart';
import 'package:messaging_worker/worker_tick_scheduler.dart';
import 'package:supabase/supabase.dart';
import 'package:test/test.dart';
import 'package:vet45_shared_application/application.dart';

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
          concurrency: 4,
          misaAppId: 'test-app-id',
          misaBaseUrl: 'https://testapi.meinvoice.vn/api/integration',
        ),
        supabaseClient: _FakeSupabaseClient(),
        modules: [
          MessagingModuleBinding(
            moduleSchema: 'iam',
            mediator: _NoopMediator(),
            commands: const IamMessagingCommandFactory(),
          ),
        ],
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

final class _NoopMediator implements IModuleMediator {
  @override
  Future<TResult> executeCommandAsync<TResult>(ICommand<TResult> command) async {
    return false as TResult;
  }

  @override
  Future<TResult> executeQueryAsync<TResult>(IQuery<TResult> query) async =>
      throw UnimplementedError();
}

final class _CountingDiscoveryClient implements ITenantDiscoveryClient {
  _CountingDiscoveryClient({required this.onCall});

  final void Function() onCall;

  @override
  Future<List<PendingMessagingWork>> listTenantsWithPendingMessaging({
    required int limit,
    List<String>? modules,
  }) async {
    onCall();
    return const [];
  }
}
