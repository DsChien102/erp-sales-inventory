/// How to resolve the base unit when setting it on a product (EPIC-04/US-01).
sealed class BaseUnitSelection {
  const BaseUnitSelection();
}

/// Pick an existing tenant measurement unit by id.
final class ExistingTenantUnit extends BaseUnitSelection {
  const ExistingTenantUnit(this.unitId);

  final String unitId;
}

/// Quick-create a new tenant measurement unit by name.
final class NewTenantUnit extends BaseUnitSelection {
  const NewTenantUnit(this.name);

  final String name;
}
