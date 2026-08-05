import 'package:supabase/supabase.dart';

/// Current authenticated account, exposed as primitives (no SDK types leak).
abstract interface class AuthAccountClient {
  String? get currentUserId;

  String? get currentEmail;

  bool get isEmailVerified;

  /// Updates the current user's password via Supabase Auth.
  Future<void> updatePassword(String newPassword);

  /// Revokes all OTHER sessions, retaining the current one.
  Future<void> signOutOtherSessions();
}

/// Thin wrapper over Supabase Auth for the current authenticated account.
///
/// Keeps Supabase SDK types out of the IAM application port: only primitive
/// values (user id, email, verified flag) cross this boundary. Password change
/// and session revocation go through Supabase Auth; the password-reset code
/// itself is owned by the IAM RPCs (not Supabase Auth recovery OTP).
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
  Future<void> updatePassword(String newPassword) async {
    await _supabase.auth.updateUser(UserAttributes(password: newPassword));
  }

  @override
  Future<void> signOutOtherSessions() {
    return _supabase.auth.signOut(scope: SignOutScope.others);
  }
}
