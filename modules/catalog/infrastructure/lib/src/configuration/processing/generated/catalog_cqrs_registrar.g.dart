// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint

import 'package:get_it/get_it.dart';
import 'package:vet45_catalog_application/application.dart';
import 'package:vet45_shared_application/application.dart';
import 'package:vet45_shared_infrastructure/infrastructure.dart';

import '../internal_commands/supabase_catalog_internal_command_client.dart';
import 'catalog_command_registration.g.dart';

void registerGeneratedCatalogValidators(GetIt container) {
  container
    ..registerFactory<ICommandValidator<CreateProductCommand>>(
      CreateProductCommandValidator.new,
    )
    ..registerFactory<ICommandValidator<RequestProductImageUploadCommand>>(
      RequestProductImageUploadCommandValidator.new,
    )
    ;
}

void registerGeneratedCatalogHandlers({
  required CommandBus bus,
  required GetIt container,
  required ICatalogInternalCommandClient internalCommandClient,
  ILogger? logger,
}) {
  registerGeneratedCatalogValidators(container);

  CatalogCommandRegistration.registerBusinessHandler<CreateProductCommand, CreateProductResult, CreateProductCommandHandler>(
    container: container,
    bus: bus,
    logger: logger,
    factory: () => CreateProductCommandHandler(
      commandGateway: container.get<IProductCommandGateway>(),
    ),
  );

  CatalogCommandRegistration.registerBusinessHandler<RequestProductImageUploadCommand, ProductImageUploadSlotDto, RequestProductImageUploadCommandHandler>(
    container: container,
    bus: bus,
    logger: logger,
    factory: () => RequestProductImageUploadCommandHandler(
      uploadPort: container.get<IProductImageUploadPort>(),
    ),
  );

}

void registerGeneratedCatalogQueries({
  required QueryBus bus,
  required GetIt container,
}) {
  CatalogCommandRegistration.registerQueryHandler<CheckDuplicateProductCodeQuery, List<ProductDuplicateMatchDto>, CheckDuplicateProductCodeQueryHandler>(
    bus: bus,
    factory: () => CheckDuplicateProductCodeQueryHandler(
      duplicateChecker: container.get<IProductDuplicateChecker>(),
    ),
    invoke: (query, handler) => handler.handle(query),
  );

}

