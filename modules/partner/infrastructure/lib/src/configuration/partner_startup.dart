import 'package:get_it/get_it.dart';
import 'package:meta/meta.dart';
import 'package:supabase/supabase.dart';
import 'package:vet45_partner_application/application.dart';
import 'package:vet45_shared_application/application.dart';
import 'package:vet45_shared_infrastructure/infrastructure.dart';

import 'data_access/data_access_module.dart';
import 'mediation/mediation_module.dart';
import 'processing/command_bus_partner_internal_command_dispatcher.dart';
import 'processing/generated/partner_access_metadata.g.dart';
import 'processing/generated/partner_integration_event_registry.g.dart';
import 'processing/inbox/process_inbox_command.dart';
import 'processing/inbox/process_inbox_command_handler.dart';
import 'processing/inbox/supabase_partner_inbox_client.dart';
import 'processing/internal_commands/supabase_partner_internal_command_client.dart';
import 'processing/internal_commands/process_internal_commands_command.dart';
import 'processing/internal_commands/process_internal_commands_command_handler.dart';
import 'processing/partner_integration_event_dispatcher.dart';
import 'processing/partner_schema_rpc.dart';
import '../partner_module.dart';

/// Composition root entry point for the partner bounded context.
abstract final class PartnerStartup {
  static IPartnerModule initialize({
    required SupabaseClient supabase,
    required ILoggerFactory loggerFactory,
    required IPermissionChecker permissionChecker,
    required ITenantAccessChecker tenantAccessChecker,
  }) {
    final container = GetIt.asNewInstance();
    return _configure(
      container,
      supabase: supabase,
      loggerFactory: loggerFactory,
      permissionChecker: permissionChecker,
      tenantAccessChecker: tenantAccessChecker,
    );
  }

  /// Service-role composition for `messaging_worker`.
  ///
  /// The worker only drives recurring inbox/internal-command processing which
  /// never hits the business authorization pipeline, so allow-all checkers are
  /// injected instead of the IAM runtime.
  static IPartnerModule initializeForMessaging({
    required SupabaseClient supabase,
    ILoggerFactory? loggerFactory,
  }) {
    return _configure(
      GetIt.asNewInstance(),
      supabase: supabase,
      loggerFactory: loggerFactory ?? const NullLoggerFactory(),
      permissionChecker: _AllowAllPermissionChecker(),
      tenantAccessChecker: _AllowAllTenantAccessChecker(),
    );
  }

  @visibleForTesting
  static IPartnerModule initializeForTesting({
    required SupabaseClient supabase,
    GetIt? container,
    ILoggerFactory? loggerFactory,
    IPermissionChecker? permissionChecker,
    ITenantAccessChecker? tenantAccessChecker,
  }) {
    final resolvedContainer = container ?? GetIt.asNewInstance();
    return _configure(
      resolvedContainer,
      supabase: supabase,
      loggerFactory: loggerFactory ?? const NullLoggerFactory(),
      permissionChecker: permissionChecker ?? _AllowAllPermissionChecker(),
      tenantAccessChecker: tenantAccessChecker ?? _AllowAllTenantAccessChecker(),
    );
  }

  static IPartnerModule _configure(
    GetIt container, {
    required SupabaseClient supabase,
    required ILoggerFactory loggerFactory,
    required IPermissionChecker permissionChecker,
    required ITenantAccessChecker tenantAccessChecker,
  }) {
    final commandLogger = loggerFactory.named('partner.commands');

    container
      ..registerSingleton<ILoggerFactory>(loggerFactory)
      ..registerSingleton<IPermissionChecker>(permissionChecker)
      ..registerSingleton<ITenantAccessChecker>(tenantAccessChecker)
      ..registerSingleton<CommandBus>(
        CommandBus(logger: commandLogger, container: container),
      )
      ..registerSingleton<QueryBus>(QueryBus());

    const PartnerDataAccessModule().load(
      container: container,
      supabase: supabase,
      loggerFactory: loggerFactory,
    );

    container.registerSingleton<IAccessMetadataRegistry>(partnerAccessMetadataRegistry);

    const PartnerMediationModule().load(
      container: container,
      commandBus: container.get<CommandBus>(),
      queryBus: container.get<QueryBus>(),
      commandLogger: commandLogger,
    );

    _wireMessaging(container);

    final module = PartnerModule(container);
    container.registerSingleton<IPartnerModule>(module);
    return module;
  }

  /// Registers inbox / internal-command processing on the module `CommandBus`.
  ///
  /// Business + internal command handlers are already registered by
  /// [PartnerMediationModule]; here we add the recurring pump commands and the
  /// application-facing internal-command dispatcher used by consumer handlers.
  static void _wireMessaging(GetIt container) {
    final commandBus = container.get<CommandBus>();
    final rpcClient = container.get<PartnerSchemaRpc>();

    final inboxClient = SupabasePartnerInboxClient(rpcClient: rpcClient);
    container.registerSingleton<IPartnerInboxClient>(inboxClient);

    container.registerSingleton<IPartnerInternalCommandDispatcher>(
      CommandBusPartnerInternalCommandDispatcher(commandBus),
    );

    final integrationEventDispatcher =
        createGeneratedPartnerIntegrationEventDispatcher(container);
    container.registerSingleton<PartnerIntegrationEventDispatcher>(
      integrationEventDispatcher,
    );

    final processInboxHandler = ProcessInboxCommandHandler(
      inboxClient: inboxClient,
      integrationEventDispatcher: integrationEventDispatcher,
    );
    final processInternalHandler = ProcessInternalCommandsCommandHandler(
      commandClient: container.get<IPartnerInternalCommandClient>(),
      commandBus: commandBus,
    );

    commandBus
      ..register<ProcessInboxCommand, bool>(processInboxHandler.handle)
      ..register<ProcessInternalCommandsCommand, bool>(
        processInternalHandler.handle,
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
