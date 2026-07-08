/// Tenant-level measurement unit for picker lists (EPIC-04/US-01).
final class TenantMeasurementUnitDto {
  const TenantMeasurementUnitDto({
    required this.id,
    required this.name,
    this.isActive = true,
  });

  final String id;
  final String name;
  final bool isActive;
}
