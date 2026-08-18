import 'package:get_it/get_it.dart';
import 'package:meta/meta.dart';
import 'package:supabase/supabase.dart';
import 'package:vet45_adapters/vet45_adapters.dart';
import 'package:vet45_einvoice_application/application.dart';
import 'package:vet45_misa/e_invoice.dart';
import 'package:vet45_shared_application/application.dart';
import 'package:vet45_shared_infrastructure/infrastructure.dart';

import '../einvoice_module.dart';
import 'data_access/data_access_module.dart';
import 'einvoice_runtime.dart';
import 'mediation/mediation_module.dart';
import 'processing/commands_executor.dart';
import 'processing/generated/einvoice_access_metadata.g.dart';
import 'processing/processing_module.dart';

/// Composition root entry point for the e-invoice bounded context.
abstract final class EinvoiceStartup {
  static EinvoiceRuntime initialize({
    required SupabaseClient supabase,
    required ILoggerFactory loggerFactory,
    required IPermissionChecker permissionChecker,
    required ITenantAccessChecker tenantAccessChecker,
    IEventsBus? integrationEventBus,
    required String misaAppId,
    String misaBaseUrl = MeInvoiceConfig.testBaseUrl,
  }) {
    final container = GetIt.asNewInstance();
    return _configure(
      container,
      supabase: supabase,
      loggerFactory: loggerFactory,
      permissionChecker: permissionChecker,
      tenantAccessChecker: tenantAccessChecker,
      integrationEventBus: integrationEventBus ?? InMemoryEventBusClient(),
      misaAppId: misaAppId,
      misaBaseUrl: misaBaseUrl,
    );
  }

  @visibleForTesting
  static EinvoiceRuntime initializeForTesting({
    required SupabaseClient supabase,
    GetIt? container,
    ILoggerFactory? loggerFactory,
    IPermissionChecker? permissionChecker,
    ITenantAccessChecker? tenantAccessChecker,
    IEventsBus? integrationEventBus,
    String misaAppId = 'test-app-id',
    String misaBaseUrl = MeInvoiceConfig.testBaseUrl,
  }) {
    final resolvedContainer = container ?? GetIt.asNewInstance();
    return _configure(
      resolvedContainer,
      supabase: supabase,
      loggerFactory: loggerFactory ?? const NullLoggerFactory(),
      permissionChecker: permissionChecker ?? _AllowAllPermissionChecker(),
      tenantAccessChecker:
          tenantAccessChecker ?? _AllowAllTenantAccessChecker(),
      integrationEventBus: integrationEventBus ?? InMemoryEventBusClient(),
      misaAppId: misaAppId,
      misaBaseUrl: misaBaseUrl,
    );
  }

  static EinvoiceRuntime _configure(
    GetIt container, {
    required SupabaseClient supabase,
    required ILoggerFactory loggerFactory,
    required IPermissionChecker permissionChecker,
    required ITenantAccessChecker tenantAccessChecker,
    required IEventsBus integrationEventBus,
    required String misaAppId,
    required String misaBaseUrl,
  }) {
    final commandLogger = loggerFactory.named('einvoice.commands');

    container
      ..registerSingleton<ILoggerFactory>(loggerFactory)
      ..registerSingleton<IPermissionChecker>(permissionChecker)
      ..registerSingleton<ITenantAccessChecker>(tenantAccessChecker)
      ..registerSingleton<IEventsBus>(integrationEventBus)
      ..registerSingleton<CommandBus>(
        CommandBus(logger: commandLogger, container: container),
      )
      ..registerSingleton<QueryBus>(QueryBus());

    EinvoiceCommandsExecutor.bind(container.get<CommandBus>());

    EinvoiceOutboxModule.createDefault().load(container);

    EinvoiceDataAccessModule().load(
      container: container,
      supabase: supabase,
      loggerFactory: loggerFactory,
      misaAppId: misaAppId,
      misaBaseUrl: misaBaseUrl,
    );

    EinvoiceProcessingModule().load(
      container: container,
      rpcClient: container.get<SupabaseSchemaRpcClient>(),
      eventsBus: integrationEventBus,
      eventTypeMapper: container.get<IDomainNotificationMapper>(),
    );

    container.registerSingleton<IAccessMetadataRegistry>(
      einvoiceAccessMetadataRegistry,
    );

    EinvoiceMediationModule().load(
      container: container,
      commandBus: container.get<CommandBus>(),
      queryBus: container.get<QueryBus>(),
      commandLogger: commandLogger,
    );

    EinvoiceProcessingModule().registerProcessHandlers(
      commandBus: container.get<CommandBus>(),
      container: container,
    );

    final module = EinvoiceModule(container);
    container.registerSingleton<IEInvoiceModule>(module);

    return EinvoiceRuntime(module: module);
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
