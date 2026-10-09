import '../../../iam/data/iam_json.dart';

/// Xem trước lời mời (`inspect_invitation_token`). Không trả về khi mã không hợp lệ.
final class InvitationTokenInspection {
  const InvitationTokenInspection({
    required this.tenantId,
    required this.tenantName,
    required this.inviteeEmail,
    required this.initialRoleId,
    required this.initialRoleLabel,
    required this.expiresAt,
    required this.accountExists,
    this.givenName,
    this.familyName,
    this.phone,
  });

  final String tenantId;
  final String tenantName;
  final String inviteeEmail;
  final String initialRoleId;
  final String initialRoleLabel;
  final DateTime expiresAt;
  final bool accountExists;
  final String? givenName;
  final String? familyName;
  final String? phone;

  factory InvitationTokenInspection.fromJson(Map<String, dynamic> json) {
    return InvitationTokenInspection(
      tenantId: json['tenant_id'] as String,
      tenantName: (json['tenant_name'] as String?) ?? '',
      inviteeEmail: json['invitee_email'] as String,
      initialRoleId: json['initial_role_id'] as String,
      initialRoleLabel: (json['initial_role_label'] as String?) ?? '',
      expiresAt: iamTimestamp(json['expires_at'])!,
      accountExists: json['account_exists'] as bool? ?? false,
      givenName: json['given_name'] as String?,
      familyName: json['family_name'] as String?,
      phone: json['phone'] as String?,
    );
  }
}
