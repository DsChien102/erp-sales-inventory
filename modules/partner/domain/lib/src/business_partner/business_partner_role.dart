import '../shared/partner_role.dart';
import 'package:vet45_shared_domain/shared_kernel_domain.dart';

final class BusinessPartnerRole extends Entity<PartnerRole> {
  BusinessPartnerRole({
    required PartnerRole role,
    this.isActive = true,
    DateTime? createdAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        super(id: role);

  final bool isActive;
  final DateTime createdAt;
}
