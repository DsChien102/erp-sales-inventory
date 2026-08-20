import 'package:supabase/supabase.dart';
import 'package:vet45_adapters/vet45_adapters.dart';
import 'package:vet45_iam_infrastructure/infrastructure.dart';
import 'package:vet45_resend/vet45_resend.dart';
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
  static Future<MessagingWorkerContext> bootstrap({
    WorkerEnv? config,
    SupabaseClient? supabaseClient,
    IEventsBus? integrationEventBus,
    ILoggerFactory? loggerFactory,
    IMessagingModule? iamMessagingModule,
  }) async {
    final resolvedConfig = config ?? WorkerEnv.fromPlatform();
    final client =
        supabaseClient ??
        createServiceRoleSupabaseClient(
          url: resolvedConfig.supabaseUrl,
          serviceRoleKey: resolvedConfig.supabaseServiceRoleKey,
        );
    final sharedBus = integrationEventBus ?? InMemoryEventBusClient();
    final resolvedLoggerFactory = loggerFactory ?? const NullLoggerFactory();

    final IMessagingModule resolvedIamModule;
    if (iamMessagingModule != null) {
      resolvedIamModule = iamMessagingModule;
    } else {
      final runtime = await IamStartup.initialize(
        supabase: client,
        loggerFactory: resolvedLoggerFactory,
        integrationEventBus: sharedBus,
        resendClient: ResendEmailClient(
          apiKey: resolvedConfig.resendApiKey,
          fromEmail: resolvedConfig.resendFromEmail,
        ),
      );
      resolvedIamModule = runtime.messagingModule;
    }

    final registry = MessagingModuleRegistry([resolvedIamModule]);

    return MessagingWorkerContext(
      supabaseClient: client,
      integrationEventBus: sharedBus,
      registry: registry,
      config: resolvedConfig,
    );
  }
}
