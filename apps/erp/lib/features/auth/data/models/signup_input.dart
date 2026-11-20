/// Bước tài khoản của wizard đăng ký cửa hàng.
final class SignupAccountInput {
  const SignupAccountInput({
    required this.givenName,
    required this.familyName,
    required this.email,
    required this.password,
    required this.confirmPassword,
    this.phone,
  });

  final String givenName;
  final String familyName;
  final String email;
  final String password;
  final String confirmPassword;
  final String? phone;

  Map<String, dynamic> toProfileMetadata() {
    final trimmedPhone = phone?.trim();
    return <String, dynamic>{
      'given_name': givenName.trim(),
      'family_name': familyName.trim(),
      if (trimmedPhone != null && trimmedPhone.isNotEmpty) 'phone': trimmedPhone,
    };
  }
}

/// Bước cửa hàng. Metadata gửi kèm `auth.signUp`, chưa tạo tổ chức.
final class SignupStoreInput {
  const SignupStoreInput({
    required this.name,
    required this.contactPhone,
    required this.provinceCode,
    required this.communeCode,
    required this.addressText,
    this.contactEmail = '',
  });

  final String name;
  final String contactPhone;
  final String provinceCode;
  final String communeCode;
  final String addressText;
  final String contactEmail;

  Map<String, dynamic> toMetadata({required String fallbackEmail}) {
    final email = contactEmail.trim().isEmpty ? fallbackEmail : contactEmail.trim().toLowerCase();
    return <String, dynamic>{
      'name': name.trim(),
      'contact_phone': contactPhone.trim(),
      'contact_email': email,
      'province_code': provinceCode.trim(),
      'commune_code': communeCode.trim(),
      'address_text': addressText.trim(),
    };
  }
}
