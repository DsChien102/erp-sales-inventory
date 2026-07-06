import 'package:vet45_shared_application/application.dart';

import '../ports/i_catalog_unit_gateway.dart';
import 'list_tenant_measurement_units_query.dart';
import 'list_tenant_measurement_units_query_validator.dart';
import 'tenant_measurement_unit_dto.dart';

@QueryHandlerFor(ListTenantMeasurementUnitsQuery)
final class ListTenantMeasurementUnitsQueryHandler
    implements IQueryHandler<ListTenantMeasurementUnitsQuery, List<TenantMeasurementUnitDto>> {
  ListTenantMeasurementUnitsQueryHandler({
    required ICatalogUnitGateway unitGateway,
    ListTenantMeasurementUnitsQueryValidator? validator,
  }) : _unitGateway = unitGateway,
       _validator = validator ?? ListTenantMeasurementUnitsQueryValidator();

  final ICatalogUnitGateway _unitGateway;
  final ListTenantMeasurementUnitsQueryValidator _validator;

  @override
  Future<List<TenantMeasurementUnitDto>> handle(
    ListTenantMeasurementUnitsQuery query,
  ) async {
    await _validator.validate(query);
    return _unitGateway.listTenantUnits(
      tenantId: query.tenantId,
      keyword: query.keyword,
      limit: query.limit,
    );
  }
}
