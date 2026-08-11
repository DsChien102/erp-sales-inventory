import 'platform_user_status.dart';

/// List-row DTO for platform user search (EP-01/US-01).
final class PlatformUserSummaryDto {
  const PlatformUserSummaryDto({
    required this.userId,
    required this.fullName,
    required this.email,
    required this.status,
    required this.createdAt,
  });

  final String userId;
  final String fullName;
  final String email;
  final PlatformUserStatus status;
  final DateTime createdAt;
}
