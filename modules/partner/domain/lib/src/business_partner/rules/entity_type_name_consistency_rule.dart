import '../../shared/entity_type.dart';
import '../../value_objects/partner_name.dart';
import 'package:vet45_shared_domain/shared_kernel_domain.dart';

final class EntityTypeNameConsistencyRule implements IBusinessRule {
  EntityTypeNameConsistencyRule({
    required EntityType entityType,
    required PartnerName? individualName,
    required PartnerName? businessName,
    required PartnerName? companyName,
  })  : _entityType = entityType,
        _individualName = individualName,
        _businessName = businessName,
        _companyName = companyName;

  final EntityType _entityType;
  final PartnerName? _individualName;
  final PartnerName? _businessName;
  final PartnerName? _companyName;

  @override
  bool isBroken() {
    return switch (_entityType) {
      EntityType.individual => _individualName == null,
      EntityType.householdBusiness => _businessName == null,
      EntityType.company => _companyName == null,
    };
  }

  @override
  String get message => 'Entity type specific name is required.';
}
