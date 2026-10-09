import '../../../iam/data/models/tenant_member.dart';

/// Kết quả đăng ký từ lời mời rồi nhận.
final class InvitationRegistrationResult {
  const InvitationRegistrationResult({
    required this.userId,
    required this.membership,
  });

  final String userId;
  final TenantMemberDetail membership;
}
