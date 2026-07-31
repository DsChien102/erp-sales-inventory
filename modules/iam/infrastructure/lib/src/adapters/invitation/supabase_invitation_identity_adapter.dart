import 'package:vet45_iam_application/application.dart';

import '../../domain/platform_user/supabase_platform_user_profile_gateway.dart';
import 'invitation_auth_client.dart';

/// Registers a verified invitation account via Auth + IAM profile sync (§S8).
final class SupabaseInvitationIdentityAdapter
    implements IInvitationIdentityPort {
  SupabaseInvitationIdentityAdapter({
    required InvitationAuthClient authClient,
    required PlatformUserProfileGateway profileGateway,
  }) : _authClient = authClient,
       _profileGateway = profileGateway;

  final InvitationAuthClient _authClient;
  final PlatformUserProfileGateway _profileGateway;

  @override
  Future<String> registerVerifiedFromInvitation({
    required String inviteeEmail,
    required InvitationRegistrationProfileInput profile,
    required String credentialProof,
  }) async {
    final canonicalInvite = inviteeEmail.trim().toLowerCase();
    try {
      final identity = await _authClient.createAccount(
        email: canonicalInvite,
        credentialProof: credentialProof,
        givenName: profile.givenName.trim(),
        familyName: profile.familyName.trim(),
        phone: profile.phone?.trim(),
      );

      if (!identity.hasSession || !identity.emailVerified) {
        throw const IamBlockedException(IamBlockedCodes.systemError);
      }
      if (identity.canonicalEmail != canonicalInvite) {
        throw const IamBlockedException(IamBlockedCodes.systemError);
      }

      await _profileGateway.updateMyProfile(
        avatarReference: null,
        givenName: profile.givenName.trim(),
        familyName: profile.familyName.trim(),
        phone: profile.phone?.trim(),
      );

      return identity.userId;
    } on IamBlockedException {
      rethrow;
    } on InvitationAuthFailure catch (error) {
      throw switch (error.kind) {
        InvitationAuthFailureKind.duplicate =>
          const IamBlockedException(IamBlockedCodes.platformUserAlreadyExists),
        InvitationAuthFailureKind.validation =>
          const IamBlockedException(IamBlockedCodes.validationError),
        InvitationAuthFailureKind.unavailable =>
          const IamBlockedException(IamBlockedCodes.systemError),
      };
    } catch (_) {
      throw const IamBlockedException(IamBlockedCodes.systemError);
    }
  }
}
