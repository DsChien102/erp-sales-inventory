import 'package:supabase/supabase.dart';
import 'package:vet45_adapters/vet45_adapters.dart';
import 'package:vet45_partner_infrastructure/infrastructure.dart';
import 'package:vet45_shared_infrastructure/infrastructure.dart';

import 'config/worker_env.dart';
import 'service_role_supabase_client.dart';

export 'config/worker_env.dart' show WorkerEnv;
export 'messaging_worker_loop.dart' show MessagingWorkerLoop;
export 'worker_tick_policy.dart' show WorkerTickPolicy;

/// Bootstrapped worker runtime: Supabase client, shared bus, module registry.
final class MessagingWorkerContext {
  const MessagingWorkerContext({
    required this.supabaseClient,
    required this.integrationEventBus,
    required this.registry,
    required this.config,
  });

  final SupabaseClient supabaseClient;
  final IEventsBus integrationEventBus;
  final MessagingModuleRegistry registry;
  final WorkerEnv config;
}

final class MessagingWorkerBootstrap {
  static MessagingWorkerContext bootstrap({
    WorkerEnv? config,
    SupabaseClient? supabaseClient,
    IEventsBus? integrationEventBus,
    ILoggerFactory? loggerFactory,
  }) {
    final resolvedConfig = config ?? WorkerEnv.fromPlatform();
    final client =
        supabaseClient ??
        createServiceRoleSupabaseClient(
          url: resolvedConfig.supabaseUrl,
          serviceRoleKey: resolvedConfig.supabaseServiceRoleKey,
        );
    final sharedBus = integrationEventBus ?? InMemoryEventBusClient();
    final resolvedLoggerFactory = loggerFactory ?? const NullLoggerFactory();

    final partnerModule = PartnerMessagingModule.create(
      supabase: client,
      loggerFactory: resolvedLoggerFactory,
    );

    final registry = MessagingModuleRegistry([partnerModule]);

    return MessagingWorkerContext(
      supabaseClient: client,
      integrationEventBus: sharedBus,
      registry: registry,
      config: resolvedConfig,
    );
  }
}
