import 'package:get_it/get_it.dart';
import 'package:meta/meta.dart';
import 'package:supabase/supabase.dart';
import 'package:vet45_sales_application/application.dart';
import 'package:vet45_shared_application/application.dart';
import 'package:vet45_shared_infrastructure/infrastructure.dart';

import '../sales_module.dart';
import 'data_access/data_access_module.dart';
import 'mediation/mediation_module.dart';
import 'processing/generated/sales_access_metadata.g.dart';

/// Composition root entry point for the sales bounded context.
abstract final class SalesStartup {
  static ISalesModule initialize({
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

  @visibleForTesting
  static ISalesModule initializeForTesting({
    required SupabaseClient supabase,
    GetIt? container,
    ILoggerFactory? loggerFactory,
    IPermissionChecker? permissionChecker,
    ITenantAccessChecker? tenantAccessChecker,
    ISalesOrderDraftGateway? salesOrderDraftGateway,
    ICheckoutGateway? checkoutGateway,
  }) {
    return _configure(
      container ?? GetIt.asNewInstance(),
      supabase: supabase,
      loggerFactory: loggerFactory ?? const NullLoggerFactory(),
      permissionChecker: permissionChecker ?? _AllowAllPermissionChecker(),
      tenantAccessChecker: tenantAccessChecker ?? _AllowAllTenantAccessChecker(),
      salesOrderDraftGateway: salesOrderDraftGateway,
      checkoutGateway: checkoutGateway,
    );
  }

  static ISalesModule _configure(
    GetIt container, {
    required SupabaseClient supabase,
    required ILoggerFactory loggerFactory,
    required IPermissionChecker permissionChecker,
    required ITenantAccessChecker tenantAccessChecker,
    ISalesOrderDraftGateway? salesOrderDraftGateway,
    ICheckoutGateway? checkoutGateway,
  }) {
    final commandLogger = loggerFactory.named('sales.commands');

    container
      ..registerSingleton<ILoggerFactory>(loggerFactory)
      ..registerSingleton<IPermissionChecker>(permissionChecker)
      ..registerSingleton<ITenantAccessChecker>(tenantAccessChecker)
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

    container.registerSingleton<IAccessMetadataRegistry>(
      salesAccessMetadataRegistry,
    );

    const SalesMediationModule().load(
      container: container,
      commandBus: container.get<CommandBus>(),
      queryBus: container.get<QueryBus>(),
      commandLogger: commandLogger,
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
