import 'package:get_it/get_it.dart';
import 'package:supabase/supabase.dart';
import 'package:vet45_inventory_application/application.dart';
import 'package:vet45_shared_application/application.dart';
import 'package:vet45_shared_infrastructure/infrastructure.dart';

import '../inventory_module.dart';
import 'data_access/data_access_module.dart';
import 'mediation/mediation_module.dart';
import 'processing/generated/inventory_access_metadata.g.dart';

abstract final class InventoryStartup {
  static IInventoryModule initialize({
    required SupabaseClient supabase,
    required ILoggerFactory loggerFactory,
    required IExecutionContext executionContext,
    required IPermissionChecker permissionChecker,
    required ITenantAccessChecker tenantAccessChecker,
  }) {
    final container = GetIt.asNewInstance();
    final commandLogger = loggerFactory.named('inventory.commands');
    container
      ..registerSingleton<ILoggerFactory>(loggerFactory)
      ..registerSingleton<IExecutionContext>(executionContext)
      ..registerSingleton<IPermissionChecker>(permissionChecker)
      ..registerSingleton<ITenantAccessChecker>(tenantAccessChecker)
      ..registerSingleton<CommandBus>(
        CommandBus(logger: commandLogger, container: container),
      )
      ..registerSingleton<QueryBus>(QueryBus());
    const InventoryDataAccessModule().load(
      container: container,
      supabase: supabase,
      loggerFactory: loggerFactory,
    );
    container.registerSingleton<IAccessMetadataRegistry>(
      inventoryAccessMetadataRegistry,
    );
    const InventoryMediationModule().load(
      container: container,
      commandBus: container.get<CommandBus>(),
      queryBus: container.get<QueryBus>(),
      commandLogger: commandLogger,
    );
    final module = InventoryModule(container);
    container.registerSingleton<IInventoryModule>(module);
    return module;
  }
}
