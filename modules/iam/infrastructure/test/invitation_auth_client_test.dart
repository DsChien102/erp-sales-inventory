import 'package:supabase/supabase.dart';
import 'package:test/test.dart';
import 'package:vet45_iam_infrastructure/src/adapters/invitation/invitation_auth_client.dart';

void main() {
  group('mapInvitationAuthException', () {
    test('email_exists maps to duplicate', () {
      final failure = mapInvitationAuthException(
        const AuthException(
          'Email already registered',
          statusCode: '422',
          code: 'email_exists',
        ),
      );
      expect(failure.kind, InvitationAuthFailureKind.duplicate);
    });

    test('user_already_exists maps to duplicate', () {
      final failure = mapInvitationAuthException(
        const AuthException(
          'User already exists',
          statusCode: '422',
          code: 'user_already_exists',
        ),
      );
      expect(failure.kind, InvitationAuthFailureKind.duplicate);
    });

    test('weak_password remains validation even with status 422', () {
      final failure = mapInvitationAuthException(
        const AuthException(
          'Password is too weak',
          statusCode: '422',
          code: 'weak_password',
        ),
      );
      expect(failure.kind, InvitationAuthFailureKind.validation);
    });

    test('unknown 422 is unavailable instead of duplicate', () {
      final failure = mapInvitationAuthException(
        const AuthException(
          'Provider rejected signup',
          statusCode: '422',
          code: 'unexpected_provider_error',
        ),
      );
      expect(failure.kind, InvitationAuthFailureKind.unavailable);
    });

    test('legacy response without code falls back to message', () {
      expect(
        mapInvitationAuthException(
          const AuthException('Email already registered', statusCode: '422'),
        ).kind,
        InvitationAuthFailureKind.duplicate,
      );
      expect(
        mapInvitationAuthException(
          const AuthException('Password is invalid', statusCode: '422'),
        ).kind,
        InvitationAuthFailureKind.validation,
      );
    });
  });
}
