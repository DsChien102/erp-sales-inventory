import 'platform_user_membership_dto.dart';
import 'platform_user_status.dart';

/// Platform User detail read-model (EP-01/US-01 FR-03/FR-04).
final class PlatformUserDetailDto {
  const PlatformUserDetailDto({
    required this.userId,
    required this.fullName,
    required this.email,
    required this.status,
    required this.emailVerified,
    required this.createdAt,
    this.version = 1,
    this.emailVerifiedAt,
    this.lastLoginAt,
    this.activationExpiresAt,
    this.memberships = const [],
  });

  final String userId;
  final String fullName;
  final String email;
  final PlatformUserStatus status;
  final bool emailVerified;

  /// Thời điểm email được xác minh (`auth.users.email_confirmed_at`); null nếu
  /// chưa xác minh.
  final DateTime? emailVerifiedAt;
  final DateTime createdAt;
  final int version;
  final DateTime? lastLoginAt;

  /// Hạn kích hoạt email của owner đang chờ (từ lời mời owner còn hiệu lực);
  /// null nếu tài khoản không ở trạng thái chờ kích hoạt.
  final DateTime? activationExpiresAt;
  final List<PlatformUserMembershipDto> memberships;
}
