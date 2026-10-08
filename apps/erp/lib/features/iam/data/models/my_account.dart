/// Hồ sơ tự phục vụ. Cột RPC + email / trạng thái xác minh từ Supabase Auth.
final class MyAccount {
  const MyAccount({
    required this.userId,
    required this.email,
    required this.givenName,
    required this.familyName,
    required this.phone,
    required this.emailVerified,
    this.avatarReference,
  });

  final String userId;
  final String email;
  final String givenName;
  final String familyName;
  final String? phone;
  final bool emailVerified;
  final String? avatarReference;

  /// Tên (cột `given_name`).
  String get firstName => givenName;

  /// Họ và tên đệm (cột `family_middle_name`).
  String get lastName => familyName;

  String? get phoneNumber => phone;

  String? get avatarUrl => avatarReference;

  String get fullName => '$familyName $givenName'.trim();

  factory MyAccount.fromProfileRow(
    Map<String, dynamic> row, {
    required String email,
    required bool emailVerified,
  }) {
    return MyAccount(
      userId: row['user_id'] as String,
      email: email,
      givenName: row['given_name'] as String? ?? '',
      familyName: row['family_middle_name'] as String? ?? '',
      phone: row['phone_number'] as String?,
      emailVerified: emailVerified,
      avatarReference: row['avatar_reference'] as String?,
    );
  }
}
