import 'package:vet45_iam_application/application.dart';

/// In-memory invitation identity port for unit tests (§S8).
final class FakeInvitationIdentityPort implements IInvitationIdentityPort {
  FakeInvitationIdentityPort({
    this.existingEmails = const {},
    this.onRegister,
  });

  final Set<String> existingEmails;
  Future<String> Function({
    required String inviteeEmail,
    required InvitationRegistrationProfileInput profile,
    required String credentialProof,
  })?
  onRegister;

  @override
  Future<String> registerVerifiedFromInvitation({
    required String inviteeEmail,
    required InvitationRegistrationProfileInput profile,
    required String credentialProof,
  }) async {
    if (onRegister != null) {
      return onRegister!(
        inviteeEmail: inviteeEmail,
        profile: profile,
        credentialProof: credentialProof,
      );
    }
    final email = inviteeEmail.trim().toLowerCase();
    if (existingEmails.contains(email)) {
      throw const IamBlockedException(IamBlockedCodes.platformUserAlreadyExists);
    }
    return 'user-$email';
  }
}
