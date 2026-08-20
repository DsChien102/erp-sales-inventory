import 'package:supabase/supabase.dart';
import 'package:vet45_iam_infrastructure/infrastructure.dart';
import 'package:vet45_resend/vet45_resend.dart';
import 'package:vet45_shared_infrastructure/infrastructure.dart';

import 'config/worker_env.dart';
import 'iam_messaging_command_factory.dart';
import 'messaging_module_binding.dart';
import 'service_role_supabase_client.dart';

export 'config/worker_env.dart' show WorkerEnv;
export 'iam_messaging_command_factory.dart' show IamMessagingCommandFactory;
export 'messaging_module_binding.dart'
    show IMessagingCommandFactory, MessagingModuleBinding, indexMessagingModuleBindings;
export 'messaging_worker_loop.dart' show MessagingWorkerLoop;
export 'worker_tick_policy.dart' show WorkerTickPolicy;

/// Bootstrapped worker runtime: Supabase client, shared bus, and module bindings.
final class MessagingWorkerContext {
  const MessagingWorkerContext({
    required this.supabaseClient,
    required this.integrationEventBus,
    required this.modules,
    required this.config,
  });

  final SupabaseClient supabaseClient;
  final IEventsBus integrationEventBus;
  final List<MessagingModuleBinding> modules;
  final WorkerEnv config;

  List<String> get boundModuleSchemas =>
      modules.map((binding) => binding.moduleSchema).toList(growable: false);
}

final class MessagingWorkerBootstrap {
  static Future<MessagingWorkerContext> bootstrap({
    WorkerEnv? config,
    SupabaseClient? supabaseClient,
    IEventsBus? integrationEventBus,
    ILoggerFactory? loggerFactory,
    List<MessagingModuleBinding>? modules,
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

    final resolvedModules = modules ?? await _defaultIamBinding(
      client: client,
      loggerFactory: resolvedLoggerFactory,
      integrationEventBus: sharedBus,
      config: resolvedConfig,
    );

    return MessagingWorkerContext(
      supabaseClient: client,
      integrationEventBus: sharedBus,
      modules: resolvedModules,
      config: resolvedConfig,
    );
  }

  static Future<List<MessagingModuleBinding>> _defaultIamBinding({
    required SupabaseClient client,
    required ILoggerFactory loggerFactory,
    required IEventsBus integrationEventBus,
    required WorkerEnv config,
  }) async {
    final runtime = await IamStartup.initialize(
      supabase: client,
      loggerFactory: loggerFactory,
      integrationEventBus: integrationEventBus,
      resendClient: ResendEmailClient(
        apiKey: config.resendApiKey,
        fromEmail: config.resendFromEmail,
      ),
    );

    return [
      MessagingModuleBinding(
        moduleSchema: 'iam',
        mediator: runtime.module,
        commands: const IamMessagingCommandFactory(),
      ),
    ];
  }
}
