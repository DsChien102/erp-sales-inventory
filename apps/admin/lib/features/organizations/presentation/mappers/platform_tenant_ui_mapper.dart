import 'package:vet45_iam_application/application.dart';
import 'package:vet45_iam_domain/domain.dart';
import 'package:vet45_iam_presentation/presentation.dart';

/// Maps platform tenant DTOs to presentation UI models.
abstract final class PlatformTenantUiMapper {
  static OrganizationStatus toOrganizationStatus(TenantLifecycleStatus status) {
    return switch (status) {
      TenantLifecycleStatus.provisioning => OrganizationStatus.settingUp,
      TenantLifecycleStatus.active => OrganizationStatus.active,
      TenantLifecycleStatus.suspended => OrganizationStatus.suspended,
      TenantLifecycleStatus.closed => OrganizationStatus.closed,
    };
  }

  static OrganizationUiModel fromSummary(PlatformTenantSummaryDto dto) {
    return OrganizationUiModel(
      id: dto.tenantId,
      name: dto.name,
      code: dto.code,
      status: toOrganizationStatus(dto.status),
      ownerName: dto.ownerName,
      ownerEmail: dto.ownerEmail,
      createdAt: dto.createdAt,
      members: List.generate(
        dto.memberCount.clamp(0, 0),
        (_) => const OrganizationMemberUiModel(id: '', name: ''),
      ),
    );
  }

  static String _normalizeRoleLabel(String? roleLabel) {
    if (roleLabel == null || roleLabel.isEmpty) return 'Chủ sở hữu';
    if (roleLabel.toLowerCase() == 'owner') return 'Chủ sở hữu';
    return IamRoleLabelMapper.toDisplayLabel(roleLabel);
  }

  static OrganizationUiModel fromDetail(PlatformTenantDetailDto dto) {
    final isSettingUp = dto.status == TenantLifecycleStatus.provisioning;
    return OrganizationUiModel(
      id: dto.tenantId,
      name: dto.name,
      code: dto.code,
      status: toOrganizationStatus(dto.status),
      ownerUserId: dto.ownerUserId,
      ownerName: dto.ownerName,
      ownerEmail: dto.ownerEmail,
      ownerRole: _normalizeRoleLabel(dto.ownerRoleLabel),
      unverifiedEmail: dto.unverifiedEmail || (isSettingUp && (dto.ownerEmail == null || dto.ownerEmail!.isEmpty || dto.ownerUserId == null)),
      incompleteProfile: dto.incompleteProfile || isSettingUp,
      createdAt: dto.createdAt,
      activatedAt: dto.activatedAt,
      lastActiveAt: dto.lastActivityAt,
      suspendedAt: dto.suspendedAt,
      suspendedBy: dto.suspendedBy,
      suspendReason: dto.suspendReason,
      closedAt: dto.closedAt,
      closedBy: dto.closedBy,
      closeReason: dto.closeReason,
      dataVersion: 'v${dto.version}',
      members: dto.members
          .map(
            (m) => OrganizationMemberUiModel(
              id: m.userId,
              name: m.fullName,
              email: m.email,
              role: _normalizeRoleLabel(m.roleLabel),
              isOwner: m.isOwner,
            ),
          )
          .toList(),
    );
  }
}
