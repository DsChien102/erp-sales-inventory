/// Presentation-safe identity profile for EP-06 My Account.
final class MyIdentityProfileDto {
  const MyIdentityProfileDto({
    required this.userId,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.emailVerified,
    this.phoneNumber,
    this.avatarUrl,
  });

  final String userId;

  /// Họ và tên đệm.
  final String firstName;

  /// Tên.
  final String lastName;

  final String email;
  final bool emailVerified;
  final String? phoneNumber;
  final String? avatarUrl;

  String get fullName => '$firstName $lastName'.trim();

  MyIdentityProfileDto copyWith({
    String? userId,
    String? firstName,
    String? lastName,
    String? email,
    bool? emailVerified,
    String? phoneNumber,
    String? avatarUrl,
  }) {
    return MyIdentityProfileDto(
      userId: userId ?? this.userId,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      emailVerified: emailVerified ?? this.emailVerified,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      avatarUrl: avatarUrl ?? this.avatarUrl,
    );
  }
}
