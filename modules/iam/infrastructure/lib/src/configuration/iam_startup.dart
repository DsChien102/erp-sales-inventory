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
import 'iam_runtime.dart';
import 'mediation/mediation_module.dart';
import 'outbox/outbox_module.dart';
import 'processing/commands_executor.dart';
import 'processing/generated/iam_access_metadata.g.dart';
import 'processing/inbox/process_inbox_command.dart';
import 'processing/internal_commands/process_internal_commands_command.dart';
import 'processing/outbox/process_outbox_command.dart';
import 'processing/processing_module.dart';
import '../iam_module.dart';
import 'session/iam_session.dart';

/// Composition root entry point for the IAM bounded context.
abstract final class IamStartup {
  /// Bootstrap the IAM module. Session restore is intentionally **not** done
  /// here — callers should invoke [IamRuntime.sessionPort.restoreFromPersistedAuth]
  /// after DI is complete so host apps control the tenant-bootstrap order.
  static Future<IamRuntime> initialize({
    required SupabaseClient supabase,
    required ILoggerFactory loggerFactory,
    IEventsBus? integrationEventBus,
    IResendClient? resendClient,
  }) async {
    final container = GetIt.asNewInstance();
    return _configure(
      container,
      supabase,
      loggerFactory,
      integrationEventBus: integrationEventBus,
      resendClient: resendClient,
    );
  }

  @visibleForTesting
  static Future<IamRuntime> initializeForTesting({
    required SupabaseClient supabase,
    GetIt? container,
    ILoggerFactory? loggerFactory,
    IEventsBus? integrationEventBus,
    /// Legacy: kept for test suites that relied on internal restore.
    /// Prefer calling [IamRuntime.sessionPort.restoreFromPersistedAuth] instead.
    bool restoreSession = false,
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
  }) async {
    final outbox = await CommandsExecutor.execute(
      ProcessOutboxCommand(tenantId: tenantId, batchSize: batchSize),
    );
    final inbox = await CommandsExecutor.execute(
      ProcessInboxCommand(tenantId: tenantId, batchSize: batchSize),
    );
    final internal = await CommandsExecutor.execute(
      ProcessInternalCommandsCommand(tenantId: tenantId, batchSize: batchSize),
    );
    return MessagingProcessResult(
      hadOutboxWork: outbox,
      hadInboxWork: inbox,
      hadInternalWork: internal,
    );
  }

  static Future<IamRuntime> _configure(
    GetIt container,
    SupabaseClient supabase,
    ILoggerFactory loggerFactory, {
    IEventsBus? integrationEventBus,
    bool restoreSession = false,
    bool requireTenantSession = true,
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

    final module = IamModule(container);
    container.registerSingleton<IIamModule>(module);

    return IamRuntime(
      module: module,
      executionContext: container.get<IExecutionContext>(),
      permissionChecker: container.get<IPermissionChecker>(),
      tenantAccessChecker: container.get<ITenantAccessChecker>(),
      activeStoreContext: container.get<IActiveStoreContext>(),
      session: session,
      sessionPort: container.get<IIamSessionPort>(),
    );
  }
}
