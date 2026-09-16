import 'package:messaging_worker/messaging_worker_bootstrap.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase/supabase.dart';
import 'package:test/test.dart';
import 'package:vet45_shared_infrastructure/infrastructure.dart';

class _FakeSupabaseClient extends Fake implements SupabaseClient {}

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
    test('default bindings include iam, sales, and einvoice', () async {
      final sharedBus = InMemoryEventBusClient();
      final context = await MessagingWorkerBootstrap.bootstrap(
        config: _baseConfig,
        supabaseClient: _FakeSupabaseClient(),
        integrationEventBus: sharedBus,
      );

      expect(identical(context.integrationEventBus, sharedBus), isTrue);
      expect(context.boundModuleSchemas, ['iam', 'sales', 'einvoice']);
    });
  });
}
