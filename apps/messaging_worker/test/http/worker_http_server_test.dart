import 'dart:convert';

import 'package:mocktail/mocktail.dart';
import 'package:messaging_worker/http/worker_http_server.dart';
import 'package:messaging_worker/messaging_worker_bootstrap.dart';
import 'package:messaging_worker/tenant_discovery_client.dart';
import 'package:shelf/shelf.dart';
import 'package:supabase/supabase.dart';
import 'package:test/test.dart';
import 'package:vet45_shared_application/application.dart';

class _FakeSupabaseClient extends Fake implements SupabaseClient {}

void main() {
  late MessagingWorkerLoop loop;
  late Handler handler;

  setUp(() async {
    final context = await MessagingWorkerBootstrap.bootstrap(
      config: const WorkerEnv(
        supabaseUrl: 'https://example.supabase.co',
        supabaseServiceRoleKey: 'service-role-key',
        tickSecret: 'top-secret',
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
    loop = MessagingWorkerLoop(
      context: context,
      discoveryClient: _EmptyDiscoveryClient(),
    );
    handler = WorkerHttpServer(loop: loop, tickSecret: 'top-secret').handler;
  });

  test('GET /health returns ok', () async {
    final response = await handler(
      Request('GET', Uri.parse('http://localhost/health')),
    );

    expect(response.statusCode, 200);
    expect(
      jsonDecode(await response.readAsString()),
      {'status': 'ok'},
    );
  });

  test('POST /tick rejects missing bearer token', () async {
    final response = await handler(
      Request('POST', Uri.parse('http://localhost/tick')),
    );

    expect(response.statusCode, 403);
  });

  test('POST /tick rejects invalid bearer token', () async {
    final response = await handler(
      Request(
        'POST',
        Uri.parse('http://localhost/tick'),
        headers: {'authorization': 'Bearer wrong'},
      ),
    );

    expect(response.statusCode, 403);
  });

  test('POST /tick returns tick metrics when authorized', () async {
    final response = await handler(
      Request(
        'POST',
        Uri.parse('http://localhost/tick'),
        headers: {'authorization': 'Bearer top-secret'},
      ),
    );

    expect(response.statusCode, 200);
    final body = jsonDecode(await response.readAsString()) as Map<String, dynamic>;
    expect(body['tenantsProcessed'], 0);
    expect(body['rounds'], 0);
    expect(body['errorsCount'], 0);
    expect(body['hadBacklog'], false);
    expect(body['durationMs'], isA<int>());
    expect(body['event'], 'tick_end');
    expect(body['tickId'], isA<String>());
    expect(body['workDiscovered'], 0);
    expect(body['queuesSucceeded'], 0);
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

final class _EmptyDiscoveryClient implements ITenantDiscoveryClient {
  @override
  Future<List<PendingMessagingWork>> listTenantsWithPendingMessaging({
    required int limit,
    List<String>? modules,
  }) async {
    return const [];
  }
}
