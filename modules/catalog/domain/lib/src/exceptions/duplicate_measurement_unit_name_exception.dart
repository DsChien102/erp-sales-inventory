import 'package:vet45_shared_domain/shared_kernel_domain.dart';

/// Thrown when a measurement unit name already exists in the tenant.
final class DuplicateMeasurementUnitNameException extends DomainException {
  DuplicateMeasurementUnitNameException({
    required this.name,
    this.existingUnitId,
  }) : super('Đơn vị "$name" đã tồn tại trong tenant.');

  final String name;
  final String? existingUnitId;
}
