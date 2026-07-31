import 'package:supabase/supabase.dart';

/// Auth identity primitives for invitation registration (no SDK types leak).
final class InvitationAuthIdentity {
  const InvitationAuthIdentity({
    required this.userId,
    required this.canonicalEmail,
    required this.emailVerified,
    required this.hasSession,
  });

  final String userId;
  final String canonicalEmail;
  final bool emailVerified;
  final bool hasSession;
}

enum InvitationAuthFailureKind { duplicate, validation, unavailable }

/// Infrastructure-only auth failure — never carries credentialProof.
final class InvitationAuthFailure implements Exception {
  const InvitationAuthFailure(this.kind, {this.message});

  final InvitationAuthFailureKind kind;
  final String? message;

  @override
  String toString() => 'InvitationAuthFailure($kind)';
}

abstract interface class InvitationAuthClient {
  Future<InvitationAuthIdentity> createAccount({
    required String email,
    required String credentialProof,
    required String givenName,
    required String familyName,
    required String? phone,
  });
}

final class SupabaseInvitationAuthClient implements InvitationAuthClient {
  SupabaseInvitationAuthClient(this._supabase);

  final SupabaseClient _supabase;

  @override
  Future<InvitationAuthIdentity> createAccount({
    required String email,
    required String credentialProof,
    required String givenName,
    required String familyName,
    required String? phone,
  }) async {
    try {
      final response = await _supabase.auth.signUp(
        email: email,
        password: credentialProof,
        data: <String, dynamic>{
          'first_name': givenName,
          'last_name': familyName,
          'phone': ?phone,
        },
      );
      final user = response.user;
      if (user == null) {
        throw const InvitationAuthFailure(InvitationAuthFailureKind.unavailable);
      }
      return InvitationAuthIdentity(
        userId: user.id,
        canonicalEmail: (user.email ?? '').trim().toLowerCase(),
        emailVerified: user.emailConfirmedAt != null,
        hasSession: response.session != null,
      );
    } on InvitationAuthFailure {
      rethrow;
    } on AuthException catch (error) {
      throw mapInvitationAuthException(error);
    } catch (_) {
      throw const InvitationAuthFailure(InvitationAuthFailureKind.unavailable);
    }
  }
}

InvitationAuthFailure mapInvitationAuthException(AuthException error) {
  const duplicateCodes = <String>{
    'email_exists',
    'user_already_exists',
  };
  const validationCodes = <String>{
    'weak_password',
    'validation_failed',
    'email_address_invalid',
  };

  final code = error.code?.trim().toLowerCase();
  if (code != null && duplicateCodes.contains(code)) {
    return const InvitationAuthFailure(
      InvitationAuthFailureKind.duplicate,
    );
  }
  if (code != null && validationCodes.contains(code)) {
    return const InvitationAuthFailure(
      InvitationAuthFailureKind.validation,
    );
  }
  if (code != null && code.isNotEmpty) {
    return const InvitationAuthFailure(
      InvitationAuthFailureKind.unavailable,
    );
  }

  final message = error.message.toLowerCase();
  if (message.contains('already') || message.contains('registered') || message.contains('exists')) {
    return const InvitationAuthFailure(
      InvitationAuthFailureKind.duplicate,
    );
  }
  if (message.contains('password') || message.contains('weak') || message.contains('invalid')) {
    return const InvitationAuthFailure(
      InvitationAuthFailureKind.validation,
    );
  }
  return const InvitationAuthFailure(
    InvitationAuthFailureKind.unavailable,
  );
}
