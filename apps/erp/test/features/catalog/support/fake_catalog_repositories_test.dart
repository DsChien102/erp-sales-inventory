import 'package:erp/core/errors/app_exception.dart';
import 'package:erp/features/catalog/data/custom_field_repository.dart';
import 'package:erp/features/catalog/data/measurement_unit_repository.dart';
import 'package:erp/features/catalog/data/models.dart';
import 'package:erp/features/catalog/data/product_price_repository.dart';
import 'package:erp/features/catalog/data/product_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';

import 'catalog_test_registry.dart';
import 'fake_catalog_backend.dart';
import 'fake_catalog_repositories.dart';
import 'fake_catalog_scenario.dart';

void main() {
  group('FakeCatalogRepositories & Registry', () {
    late FakeCatalogBackend backend;
    late FakeProductRepository productRepo;
    late FakeMeasurementUnitRepository unitRepo;
    late FakeCustomFieldRepository customFieldRepo;
    late FakeProductPriceRepository priceRepo;

    setUp(() {
      backend = FakeCatalogBackend(scenario: FakeCatalogScenario.guidedCreateOk);
      productRepo = FakeProductRepository(backend: backend);
      unitRepo = FakeMeasurementUnitRepository(backend: backend);
      customFieldRepo = FakeCustomFieldRepository(backend: backend);
      priceRepo = FakeProductPriceRepository(backend: backend);
    });

    tearDown(() {
      GetIt.instance.reset();
    });

    test('FakeProductRepository delegates to backend and records call', () async {
      final result = await productRepo.search();
      expect(productRepo.calls, contains('search'));
      expect(result.items, isNotEmpty);
    });

    test('FakeMeasurementUnitRepository delegates to backend and records call', () async {
      final units = await unitRepo.listTenantUnits();
      expect(unitRepo.calls, contains('listTenantUnits'));
      expect(units, isNotEmpty);
    });

    test('FakeCustomFieldRepository delegates to backend and records call', () async {
      await customFieldRepo.initializeTemplate();
      final config = await customFieldRepo.listConfig();
      expect(customFieldRepo.calls, contains('initializeTemplate'));
      expect(customFieldRepo.calls, contains('listConfig'));
      expect(config.groups, isNotEmpty);
    });

    test('FakeProductPriceRepository delegates to backend and records call', () async {
      final rule = await priceRepo.getStorePriceRule();
      expect(priceRepo.calls, contains('getStorePriceRule'));
      expect(rule, isNotNull);
    });

    test('FakeProductRepository throws AppException on permission denied scenario', () async {
      final errorBackend = FakeCatalogBackend(scenario: FakeCatalogScenario.guidedCreatePermissionDenied);
      final repo = FakeProductRepository(backend: errorBackend);

      expect(
        () => repo.createGuided(
          const CreateGuidedProductInput(
            productName: 'Thuốc thử',
          ),
        ),
        throwsA(
          isA<AppException>()
              .having((e) => e.code, 'code', AppErrorCode.noPermission)
              .having((e) => e.serverMessage, 'serverMessage', 'Permission denied'),
        ),
      );
      expect(repo.calls, contains('createGuided'));
    });

    test('FakeMeasurementUnitRepository throws DUPLICATE_PRODUCT_UNIT with details', () async {
      expect(
        () => unitRepo.addConversionUnit(
          productId: 'product-1',
          unitName: 'Hộp',
          conversionRateToBase: 2.0,
        ),
        throwsA(
          isA<AppException>()
              .having((e) => e.code, 'code', CatalogErrorCodes.duplicateProductUnit)
              .having((e) => e.details?['value'], 'details.value', 'Hộp'),
        ),
      );
      expect(unitRepo.calls, contains('addConversionUnit'));
    });

    test('FakeCustomFieldRepository throws DUPLICATE_CUSTOM_FIELD_GROUP_NAME with details', () async {
      await customFieldRepo.initializeTemplate();
      expect(
        () => customFieldRepo.upsertGroup(name: 'Thông tin thuốc'),
        throwsA(
          isA<AppException>()
              .having((e) => e.code, 'code', CatalogErrorCodes.duplicateCustomFieldGroupName)
              .having((e) => e.details?['value'], 'details.value', 'Thông tin thuốc'),
        ),
      );
      expect(customFieldRepo.calls, contains('upsertGroup'));
    });

    test('FakeProductPriceRepository throws PRICE_BAND_OVERWRITE_REQUIRED with details', () async {
      final readyBackend = FakeCatalogBackend(scenario: FakeCatalogScenario.pccReadyToSell);
      final repo = FakeProductPriceRepository(backend: readyBackend);

      expect(
        () => repo.applyStorePriceRule(
          productId: 'product-1',
          confirmOverwrite: false,
        ),
        throwsA(
          isA<AppException>()
              .having((e) => e.code, 'code', CatalogErrorCodes.priceBandOverwriteRequired)
              .having((e) => e.details?['existing_list_after_vat'], 'existing_list_after_vat', isNotNull),
        ),
      );
      expect(repo.calls, contains('applyStorePriceRule'));
    });

    test('registerFakeCatalog registers all services into GetIt', () async {
      final getIt = GetIt.instance;
      final registeredBackend = registerFakeCatalog(getIt);

      expect(registeredBackend, isA<FakeCatalogBackend>());
      expect(getIt<ProductRepository>(), isA<FakeProductRepository>());
      expect(getIt<MeasurementUnitRepository>(), isA<FakeMeasurementUnitRepository>());
      expect(getIt<CustomFieldRepository>(), isA<FakeCustomFieldRepository>());
      expect(getIt<ProductPriceRepository>(), isA<FakeProductPriceRepository>());
    });
  });
}
