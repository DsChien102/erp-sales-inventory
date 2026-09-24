/// Owner step input for tenant onboarding wizard (EP-01/US-03).
///
/// Use [OnboardingOwnerInput.existing] or [OnboardingOwnerInput.newUser].
final class OnboardingOwnerInput {
  const OnboardingOwnerInput._({
    this.existingUserId,
    this.lastName,
    this.firstName,
    this.email,
    this.phone,
  });

  /// Select an existing Platform User as first Owner.
  const OnboardingOwnerInput.existing(String userId) : this._(existingUserId: userId);

  /// Mời email mới làm Owner đầu tiên của Tenant (không cần mật khẩu).
  /// Chỉ tạo Platform User và Owner Membership sau khi chấp nhận lời mời.
  const OnboardingOwnerInput.newUser({
    required String lastName,
    required String firstName,
    required String email,
    String? phone,
  }) : this._(
         lastName: lastName,
         firstName: firstName,
         email: email,
         phone: phone,
       );

  final String? existingUserId;
  final String? lastName;
  final String? firstName;
  final String? email;
  final String? phone;

  bool get isExisting => existingUserId != null;
  bool get isNewUser => email != null && existingUserId == null;
}
