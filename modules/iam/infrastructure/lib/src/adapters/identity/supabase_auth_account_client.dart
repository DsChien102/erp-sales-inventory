import 'package:supabase/supabase.dart';

/// Current authenticated account, exposed as primitives (no SDK types leak).
abstract interface class AuthAccountClient {
  String? get currentUserId;

  String? get currentEmail;

  bool get isEmailVerified;

  /// Triggers a Supabase Auth recovery OTP (six-digit code) to [email].
  /// Any previously issued code is invalidated by the provider.
  Future<void> sendRecoveryOtp({required String email});

  /// Verifies a recovery OTP. The raw [code] is passed straight to the SDK and
  /// is never logged or persisted.
  Future<void> verifyRecoveryOtp({
    required String email,
    required String code,
  });

  /// Updates the current user's password via Supabase Auth.
  Future<void> updatePassword(String newPassword);

  /// Revokes all OTHER sessions, retaining the current one.
  Future<void> signOutOtherSessions();
}

/// Thin wrapper over Supabase Auth for the current authenticated account.
///
/// Keeps Supabase SDK types out of the IAM application port: only primitive
/// values (user id, email, verified flag) cross this boundary. Password /
/// recovery OTP / session operations are added in Task 5.
final class SupabaseAuthAccountClient implements AuthAccountClient {
  SupabaseAuthAccountClient(this._supabase);

  final SupabaseClient _supabase;

  @override
  String? get currentUserId => _supabase.auth.currentUser?.id;

  @override
  String? get currentEmail => _supabase.auth.currentUser?.email;

  @override
  bool get isEmailVerified =>
      _supabase.auth.currentUser?.emailConfirmedAt != null;

  @override
  Future<void> sendRecoveryOtp({required String email}) {
    return _supabase.auth.resetPasswordForEmail(email);
  }

  @override
  Future<void> verifyRecoveryOtp({
    required String email,
    required String code,
  }) async {
    await _supabase.auth.verifyOTP(
      type: OtpType.recovery,
      email: email,
      token: code,
    );
  }

  @override
  Future<void> updatePassword(String newPassword) async {
    await _supabase.auth.updateUser(UserAttributes(password: newPassword));
  }

  @override
  Future<void> signOutOtherSessions() {
    return _supabase.auth.signOut(scope: SignOutScope.others);
  }
}
