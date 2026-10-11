import 'package:erp/core/iam/iam_codes.dart';
import 'package:erp/core/session/models/session_snapshot.dart';

import '../../../core/iam/iam_load_status.dart';
import '../../../core/iam/iam_ui_failure.dart';

final class IamFeatureAccessState {
  const IamFeatureAccessState({
    this.status = IamLoadStatus.initial,
    this.session,
    this.failure,
  });

  final IamLoadStatus status;
  final SessionSnapshot? session;
  final IamUiFailure? failure;

  bool _has(String code) => session?.hasPermission(code) ?? false;

  bool get canViewMembers => _has(IamPermissions.memberView);
  bool get canInviteMembers => _has(IamPermissions.memberInvite);
  bool get canUpdateMemberStatus => _has(IamPermissions.memberStatusUpdate);
  bool get canRemoveMember => _has(IamPermissions.memberRemove);
  bool get canViewTenantProfile => _has(IamPermissions.tenantView);
  bool get canUpdateTenantProfile => _has(IamPermissions.tenantProfileUpdate);
  bool get canUpdateLegalProfile => _has(IamPermissions.tenantLegalProfileUpdate);
  bool get canViewTenantAudit => _has(IamPermissions.tenantAuditView);

  /// Hub quản trị tổ chức chỉ dành cho chủ sở hữu.
  bool get canOpenIamHub => session?.isOwner ?? false;

  IamFeatureAccessState copyWith({
    IamLoadStatus? status,
    SessionSnapshot? session,
    IamUiFailure? failure,
    bool clearFailure = false,
    bool clearSession = false,
  }) {
    return IamFeatureAccessState(
      status: status ?? this.status,
      session: clearSession ? null : (session ?? this.session),
      failure: clearFailure ? null : (failure ?? this.failure),
    );
  }
}
