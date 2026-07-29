/// Supabase Auth credential verification (infrastructure implements).
abstract interface class IAuthenticator {
  Future<void> signIn({required String email, required String password});

  Future<void> signOut();

  /// Updates the authenticated user's password (GoTrue `updateUser`).
  Future<void> updatePassword(String newPassword);

  String? get currentUserId;

  String? get currentEmail;
}
