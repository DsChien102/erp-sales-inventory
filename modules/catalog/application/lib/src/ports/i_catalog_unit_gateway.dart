import 'package:vet45_catalog_application/src/product_unit/commands/add_product_conversion_unit/add_product_conversion_unit_command.dart';
import 'package:vet45_catalog_application/src/product_unit/commands/deactivate_product_conversion_unit/deactivate_product_conversion_unit_command.dart';
import 'package:vet45_catalog_application/src/product_unit/commands/delete_product_conversion_unit/delete_product_conversion_unit_command.dart';
import 'package:vet45_catalog_application/src/product_unit/queries/list_product_units/list_product_units_query.dart';
import 'package:vet45_catalog_application/src/product_unit/shared/product_unit_mutation_result.dart';
import 'package:vet45_catalog_application/src/product_unit/shared/product_units_dto.dart';
import 'package:vet45_catalog_application/src/product_unit/commands/reactivate_product_conversion_unit/reactivate_product_conversion_unit_command.dart';
import 'package:vet45_catalog_application/src/product_unit/commands/set_product_base_unit/set_product_base_unit_command.dart';
import 'package:vet45_catalog_application/src/product_unit/commands/set_product_base_unit/set_product_base_unit_result.dart';
import 'package:vet45_catalog_application/src/product_unit/queries/list_tenant_measurement_units/tenant_measurement_unit_dto.dart';

/// Port for tenant measurement units and base-unit assignment (EPIC-04/US-01).
abstract interface class ICatalogUnitGateway {
  Future<List<TenantMeasurementUnitDto>> listTenantUnits({
    required String tenantId,
    String? keyword,
    required int limit,
  });

  Future<bool> isDuplicateUnitName({
    required String tenantId,
    required String name,
  });

  Future<SetProductBaseUnitResult> setProductBaseUnit({
    required SetProductBaseUnitCommand command,
  });

  Future<ProductUnitsDto> listProductUnits({
    required ListProductUnitsQuery query,
  });

  Future<ProductUnitMutationResult> addConversionUnit({
    required AddProductConversionUnitCommand command,
  });

  Future<ProductUnitMutationResult> deactivateConversionUnit({
    required DeactivateProductConversionUnitCommand command,
  });

  Future<ProductUnitMutationResult> reactivateConversionUnit({
    required ReactivateProductConversionUnitCommand command,
  });

  Future<void> deleteConversionUnit({
    required DeleteProductConversionUnitCommand command,
  });
}
