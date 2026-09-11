import 'package:vet45_iam_application/application.dart';
import 'package:vet45_iam_domain/domain.dart';

import '../../shared/iam_role_label_mapper.dart';
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
      role: IamRoleLabelMapper.toDisplayLabel(
        dto.roleLabel.isNotEmpty ? dto.roleLabel : dto.roleId,
      ),
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
    final role = IamRoleLabelMapper.toDisplayLabel(
      (dto.roleLabel != null && dto.roleLabel!.trim().isNotEmpty)
          ? dto.roleLabel!.trim()
          : dto.role,
    );

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


  static MemberStatus _status(String wire) {
    return switch (wire) {
      'inactive' => MemberStatus.suspended,
      'removed' => MemberStatus.removed,
      _ => MemberStatus.active,
    };
  }
}
