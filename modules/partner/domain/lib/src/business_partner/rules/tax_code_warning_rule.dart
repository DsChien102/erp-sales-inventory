import '../../shared/entity_type.dart';
import '../../value_objects/tax_code.dart';

final class TaxCodeWarningRule {
  const TaxCodeWarningRule({
    required this.entityType,
    required this.taxCode,
  });

  final EntityType entityType;
  final TaxCode? taxCode;

  bool get isWarning =>
      (entityType == EntityType.householdBusiness ||
          entityType == EntityType.company) &&
      taxCode == null;
}
