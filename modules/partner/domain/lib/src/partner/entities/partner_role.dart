import 'package:vet45_shared_domain/shared_kernel_domain.dart';

import '../../enums/partner_role_type.dart';

/// Trading role assignment within the Partner aggregate.
final class PartnerRole extends ValueObject {
  const PartnerRole({
    required this.role,
    this.isActive = true,
  });

  final PartnerRoleType role;
  final bool isActive;

  @override
  List<Object?> get props => [role, isActive];
}
