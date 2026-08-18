import 'package:supabase/supabase.dart';
import 'package:vet45_einvoice_infrastructure/infrastructure.dart';
import 'package:vet45_iam_infrastructure/infrastructure.dart';
import 'package:vet45_resend/vet45_resend.dart';
import 'package:vet45_shared_application/application.dart';
import 'package:vet45_shared_infrastructure/infrastructure.dart';

import 'config/worker_env.dart';
import 'iam_messaging_command_factory.dart';
import 'messaging_module_binding.dart';
import 'service_role_supabase_client.dart';

export 'config/worker_env.dart';
export 'iam_messaging_command_factory.dart';
export 'messaging_module_binding.dart';
export 'messaging_worker_loop.dart';
export 'messaging_worker_tick_result.dart';
export 'worker_structured_log.dart';
export 'worker_tick_policy.dart';

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

    final iamRuntime = await IamStartup.initialize(
      supabase: client,
      loggerFactory: resolvedLoggerFactory,
      integrationEventBus: integrationEventBus,
      resendClient: ResendEmailClient(
        apiKey: resolvedConfig.resendApiKey,
        fromEmail: resolvedConfig.resendFromEmail,
      ),
    );

    final eInvoiceRuntime = EinvoiceStartup.initialize(
      supabase: client,
      loggerFactory: resolvedLoggerFactory,
      permissionChecker: _AllowAllPermissionChecker(),
      tenantAccessChecker: _AllowAllTenantAccessChecker(),
      integrationEventBus: sharedBus,
      misaAppId: resolvedConfig.misaAppId,
      misaBaseUrl: resolvedConfig.misaBaseUrl,
    );

    final resolvedModules =
        modules ??
        <MessagingModuleBinding>[
          MessagingModuleBinding(
            moduleSchema: 'iam',
            mediator: iamRuntime.module,
            commands: const IamMessagingCommandFactory(),
          ),
          MessagingModuleBinding(
            moduleSchema: 'iam',
            mediator: eInvoiceRuntime.module,
            commands: const IamMessagingCommandFactory(),
          ),
        ];

    return MessagingWorkerContext(
      supabaseClient: client,
      integrationEventBus: sharedBus,
      modules: resolvedModules,
      config: resolvedConfig,
    );
  }
}

final class _AllowAllPermissionChecker implements IPermissionChecker {
  @override
  Future<void> require(String permissionCode) async {}
}

final class _AllowAllTenantAccessChecker implements ITenantAccessChecker {
  @override
  Future<void> ensureAccess(String tenantId) async {}
}
