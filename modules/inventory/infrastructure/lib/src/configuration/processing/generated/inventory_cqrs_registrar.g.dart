// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint

import 'package:get_it/get_it.dart';
import 'package:vet45_inventory_application/application.dart';
import 'package:vet45_shared_application/application.dart';
import 'package:vet45_shared_infrastructure/infrastructure.dart';

import '../internal_commands/supabase_inventory_internal_command_client.dart';
import 'inventory_command_registration.g.dart';

void registerGeneratedInventoryValidators(GetIt container) {
  container
    ..registerFactory<ICommandValidator<EnsureDefaultStoreWarehousePairCommand>>(
      EnsureDefaultStoreWarehousePairCommandValidator.new,
    )
    ;
}

void registerGeneratedInventoryHandlers({
  required CommandBus bus,
  required GetIt container,
  required IInventoryInternalCommandClient internalCommandClient,
  ILogger? logger,
}) {
  registerGeneratedInventoryValidators(container);

  InventoryCommandRegistration.registerBusinessHandler<EnsureDefaultStoreWarehousePairCommand, EnsureDefaultStoreWarehousePairResultDto, EnsureDefaultStoreWarehousePairCommandHandler>(
    container: container,
    bus: bus,
    logger: logger,
    factory: () => EnsureDefaultStoreWarehousePairCommandHandler(
      executionContext: container.get<IExecutionContext>(),
      defaultStoreWarehousePairPort: container.get<IDefaultStoreWarehousePairPort>(),
    ),
  );

}

void registerGeneratedInventoryQueries({
  required QueryBus bus,
  required GetIt container,
}) {
  InventoryCommandRegistration.registerQueryHandler<GetDefaultStoreWarehousePairQuery, DefaultStoreWarehousePairDto, GetDefaultStoreWarehousePairQueryHandler>(
    bus: bus,
    factory: () => GetDefaultStoreWarehousePairQueryHandler(
      permissionChecker: container.get<IPermissionChecker>(),
      executionContext: container.get<IExecutionContext>(),
      defaultStoreWarehousePairPort: container.get<IDefaultStoreWarehousePairPort>(),
    ),
    invoke: (query, handler) => handler.handle(query),
  );

}

