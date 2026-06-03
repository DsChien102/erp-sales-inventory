import 'dart:convert';

import 'package:mocktail/mocktail.dart';
import 'package:messaging_worker/http/worker_http_server.dart';
import 'package:messaging_worker/messaging_worker_bootstrap.dart';
import 'package:messaging_worker/tenant_discovery_client.dart';
import 'package:shelf/shelf.dart';
import 'package:supabase/supabase.dart';
import 'package:test/test.dart';

class _FakeSupabaseClient extends Fake implements SupabaseClient {}

void main() {
  late MessagingWorkerLoop loop;
  late Handler handler;

  setUp(() {
    final context = MessagingWorkerBootstrap.bootstrap(
      config: const WorkerEnv(
        supabaseUrl: 'https://example.supabase.co',
        supabaseServiceRoleKey: 'service-role-key',
        tickSecret: 'top-secret',
        tenantBatchSize: 20,
        moduleBatchSize: 10,
        maxRoundsPerTick: 5,
      ),
      supabaseClient: _FakeSupabaseClient(),
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
  });
}

final class _EmptyDiscoveryClient implements ITenantDiscoveryClient {
  @override
  Future<List<PendingTenant>> listTenantsWithPendingMessaging({
    required int limit,
  }) async {
    return const [];
  }
}
