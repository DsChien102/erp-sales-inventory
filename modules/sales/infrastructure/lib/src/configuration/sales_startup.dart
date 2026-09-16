import 'package:get_it/get_it.dart';
import 'package:meta/meta.dart';
import 'package:supabase/supabase.dart';
import 'package:vet45_adapters/vet45_adapters.dart';
import 'package:vet45_sales_application/application.dart';
import 'package:vet45_shared_application/application.dart';
import 'package:vet45_shared_infrastructure/infrastructure.dart';

import '../sales_module.dart';
import 'data_access/data_access_module.dart';
import 'mediation/mediation_module.dart';
import 'processing/generated/sales_access_metadata.g.dart';
import 'processing/outbox/i_sales_outbox_client.dart';
import 'processing/processing_module.dart';

/// Composition root entry point for the sales bounded context.
abstract final class SalesStartup {
  static ISalesModule initialize({
    required SupabaseClient supabase,
    required ILoggerFactory loggerFactory,
    required IPermissionChecker permissionChecker,
    required ITenantAccessChecker tenantAccessChecker,
    IEventsBus? integrationEventBus,
  }) {
    final container = GetIt.asNewInstance();
    return _configure(
      container,
      supabase: supabase,
      loggerFactory: loggerFactory,
      permissionChecker: permissionChecker,
      tenantAccessChecker: tenantAccessChecker,
      integrationEventBus: integrationEventBus,
    );
  }

  @visibleForTesting
  static ISalesModule initializeForTesting({
    required SupabaseClient supabase,
    GetIt? container,
    ILoggerFactory? loggerFactory,
    IPermissionChecker? permissionChecker,
    ITenantAccessChecker? tenantAccessChecker,
    IEventsBus? integrationEventBus,
    ISalesOrderDraftGateway? salesOrderDraftGateway,
    ICheckoutGateway? checkoutGateway,
    ISalesOutboxClient? salesOutboxClient,
  }) {
    return _configure(
      container ?? GetIt.asNewInstance(),
      supabase: supabase,
      loggerFactory: loggerFactory ?? const NullLoggerFactory(),
      permissionChecker: permissionChecker ?? _AllowAllPermissionChecker(),
      tenantAccessChecker: tenantAccessChecker ?? _AllowAllTenantAccessChecker(),
      integrationEventBus: integrationEventBus,
      salesOrderDraftGateway: salesOrderDraftGateway,
      checkoutGateway: checkoutGateway,
      salesOutboxClient: salesOutboxClient,
    );
  }

  static ISalesModule _configure(
    GetIt container, {
    required SupabaseClient supabase,
    required ILoggerFactory loggerFactory,
    required IPermissionChecker permissionChecker,
    required ITenantAccessChecker tenantAccessChecker,
    IEventsBus? integrationEventBus,
    ISalesOrderDraftGateway? salesOrderDraftGateway,
    ICheckoutGateway? checkoutGateway,
    ISalesOutboxClient? salesOutboxClient,
  }) {
    final commandLogger = loggerFactory.named('sales.commands');
    final resolvedEventBus = integrationEventBus ?? InMemoryEventBusClient();

    container
      ..registerSingleton<ILoggerFactory>(loggerFactory)
      ..registerSingleton<IPermissionChecker>(permissionChecker)
      ..registerSingleton<ITenantAccessChecker>(tenantAccessChecker)
      ..registerSingleton<IEventsBus>(resolvedEventBus)
      ..registerSingleton<CommandBus>(
        CommandBus(logger: commandLogger, container: container),
      )
      ..registerSingleton<QueryBus>(QueryBus());

    const SalesDataAccessModule().load(
      container: container,
      supabase: supabase,
      loggerFactory: loggerFactory,
      salesOrderDraftGateway: salesOrderDraftGateway,
      checkoutGateway: checkoutGateway,
    );

    const ProcessingModule().load(
      container: container,
      rpcClient: container.get<SupabaseSchemaRpcClient>(),
      outboxClient: salesOutboxClient,
    );

    container.registerSingleton<IAccessMetadataRegistry>(
      salesAccessMetadataRegistry,
    );

    const SalesMediationModule().load(
      container: container,
      commandBus: container.get<CommandBus>(),
      queryBus: container.get<QueryBus>(),
      commandLogger: commandLogger,
    );

    const ProcessingModule().registerProcessHandlers(
      commandBus: container.get<CommandBus>(),
      container: container,
    );

    final module = SalesModule(container);
    container.registerSingleton<ISalesModule>(module);
    return module;
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
