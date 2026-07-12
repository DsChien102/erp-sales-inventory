import 'package:vet45_shared_application/application.dart';

import 'list_tenant_measurement_units_query.dart';

final class ListTenantMeasurementUnitsQueryValidator
    implements ICommandValidator<ListTenantMeasurementUnitsQuery> {
  @override
  Future<void> validate(ListTenantMeasurementUnitsQuery query) async {
    if (query.tenantId.trim().isEmpty) {
      throw ValidationException('Tenant id is required.');
    }
    if (query.limit < 1 || query.limit > 100) {
      throw ValidationException('Limit must be between 1 and 100.');
    }
  }
}
