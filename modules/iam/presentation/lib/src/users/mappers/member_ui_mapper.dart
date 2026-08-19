import 'package:vet45_iam_application/application.dart';
import 'package:vet45_iam_domain/domain.dart';

import '../models/user_ui_model.dart';
import 'iam_date_formatter.dart';

abstract final class MemberUiMapper {
  static MemberUiModel fromSummary(TenantMemberDto dto) {
    return MemberUiModel(
      id: dto.membershipId,
      name: dto.displayName.isNotEmpty
          ? dto.displayName
          : (dto.email.isNotEmpty ? dto.email : dto.userId),
      email: dto.email,
      role: dto.roleLabel.isNotEmpty ? dto.roleLabel : _roleLabel(dto.roleId),
      status: _status(dto.status),
      isOwner: dto.isOwner,
      identityText: dto.isOwner ? 'Chủ sở hữu' : 'Chỉ đọc',
      joinedDate: IamDateFormatter.formatDate(dto.joinedAt),
      lastActiveDate: '',
      dataVersion: 'v${dto.version}',
      suspendedAt: null,
      suspendedBy: null,
      removedAt: null,
      removedBy: null,
      previousRole: null,
    );
  }

  static MemberUiModel fromDetail(TenantMemberDetailDto dto) {
    final displayName = dto.displayName?.trim();
    final email = dto.email?.trim() ?? '';
    final name = (displayName != null && displayName.isNotEmpty)
        ? displayName
        : (email.isNotEmpty ? email : dto.userId);
    final role = (dto.roleLabel != null && dto.roleLabel!.trim().isNotEmpty)
        ? dto.roleLabel!.trim()
        : _roleLabel(dto.role);

    return MemberUiModel(
      id: dto.membershipId,
      name: name,
      email: email,
      role: role,
      status: switch (dto.status) {
        MembershipStatus.active => MemberStatus.active,
        MembershipStatus.inactive => MemberStatus.suspended,
        MembershipStatus.removed => MemberStatus.removed,
      },
      isOwner: dto.isOwner,
      identityText: dto.isOwner ? 'Chủ sở hữu' : 'Chỉ đọc',
      joinedDate: IamDateFormatter.formatDate(dto.joinedAt),
      lastActiveDate: dto.lastActivityAt != null
          ? IamDateFormatter.formatDateTime(dto.lastActivityAt!)
          : IamDateFormatter.formatDateTime(dto.joinedAt),
      dataVersion: 'v${dto.version}',
      suspendedAt: dto.statusChangedAt == null
          ? null
          : IamDateFormatter.formatDateTime(dto.statusChangedAt!),
      suspendedBy: null,
      removedAt: dto.removedAt == null
          ? null
          : IamDateFormatter.formatDateTime(dto.removedAt!),
      removedBy: null,
      previousRole: null,
    );
  }

  static String _roleLabel(String roleCode) {
    return switch (roleCode.toLowerCase()) {
      'owner' => 'Chủ sở hữu',
      'admin' => 'Quản trị viên',
      'staff' || 'sales' => 'Nhân viên bán hàng',
      'vet' || 'doctor' => 'Bác sĩ thú y',
      'technician' => 'Kỹ thuật viên',
      'accountant' => 'Kế toán',
      _ => roleCode,
    };
  }

  static MemberStatus _status(String wire) {
    return switch (wire) {
      'inactive' => MemberStatus.suspended,
      'removed' => MemberStatus.removed,
      _ => MemberStatus.active,
    };
  }
}
