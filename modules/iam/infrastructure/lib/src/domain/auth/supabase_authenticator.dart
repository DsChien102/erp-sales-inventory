import 'package:supabase/supabase.dart';

import 'package:vet45_iam_application/application.dart';

final class SupabaseAuthenticator implements IAuthenticator {
  SupabaseAuthenticator(this._supabase);

  final SupabaseClient _supabase;

  @override
  String? get currentEmail => _supabase.auth.currentUser?.email;

  @override
  String? get currentUserId => _supabase.auth.currentUser?.id;

  @override
  AuthSessionState get sessionState {
    final session = _supabase.auth.currentSession;
    if (session == null) {
      return AuthSessionState.absent;
    }
    return session.isExpired ? AuthSessionState.expired : AuthSessionState.active;
  }

  @override
  Future<void> signIn({
    required String email,
    required String password,
  }) {
    return _supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  @override
  Future<void> signOut() {
    return _supabase.auth.signOut();
  }
}
