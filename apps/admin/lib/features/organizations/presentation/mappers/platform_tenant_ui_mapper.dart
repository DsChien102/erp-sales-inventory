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

  static OrganizationUiModel fromDetail(PlatformTenantDetailDto dto) {
    return OrganizationUiModel(
      id: dto.tenantId,
      name: dto.name,
      code: dto.code,
      status: toOrganizationStatus(dto.status),
      ownerName: dto.ownerName,
      ownerEmail: dto.ownerEmail,
      ownerRole: dto.ownerRoleLabel,
      createdAt: dto.createdAt,
      activatedAt: dto.activatedAt,
      suspendedAt: dto.suspendedAt,
      suspendedBy: dto.suspendedBy,
      suspendReason: dto.suspendReason,
      closedAt: dto.closedAt,
      closedBy: dto.closedBy,
      closeReason: dto.closeReason,
      members: dto.members
          .map(
            (m) => OrganizationMemberUiModel(
              id: m.userId,
              name: m.fullName,
              email: m.email,
              role: m.roleLabel,
            ),
          )
          .toList(),
    );
  }
}
