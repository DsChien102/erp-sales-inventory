/// Platform User self-service profile read model (§S14).
final class MyAccountDto {
  const MyAccountDto({
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
}
