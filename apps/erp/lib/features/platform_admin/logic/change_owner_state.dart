import 'package:erp/core/iam/iam_load_status.dart';
import 'package:erp/core/iam/iam_ui_failure.dart';

import '../data/models/platform_tenant.dart';

final class ChangeOwnerState {
  const ChangeOwnerState({
    this.status = IamLoadStatus.initial,
    this.detail,
    this.members = const [],
    this.query = '',
    this.selectedUserId,
    this.isSubmitting = false,
    this.completed = false,
    this.failure,
  });

  final IamLoadStatus status;
  final PlatformTenantDetail? detail;

  /// Mọi thành viên đang hoạt động, gồm cả Owner hiện tại (hiện mờ ở C5).
  final List<PlatformTenantMember> members;
  final String query;
  final String? selectedUserId;
  final bool isSubmitting;

  /// Chuyển Owner thành công; trang đóng và báo "Đã chuyển quyền sở hữu."
  final bool completed;
  final IamUiFailure? failure;

  PlatformTenantMember? get currentOwner {
    final ownerId = detail?.ownerUserId;
    for (final member in members) {
      if (member.isOwner || (ownerId != null && member.userId == ownerId)) return member;
    }
    return null;
  }

  bool _isCandidate(PlatformTenantMember member) {
    final ownerId = detail?.ownerUserId;
    return !member.isOwner && (ownerId == null || member.userId != ownerId);
  }

  List<PlatformTenantMember> get candidates =>
      members.where(_isCandidate).toList(growable: false);

  /// Ứng viên khớp [query] theo tên hoặc email.
  List<PlatformTenantMember> get filteredCandidates {
    final needle = query.trim().toLowerCase();
    if (needle.isEmpty) return candidates;
    return candidates
        .where(
          (member) =>
              member.fullName.toLowerCase().contains(needle) ||
              member.email.toLowerCase().contains(needle),
        )
        .toList(growable: false);
  }

  PlatformTenantMember? get selected {
    final id = selectedUserId;
    if (id == null) return null;
    for (final member in candidates) {
      if (member.userId == id) return member;
    }
    return null;
  }

  ChangeOwnerState copyWith({
    IamLoadStatus? status,
    PlatformTenantDetail? detail,
    List<PlatformTenantMember>? members,
    String? query,
    String? selectedUserId,
    bool? isSubmitting,
    bool? completed,
    IamUiFailure? failure,
    bool clearSelection = false,
    bool clearFailure = false,
  }) {
    return ChangeOwnerState(
      status: status ?? this.status,
      detail: detail ?? this.detail,
      members: members ?? this.members,
      query: query ?? this.query,
      selectedUserId: clearSelection ? null : (selectedUserId ?? this.selectedUserId),
      isSubmitting: isSubmitting ?? this.isSubmitting,
      completed: completed ?? this.completed,
      failure: clearFailure ? null : (failure ?? this.failure),
    );
  }
}
