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
    this.lastLoginAt,
    this.memberships = const [],
  });

  final String userId;
  final String fullName;
  final String email;
  final PlatformUserStatus status;
  final bool emailVerified;
  final DateTime createdAt;
  final int version;
  final DateTime? lastLoginAt;
  final List<PlatformUserMembershipDto> memberships;
}
