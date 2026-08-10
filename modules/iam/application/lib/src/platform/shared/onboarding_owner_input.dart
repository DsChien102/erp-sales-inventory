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
  const OnboardingOwnerInput.existing(String userId)
    : this._(existingUserId: userId);

  /// Create a pending Platform User as first Owner (no password).
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
