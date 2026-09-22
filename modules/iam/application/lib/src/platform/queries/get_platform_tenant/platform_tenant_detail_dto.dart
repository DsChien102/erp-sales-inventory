import 'package:vet45_iam_domain/domain.dart';

import '../../shared/platform_tenant_member_dto.dart';

/// Platform tenant detail read-model (EP-02/US-08).
final class PlatformTenantDetailDto {
  const PlatformTenantDetailDto({
    required this.tenantId,
    required this.name,
    required this.code,
    required this.status,
    required this.createdAt,
    this.version = 1,
    this.ownerUserId,
    this.ownerName,
    this.ownerEmail,
    this.ownerRoleLabel = 'Chủ cửa hàng',
    this.activatedAt,
    this.lastActivityAt,
    this.suspendedAt,
    this.suspendedBy,
    this.suspendReason,
    this.closedAt,
    this.closedBy,
    this.closeReason,
    this.members = const [],
    this.unverifiedEmail = false,
    this.incompleteProfile = false,
    this.ownerInvitationEmail,
    this.ownerInvitationState,
    this.ownerInvitationExpiresAt,
    this.ownerInvitationGivenName,
    this.ownerInvitationFamilyName,
    this.ownerInvitationPhone,
  });

  final String tenantId;
  final String name;
  final String code;
  final TenantLifecycleStatus status;
  final DateTime createdAt;
  final int version;
  final String? ownerUserId;
  final String? ownerName;
  final String? ownerEmail;
  final String ownerRoleLabel;
  final DateTime? activatedAt;
  final DateTime? lastActivityAt;
  final DateTime? suspendedAt;
  final String? suspendedBy;
  final String? suspendReason;
  final DateTime? closedAt;
  final String? closedBy;
  final String? closeReason;
  final List<PlatformTenantMemberDto> members;
  final bool unverifiedEmail;
  final bool incompleteProfile;
  final String? ownerInvitationEmail;
  final String? ownerInvitationState;
  final DateTime? ownerInvitationExpiresAt;
  final String? ownerInvitationGivenName;
  final String? ownerInvitationFamilyName;
  final String? ownerInvitationPhone;
}
