import 'package:messaging_worker/config/worker_env.dart';
import 'package:test/test.dart';

WorkerEnv _config({
  required String environment,
  String resendFromDomain = 'mail.vet45.vn',
}) {
  return WorkerEnv(
    supabaseUrl: 'https://example.supabase.co',
    supabaseServiceRoleKey: 'service-role-key',
    tickSecret: 'tick-secret',
    tenantBatchSize: 20,
    moduleBatchSize: 10,
    maxRoundsPerTick: 5,
    concurrency: 4,
    misaAppId: 'test-app-id',
    misaBaseUrl: 'https://testapi.meinvoice.vn/api/integration',
    environment: environment,
    resendFromDomain: resendFromDomain,
  );
}

void main() {
  group('WorkerEnv.resendFromEmail', () {
    test('adds dev label for development', () {
      expect(
        _config(environment: 'development').resendFromEmail,
        'VET45 (dev) <noreply@mail.vet45.vn>',
      );
    });

    test('adds staging label for staging', () {
      expect(
        _config(environment: 'staging').resendFromEmail,
        'VET45 (staging) <noreply@mail.vet45.vn>',
      );
    });

    test('omits environment label for production', () {
      expect(
        _config(environment: 'production').resendFromEmail,
        'VET45 <noreply@mail.vet45.vn>',
      );
    });
  });

  group('WorkerEnv misaEmailDeliveryEnabled', () {
    test('defaults to false when environment variable is absent', () {
      final config = _config(environment: 'development');
      expect(config.misaEmailDeliveryEnabled, isFalse);
    });

    test('parses true case-insensitively', () {
      const config = WorkerEnv(
        supabaseUrl: 'https://example.supabase.co',
        supabaseServiceRoleKey: 'service-role-key',
        tickSecret: 'tick-secret',
        tenantBatchSize: 20,
        moduleBatchSize: 10,
        maxRoundsPerTick: 5,
        concurrency: 4,
        misaAppId: 'test-app-id',
        misaBaseUrl: 'https://api.meinvoice.vn/api/integration',
        misaEmailDeliveryEnabled: true,
      );
      expect(config.misaEmailDeliveryEnabled, isTrue);
    });
  });
}
