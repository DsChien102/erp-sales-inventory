import 'package:erp/features/catalog/data/custom_field_repository.dart';
import 'package:erp/features/catalog/data/measurement_unit_repository.dart';
import 'package:erp/features/catalog/data/product_price_repository.dart';
import 'package:erp/features/catalog/data/product_repository.dart';
import 'package:get_it/get_it.dart';

import 'fake_catalog_backend.dart';
import 'fake_catalog_repositories.dart';
import 'fake_catalog_scenario.dart';

/// Registers fake catalog repositories into [getIt].
/// Returns the backing [FakeCatalogBackend].
FakeCatalogBackend registerFakeCatalog(
  GetIt getIt, {
  String scenario = FakeCatalogScenario.guidedCreateOk,
  FakeCatalogBackend? backend,
  bool registerExecutionContext = true,
}) {
  final effectiveBackend = backend ?? FakeCatalogBackend(scenario: scenario);

  if (getIt.isRegistered<ProductRepository>()) {
    getIt.unregister<ProductRepository>();
  }
  getIt.registerSingleton<ProductRepository>(
    FakeProductRepository(backend: effectiveBackend),
  );

  if (getIt.isRegistered<MeasurementUnitRepository>()) {
    getIt.unregister<MeasurementUnitRepository>();
  }
  getIt.registerSingleton<MeasurementUnitRepository>(
    FakeMeasurementUnitRepository(backend: effectiveBackend),
  );

  if (getIt.isRegistered<CustomFieldRepository>()) {
    getIt.unregister<CustomFieldRepository>();
  }
  getIt.registerSingleton<CustomFieldRepository>(
    FakeCustomFieldRepository(backend: effectiveBackend),
  );

  if (getIt.isRegistered<ProductPriceRepository>()) {
    getIt.unregister<ProductPriceRepository>();
  }
  getIt.registerSingleton<ProductPriceRepository>(
    FakeProductPriceRepository(backend: effectiveBackend),
  );

  if (registerExecutionContext) {
  }

  return effectiveBackend;
}
