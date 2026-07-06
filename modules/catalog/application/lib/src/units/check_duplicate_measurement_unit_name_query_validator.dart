import 'package:vet45_shared_application/application.dart';

import 'check_duplicate_measurement_unit_name_query.dart';

final class CheckDuplicateMeasurementUnitNameQueryValidator
    implements ICommandValidator<CheckDuplicateMeasurementUnitNameQuery> {
  static const int maxUnitNameLength = 80;

  @override
  Future<void> validate(CheckDuplicateMeasurementUnitNameQuery query) async {
    if (query.tenantId.trim().isEmpty) {
      throw ValidationException('Tenant id is required.');
    }
    final trimmed = query.name.trim();
    if (trimmed.isEmpty) {
      throw ValidationException('Unit name must not be empty.');
    }
    if (trimmed.length > maxUnitNameLength) {
      throw ValidationException('Unit name is too long.');
    }
  }
}
