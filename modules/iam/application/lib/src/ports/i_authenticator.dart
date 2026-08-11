import '../authentication/shared/auth_session_state.dart';

/// Supabase Auth credential verification (infrastructure implements).
abstract interface class IAuthenticator {
  AuthSessionState get sessionState;

  Future<void> signIn({required String email, required String password});

  Future<void> signOut();

  String? get currentUserId;

  String? get currentEmail;
}
