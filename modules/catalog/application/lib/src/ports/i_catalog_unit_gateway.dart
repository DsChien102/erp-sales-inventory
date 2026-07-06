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
}
