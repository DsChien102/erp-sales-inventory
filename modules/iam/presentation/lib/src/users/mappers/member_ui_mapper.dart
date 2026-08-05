import 'package:vet45_iam_application/application.dart';
import 'package:vet45_iam_domain/domain.dart';

import '../models/user_ui_model.dart';
import 'iam_date_formatter.dart';

abstract final class MemberUiMapper {
  static MemberUiModel fromSummary(TenantMemberDto dto) {
    return MemberUiModel(
      id: dto.membershipId,
      name: dto.displayName,
      email: dto.email,
      role: dto.roleLabel,
      status: _status(dto.status),
      isOwner: dto.isOwner,
      identityText: dto.isOwner ? 'Chủ sở hữu' : 'Thành viên',
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
    return MemberUiModel(
      id: dto.membershipId,
      name: dto.userId,
      email: '',
      role: dto.role,
      status: switch (dto.status) {
        MembershipStatus.active => MemberStatus.active,
        MembershipStatus.inactive => MemberStatus.suspended,
        MembershipStatus.removed => MemberStatus.removed,
      },
      isOwner: dto.isOwner,
      identityText: dto.isOwner ? 'Chủ sở hữu' : 'Thành viên',
      joinedDate: IamDateFormatter.formatDate(dto.joinedAt),
      lastActiveDate: '',
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
