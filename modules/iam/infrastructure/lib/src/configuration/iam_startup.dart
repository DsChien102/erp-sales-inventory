import 'package:get_it/get_it.dart';
import 'package:meta/meta.dart';
import 'package:supabase/supabase.dart';
import 'package:vet45_iam_application/application.dart';
import 'package:vet45_shared_application/application.dart';
import 'package:vet45_shared_infrastructure/infrastructure.dart';

import 'data_access/data_access_module.dart';
import 'iam_runtime.dart';
import 'mediation/mediation_module.dart';
import '../iam_module.dart';
import 'session/iam_session.dart';

/// Composition root entry point for the IAM bounded context.
abstract final class IamStartup {
  static Future<IamRuntime> initialize({
    required SupabaseClient supabase,
    required ILoggerFactory loggerFactory,
    IEventsBus? integrationEventBus,
  }) async {
    final container = GetIt.asNewInstance();
    return _configure(container, supabase, loggerFactory);
  }

  @visibleForTesting
  static Future<IamRuntime> initializeForTesting({
    required SupabaseClient supabase,
    GetIt? container,
    ILoggerFactory? loggerFactory,
  }) {
    final resolvedContainer = container ?? GetIt.asNewInstance();
    final resolvedLoggerFactory =
        loggerFactory ?? const NullLoggerFactory();
    return _configure(resolvedContainer, supabase, resolvedLoggerFactory);
  }

  static Future<IamRuntime> _configure(
    GetIt container,
    SupabaseClient supabase,
    ILoggerFactory loggerFactory,
  ) async {
    final commandLogger = loggerFactory.named('iam.commands');

    container
      ..registerSingleton<ILoggerFactory>(loggerFactory)
      ..registerSingleton<CommandBus>(
        CommandBus(logger: commandLogger, container: container),
      )
      ..registerSingleton<QueryBus>(QueryBus());

    const IamDataAccessModule().load(
      container: container,
      supabase: supabase,
      loggerFactory: loggerFactory,
    );

    const IamMediationModule().load(
      container: container,
      commandBus: container.get<CommandBus>(),
      queryBus: container.get<QueryBus>(),
      commandLogger: commandLogger,
    );

    final session = container.get<IamSession>();
    final sessionPort = container.get<IIamSessionPort>();
    await sessionPort.restoreFromPersistedAuth();

    final module = IamModule(container);
    container.registerSingleton<IIamModule>(module);

    return IamRuntime(
      module: module,
      executionContext: container.get<IExecutionContext>(),
      permissionChecker: container.get<IPermissionChecker>(),
      tenantAccessChecker: container.get<ITenantAccessChecker>(),
      session: session,
    );
  }
}
