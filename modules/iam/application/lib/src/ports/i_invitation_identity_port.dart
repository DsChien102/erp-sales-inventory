import '../invitation/shared/invitation_registration_profile_input.dart';

/// Identity side of invitation registration (§S8).
///
/// Creates a verified Platform User from invitation email proof.
/// `accountExists` is decided solely by [InspectInvitationTokenQuery]/rpc.
abstract interface class IInvitationIdentityPort {
  /// Creates identity with [inviteeEmail] verified; returns new userId.
  Future<String> registerVerifiedFromInvitation({
    required String inviteeEmail,
    required InvitationRegistrationProfileInput profile,
    required String credentialProof,
  });
}
