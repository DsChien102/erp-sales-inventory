import 'package:test/test.dart';
import 'package:vet45_iam_application/application.dart';
import 'package:vet45_iam_infrastructure/src/adapters/invitation/invitation_auth_client.dart';
import 'package:vet45_iam_infrastructure/src/adapters/invitation/supabase_invitation_identity_adapter.dart';
import 'package:vet45_iam_infrastructure/src/domain/platform_user/supabase_platform_user_profile_gateway.dart';

void main() {
  group('SupabaseInvitationIdentityAdapter', () {
    test('happy path creates verified account and syncs profile', () async {
      final auth = _FakeAuthClient(
        identity: const InvitationAuthIdentity(
          userId: 'user-1',
          canonicalEmail: 'a@example.com',
          emailVerified: true,
          hasSession: true,
        ),
      );
      final profiles = _FakeProfileGateway();
      final adapter = SupabaseInvitationIdentityAdapter(
        authClient: auth,
        profileGateway: profiles,
      );

      final userId = await adapter.registerVerifiedFromInvitation(
        inviteeEmail: 'a@example.com',
        profile: const InvitationRegistrationProfileInput(
          givenName: 'An',
          familyName: 'Nguyen',
          phone: '+84901111111',
        ),
        credentialProof: 'SecretPass1!',
      );

      expect(userId, 'user-1');
      expect(profiles.lastUpdate?.givenName, 'An');
      expect(profiles.lastUpdate?.familyName, 'Nguyen');
      expect(auth.lastEmail, 'a@example.com');
    });

    test('canonical email mismatch fails closed', () async {
      final adapter = SupabaseInvitationIdentityAdapter(
        authClient: _FakeAuthClient(
          identity: const InvitationAuthIdentity(
            userId: 'user-1',
            canonicalEmail: 'other@example.com',
            emailVerified: true,
            hasSession: true,
          ),
        ),
        profileGateway: _FakeProfileGateway(),
      );

      expect(
        () => adapter.registerVerifiedFromInvitation(
          inviteeEmail: 'a@example.com',
          profile: const InvitationRegistrationProfileInput(
            givenName: 'An',
            familyName: 'Nguyen',
          ),
          credentialProof: 'SecretPass1!',
        ),
        throwsA(
          isA<IamBlockedException>().having(
            (e) => e.code,
            'code',
            IamBlockedCodes.systemError,
          ),
        ),
      );
    });

    test('missing session / unverified email fail SYSTEM_ERROR', () async {
      Future<void> expectSystem(InvitationAuthIdentity identity) async {
        final adapter = SupabaseInvitationIdentityAdapter(
          authClient: _FakeAuthClient(identity: identity),
          profileGateway: _FakeProfileGateway(),
        );
        await expectLater(
          () => adapter.registerVerifiedFromInvitation(
            inviteeEmail: 'a@example.com',
            profile: const InvitationRegistrationProfileInput(
              givenName: 'An',
              familyName: 'Nguyen',
            ),
            credentialProof: 'SecretPass1!',
          ),
          throwsA(
            isA<IamBlockedException>().having(
              (e) => e.code,
              'code',
              IamBlockedCodes.systemError,
            ),
          ),
        );
      }

      await expectSystem(
        const InvitationAuthIdentity(
          userId: 'u1',
          canonicalEmail: 'a@example.com',
          emailVerified: true,
          hasSession: false,
        ),
      );
      await expectSystem(
        const InvitationAuthIdentity(
          userId: 'u1',
          canonicalEmail: 'a@example.com',
          emailVerified: false,
          hasSession: true,
        ),
      );
    });

    test('maps duplicate / validation / provider failures', () async {
      Future<void> expectMapped(
        InvitationAuthFailureKind kind,
        String code,
      ) async {
        final adapter = SupabaseInvitationIdentityAdapter(
          authClient: _FakeAuthClient(failure: InvitationAuthFailure(kind)),
          profileGateway: _FakeProfileGateway(),
        );
        await expectLater(
          () => adapter.registerVerifiedFromInvitation(
            inviteeEmail: 'a@example.com',
            profile: const InvitationRegistrationProfileInput(
              givenName: 'An',
              familyName: 'Nguyen',
            ),
            credentialProof: 'SecretPass1!',
          ),
          throwsA(
            isA<IamBlockedException>().having((e) => e.code, 'code', code),
          ),
        );
      }

      await expectMapped(
        InvitationAuthFailureKind.duplicate,
        IamBlockedCodes.platformUserAlreadyExists,
      );
      await expectMapped(
        InvitationAuthFailureKind.validation,
        IamBlockedCodes.validationError,
      );
      await expectMapped(
        InvitationAuthFailureKind.unavailable,
        IamBlockedCodes.systemError,
      );
    });

    test('profile failure maps SYSTEM_ERROR and never leaks credential', () async {
      const secret = 'SecretPass1!';
      final adapter = SupabaseInvitationIdentityAdapter(
        authClient: _FakeAuthClient(
          identity: const InvitationAuthIdentity(
            userId: 'user-1',
            canonicalEmail: 'a@example.com',
            emailVerified: true,
            hasSession: true,
          ),
        ),
        profileGateway: _FakeProfileGateway(fail: true),
      );

      try {
        await adapter.registerVerifiedFromInvitation(
          inviteeEmail: 'a@example.com',
          profile: const InvitationRegistrationProfileInput(
            givenName: 'An',
            familyName: 'Nguyen',
          ),
          credentialProof: secret,
        );
        fail('expected exception');
      } on IamBlockedException catch (error) {
        expect(error.code, IamBlockedCodes.systemError);
        expect(error.toString(), isNot(contains(secret)));
        expect(error.message ?? '', isNot(contains(secret)));
      }
    });
  });
}

final class _FakeAuthClient implements InvitationAuthClient {
  _FakeAuthClient({this.identity, this.failure});

  final InvitationAuthIdentity? identity;
  final InvitationAuthFailure? failure;
  String? lastEmail;

  @override
  Future<InvitationAuthIdentity> createAccount({
    required String email,
    required String credentialProof,
    required String givenName,
    required String familyName,
    required String? phone,
  }) async {
    lastEmail = email;
    if (failure != null) throw failure!;
    return identity!;
  }
}

final class _FakeProfileGateway implements PlatformUserProfileGateway {
  _FakeProfileGateway({this.fail = false});

  final bool fail;
  ({String givenName, String familyName, String? phone})? lastUpdate;

  @override
  Future<PlatformUserProfileSnapshot> getMyProfile() {
    throw UnimplementedError();
  }

  @override
  Future<PlatformUserProfileSnapshot> updateMyProfile({
    required String? avatarReference,
    required String givenName,
    required String familyName,
    required String? phone,
  }) async {
    if (fail) throw StateError('profile sync failed');
    lastUpdate = (givenName: givenName, familyName: familyName, phone: phone);
    return PlatformUserProfileSnapshot(
      userId: 'user-1',
      givenName: givenName,
      familyMiddleName: familyName,
      phoneNumber: phone,
      avatarReference: avatarReference,
      status: 'active',
    );
  }
}
