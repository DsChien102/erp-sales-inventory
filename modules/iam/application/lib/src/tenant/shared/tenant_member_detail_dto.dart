import 'package:vet45_iam_domain/domain.dart';

/// Detail row for a single TenantMembership.
final class TenantMemberDetailDto {
  const TenantMemberDetailDto({
    required this.membershipId,
    required this.tenantId,
    required this.userId,
    required this.role,
    required this.isOwner,
    required this.isSoleOwner,
    required this.status,
    required this.version,
    required this.joinedAt,
    this.statusChangedAt,
    this.removedAt,
  });

  final String membershipId;
  final String tenantId;
  final String userId;
  final String role;
  final bool isOwner;
  final bool isSoleOwner;
  final MembershipStatus status;
  final int version;
  final DateTime joinedAt;
  final DateTime? statusChangedAt;
  final DateTime? removedAt;
}
