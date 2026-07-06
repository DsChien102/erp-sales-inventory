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
    ..registerFactory<ICommandValidator<AddProductConversionUnitCommand>>(
      AddProductConversionUnitCommandValidator.new,
    )
    ..registerFactory<ICommandValidator<AdjustBasicStockCommand>>(
      AdjustBasicStockCommandValidator.new,
    )
    ..registerFactory<ICommandValidator<CreateProductCommand>>(
      CreateProductCommandValidator.new,
    )
    ..registerFactory<ICommandValidator<DeactivateProductConversionUnitCommand>>(
      DeactivateProductConversionUnitCommandValidator.new,
    )
    ..registerFactory<ICommandValidator<ReactivateProductConversionUnitCommand>>(
      ReactivateProductConversionUnitCommandValidator.new,
    )
    ..registerFactory<ICommandValidator<RequestProductImageUploadCommand>>(
      RequestProductImageUploadCommandValidator.new,
    )
    ..registerFactory<ICommandValidator<SetInitialPriceBandCommand>>(
      SetInitialPriceBandCommandValidator.new,
    )
    ..registerFactory<ICommandValidator<SetInitialStockCommand>>(
      SetInitialStockCommandValidator.new,
    )
    ..registerFactory<ICommandValidator<SetManualBasePriceCommand>>(
      SetManualBasePriceCommandValidator.new,
    )
    ..registerFactory<ICommandValidator<SetProductBaseUnitCommand>>(
      SetProductBaseUnitCommandValidator.new,
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

  CatalogCommandRegistration.registerBusinessHandler<AddProductConversionUnitCommand, ProductUnitMutationResult, AddProductConversionUnitCommandHandler>(
    container: container,
    bus: bus,
    logger: logger,
    factory: () => AddProductConversionUnitCommandHandler(
      unitGateway: container.get<ICatalogUnitGateway>(),
    ),
  );

  CatalogCommandRegistration.registerBusinessHandler<AdjustBasicStockCommand, AdjustBasicStockResult, AdjustBasicStockCommandHandler>(
    container: container,
    bus: bus,
    logger: logger,
    factory: () => AdjustBasicStockCommandHandler(
      stockGateway: container.get<ICatalogStockGateway>(),
      readinessReadPort: container.get<IProductReadinessReadPort>(),
    ),
  );

  CatalogCommandRegistration.registerBusinessHandler<CreateProductCommand, CreateProductResult, CreateProductCommandHandler>(
    container: container,
    bus: bus,
    logger: logger,
    factory: () => CreateProductCommandHandler(
      commandGateway: container.get<IProductCommandGateway>(),
    ),
  );

  CatalogCommandRegistration.registerBusinessHandler<DeactivateProductConversionUnitCommand, ProductUnitMutationResult, DeactivateProductConversionUnitCommandHandler>(
    container: container,
    bus: bus,
    logger: logger,
    factory: () => DeactivateProductConversionUnitCommandHandler(
      unitGateway: container.get<ICatalogUnitGateway>(),
    ),
  );

  CatalogCommandRegistration.registerBusinessHandler<ReactivateProductConversionUnitCommand, ProductUnitMutationResult, ReactivateProductConversionUnitCommandHandler>(
    container: container,
    bus: bus,
    logger: logger,
    factory: () => ReactivateProductConversionUnitCommandHandler(
      unitGateway: container.get<ICatalogUnitGateway>(),
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

  CatalogCommandRegistration.registerBusinessHandler<SetInitialPriceBandCommand, void, SetInitialPriceBandCommandHandler>(
    container: container,
    bus: bus,
    logger: logger,
    factory: () => SetInitialPriceBandCommandHandler(
      commandGateway: container.get<IProductCommandGateway>(),
      readinessReadPort: container.get<IProductReadinessReadPort>(),
    ),
  );

  CatalogCommandRegistration.registerBusinessHandler<SetInitialStockCommand, SetInitialStockResult, SetInitialStockCommandHandler>(
    container: container,
    bus: bus,
    logger: logger,
    factory: () => SetInitialStockCommandHandler(
      commandGateway: container.get<IProductCommandGateway>(),
      readinessReadPort: container.get<IProductReadinessReadPort>(),
      unitGateway: container.get<ICatalogUnitGateway>(),
    ),
  );

  CatalogCommandRegistration.registerBusinessHandler<SetManualBasePriceCommand, SetManualBasePriceResult, SetManualBasePriceCommandHandler>(
    container: container,
    bus: bus,
    logger: logger,
    factory: () => SetManualBasePriceCommandHandler(
      commandGateway: container.get<IProductCommandGateway>(),
      readinessReadPort: container.get<IProductReadinessReadPort>(),
      unitGateway: container.get<ICatalogUnitGateway>(),
    ),
  );

  CatalogCommandRegistration.registerBusinessHandler<SetProductBaseUnitCommand, SetProductBaseUnitResult, SetProductBaseUnitCommandHandler>(
    container: container,
    bus: bus,
    logger: logger,
    factory: () => SetProductBaseUnitCommandHandler(
      unitGateway: container.get<ICatalogUnitGateway>(),
    ),
  );

}

void registerGeneratedCatalogQueries({
  required QueryBus bus,
  required GetIt container,
}) {
  CatalogCommandRegistration.registerQueryHandler<CheckDuplicateMeasurementUnitNameQuery, bool, CheckDuplicateMeasurementUnitNameQueryHandler>(
    bus: bus,
    factory: () => CheckDuplicateMeasurementUnitNameQueryHandler(
      unitGateway: container.get<ICatalogUnitGateway>(),
    ),
    invoke: (query, handler) => handler.handle(query),
  );

  CatalogCommandRegistration.registerQueryHandler<CheckDuplicateProductCodeQuery, List<ProductDuplicateMatchDto>, CheckDuplicateProductCodeQueryHandler>(
    bus: bus,
    factory: () => CheckDuplicateProductCodeQueryHandler(
      duplicateChecker: container.get<IProductDuplicateChecker>(),
    ),
    invoke: (query, handler) => handler.handle(query),
  );

  CatalogCommandRegistration.registerQueryHandler<GetProductControlCenterQuery, ProductControlCenterDto, GetProductControlCenterQueryHandler>(
    bus: bus,
    factory: () => GetProductControlCenterQueryHandler(
      readGateway: container.get<ICatalogReadGateway>(),
      permissionChecker: container.get<IPermissionChecker>(),
    ),
    invoke: (query, handler) => handler.handle(query),
  );

  CatalogCommandRegistration.registerQueryHandler<GetProductReadinessQuery, ProductReadinessViewDto, GetProductReadinessQueryHandler>(
    bus: bus,
    factory: () => GetProductReadinessQueryHandler(
      readinessReadPort: container.get<IProductReadinessReadPort>(),
      permissionChecker: container.get<IPermissionChecker>(),
    ),
    invoke: (query, handler) => handler.handle(query),
  );

  CatalogCommandRegistration.registerQueryHandler<GetProductStockHistoryQuery, ProductStockHistoryDto, GetProductStockHistoryQueryHandler>(
    bus: bus,
    factory: () => GetProductStockHistoryQueryHandler(
      stockReadPort: container.get<IProductStockReadPort>(),
      readinessReadPort: container.get<IProductReadinessReadPort>(),
    ),
    invoke: (query, handler) => handler.handle(query),
  );

  CatalogCommandRegistration.registerQueryHandler<ListProductUnitsQuery, ProductUnitsDto, ListProductUnitsQueryHandler>(
    bus: bus,
    factory: () => ListProductUnitsQueryHandler(
      unitGateway: container.get<ICatalogUnitGateway>(),
    ),
    invoke: (query, handler) => handler.handle(query),
  );

  CatalogCommandRegistration.registerQueryHandler<ListTenantMeasurementUnitsQuery, List<TenantMeasurementUnitDto>, ListTenantMeasurementUnitsQueryHandler>(
    bus: bus,
    factory: () => ListTenantMeasurementUnitsQueryHandler(
      unitGateway: container.get<ICatalogUnitGateway>(),
    ),
    invoke: (query, handler) => handler.handle(query),
  );

  CatalogCommandRegistration.registerQueryHandler<ScanBarcodeQuery, ProductListItemDto?, ScanBarcodeQueryHandler>(
    bus: bus,
    factory: () => ScanBarcodeQueryHandler(
      readGateway: container.get<ICatalogReadGateway>(),
    ),
    invoke: (query, handler) => handler.handle(query),
  );

  CatalogCommandRegistration.registerQueryHandler<SearchProductsQuery, ProductSearchResultDto, SearchProductsQueryHandler>(
    bus: bus,
    factory: () => SearchProductsQueryHandler(
      readGateway: container.get<ICatalogReadGateway>(),
    ),
    invoke: (query, handler) => handler.handle(query),
  );

}

