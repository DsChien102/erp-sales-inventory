enum MemberStatus {
  active,
  suspended,
  removed,
}

enum InvitationStatus {
  pending,
  expiring,
  failed,
}

final class MemberUiModel {
  final String id;
  final String name;
  final String email;
  final String role;
  final MemberStatus status;
  final String identityText;
  final String joinedDate;
  final String lastActiveDate;
  final String dataVersion;
  final String? suspendedAt;
  final String? suspendedBy;
  final String? removedAt;
  final String? removedBy;
  final String? previousRole;

  const MemberUiModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.status,
    this.identityText = 'Chỉ đọc',
    this.joinedDate = '12/07/2026',
    this.lastActiveDate = '14/07/2026 · 09:18',
    this.dataVersion = 'v8',
    this.suspendedAt = '14/07/2026 · 09:30',
    this.suspendedBy = 'Lê Thị Lan',
    this.removedAt = '14/07/2026 · 09:45',
    this.removedBy = 'Lê Thị Lan',
    this.previousRole = 'Nhân viên bán hàng',
  });
}

final class InvitationUiModel {
  final String id;
  final String email;
  final String role;
  final String statusDetail;
  final InvitationStatus status;

  const InvitationUiModel({
    required this.id,
    required this.email,
    required this.role,
    required this.statusDetail,
    required this.status,
  });
}
