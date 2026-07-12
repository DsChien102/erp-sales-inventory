import 'package:vet45_shared_application/application.dart';

import 'package:vet45_catalog_application/src/ports/i_catalog_unit_gateway.dart';
import 'check_duplicate_measurement_unit_name_query.dart';
import 'check_duplicate_measurement_unit_name_query_validator.dart';

@QueryHandlerFor(CheckDuplicateMeasurementUnitNameQuery)
final class CheckDuplicateMeasurementUnitNameQueryHandler
    implements IQueryHandler<CheckDuplicateMeasurementUnitNameQuery, bool> {
  CheckDuplicateMeasurementUnitNameQueryHandler({
    required ICatalogUnitGateway unitGateway,
    CheckDuplicateMeasurementUnitNameQueryValidator? validator,
  }) : _unitGateway = unitGateway,
       _validator = validator ?? CheckDuplicateMeasurementUnitNameQueryValidator();

  final ICatalogUnitGateway _unitGateway;
  final CheckDuplicateMeasurementUnitNameQueryValidator _validator;

  @override
  Future<bool> handle(CheckDuplicateMeasurementUnitNameQuery query) async {
    await _validator.validate(query);
    return _unitGateway.isDuplicateUnitName(
      tenantId: query.tenantId,
      name: query.name,
    );
  }
}
