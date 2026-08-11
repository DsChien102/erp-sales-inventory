import 'package:get_it/get_it.dart';
import 'package:meta/meta.dart';
import 'package:supabase/supabase.dart';
import 'package:vet45_adapters/vet45_adapters.dart';
import 'package:vet45_iam_application/application.dart';
import 'package:vet45_resend/vet45_resend.dart';
import 'package:vet45_shared_application/application.dart';
import 'package:vet45_shared_infrastructure/infrastructure.dart';

import 'data_access/data_access_module.dart';
import 'events_bus/events_bus_module.dart';
import 'events_bus/events_bus_startup.dart';
import 'iam_messaging_module.dart';
import 'iam_runtime.dart';
import 'mediation/mediation_module.dart';
import 'outbox/outbox_module.dart';
import 'processing/commands_executor.dart';
import 'processing/generated/iam_access_metadata.g.dart';
import 'processing/processing_module.dart';
import '../iam_module.dart';
import 'session/iam_session.dart';

/// Composition root entry point for the IAM bounded context.
abstract final class IamStartup {
  static Future<IamRuntime> initialize({
    required SupabaseClient supabase,
    required ILoggerFactory loggerFactory,
    IEventsBus? integrationEventBus,
    bool restoreSession = true,
    bool requireTenantSession = true,
    IResendClient? resendClient,
  }) async {
    final container = GetIt.asNewInstance();
    return _configure(
      container,
      supabase,
      loggerFactory,
      integrationEventBus: integrationEventBus,
      restoreSession: restoreSession,
      requireTenantSession: requireTenantSession,
      resendClient: resendClient,
    );
  }

  @visibleForTesting
  static Future<IamRuntime> initializeForTesting({
    required SupabaseClient supabase,
    GetIt? container,
    ILoggerFactory? loggerFactory,
    IEventsBus? integrationEventBus,
    bool restoreSession = true,
    bool requireTenantSession = true,
    IResendClient? resendClient,
  }) {
    final resolvedContainer = container ?? GetIt.asNewInstance();
    final resolvedLoggerFactory = loggerFactory ?? const NullLoggerFactory();
    return _configure(
      resolvedContainer,
      supabase,
      resolvedLoggerFactory,
      integrationEventBus: integrationEventBus,
      restoreSession: restoreSession,
      requireTenantSession: requireTenantSession,
      resendClient: resendClient,
    );
  }

  /// Outbox → inbox → internal (same order as sales golden).
  static Future<MessagingProcessResult> processMessagingOnce({
    required String tenantId,
    int batchSize = 10,
  }) {
    return IamStartupMessaging.processMessagingOnce(
      tenantId: tenantId,
      batchSize: batchSize,
    );
  }

  static Future<IamRuntime> _configure(
    GetIt container,
    SupabaseClient supabase,
    ILoggerFactory loggerFactory, {
    IEventsBus? integrationEventBus,
    required bool restoreSession,
    required bool requireTenantSession,
    IResendClient? resendClient,
  }) async {
    final commandLogger = loggerFactory.named('iam.commands');

    container
      ..registerSingleton<ILoggerFactory>(loggerFactory)
      ..registerSingleton<CommandBus>(
        CommandBus(logger: commandLogger, container: container),
      )
      ..registerSingleton<QueryBus>(QueryBus());

    CommandsExecutor.bind(container.get<CommandBus>());

    EventsBusModule(eventsBus: integrationEventBus).load(container);
    OutboxModule.createDefault().load(container);

    const IamDataAccessModule().load(
      container: container,
      supabase: supabase,
      loggerFactory: loggerFactory,
      resendClient: resendClient,
    );

    const ProcessingModule().load(
      container: container,
      rpcClient: container.get<SupabaseSchemaRpcClient>(),
    );
    const IamDataAccessModule().registerEmailDeliveryPort(container);

    container.registerSingleton<IAccessMetadataRegistry>(iamAccessMetadataRegistry);

    const IamMediationModule().load(
      container: container,
      commandBus: container.get<CommandBus>(),
      queryBus: container.get<QueryBus>(),
      commandLogger: commandLogger,
    );

    const ProcessingModule().registerProcessHandlers(
      commandBus: container.get<CommandBus>(),
      container: container,
    );

    EventsBusStartup.initialize(
      container,
      loggerFactory.named('iam.events_bus'),
    );

    final session = container.get<IamSession>();
    final sessionPort = container.get<IIamSessionPort>();
    if (restoreSession) {
      await sessionPort.restoreFromPersistedAuth(
        requireTenantContext: requireTenantSession,
      );
    }

    const messagingModule = IamMessagingModule();

    final module = IamModule(container);
    container.registerSingleton<IIamModule>(module);

    return IamRuntime(
      module: module,
      executionContext: container.get<IExecutionContext>(),
      permissionChecker: container.get<IPermissionChecker>(),
      tenantAccessChecker: container.get<ITenantAccessChecker>(),
      session: session,
      messagingModule: messagingModule,
    );
  }
}
