/// Profile fields for RegisterFromInvitationCommand (§S8).
///
/// Email is locked to invitation invitee — not accepted from client.
final class InvitationRegistrationProfileInput {
  const InvitationRegistrationProfileInput({
    required this.givenName,
    required this.familyName,
    this.phone,
  });

  final String givenName;
  final String familyName;
  final String? phone;
}
