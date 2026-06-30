/// Supabase Auth credential verification (infrastructure implements).
abstract interface class IAuthenticator {
  Future<void> signIn({required String email, required String password});

  Future<void> signOut();

  String? get currentUserId;

  String? get currentEmail;
}
