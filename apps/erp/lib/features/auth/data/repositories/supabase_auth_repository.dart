import '../../../../core/errors/exception_mapper.dart';
import '../../../../core/errors/result.dart';
import '../../../../core/supabase/supabase_module.dart';
import '../../domain/repositories/auth_repository.dart';

class SupabaseAuthRepository implements AuthRepository {
  SupabaseAuthRepository(this._supabase);

  final SupabaseModule _supabase;

  @override
  ResultFuture<void> signInWithPassword({
    required String email,
    required String password,
  }) {
    return guard(() async {
      await _supabase.client.auth.signInWithPassword(
        email: email,
        password: password,
      );
    });
  }

  @override
  ResultFuture<void> signOut() {
    return guard(() async {
      await _supabase.client.auth.signOut();
    });
  }

  @override
  AuthState get currentAuthState {
    final session = _supabase.client.auth.currentSession;
    final user = session?.user;
    return AuthState(
      isAuthenticated: user != null,
      userId: user?.id,
      email: user?.email,
    );
  }
}
