import '../units/add_product_conversion_unit_command.dart';
import '../units/deactivate_product_conversion_unit_command.dart';
import '../units/delete_product_conversion_unit_command.dart';
import '../units/list_product_units_query.dart';
import '../units/product_unit_mutation_result.dart';
import '../units/product_units_dto.dart';
import '../units/reactivate_product_conversion_unit_command.dart';
import '../units/set_product_base_unit_command.dart';
import '../units/set_product_base_unit_result.dart';
import '../units/tenant_measurement_unit_dto.dart';

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
