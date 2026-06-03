import '../../../../core/errors/result.dart';

class AuthState {
  const AuthState({
    required this.isAuthenticated,
    this.userId,
    this.email,
  });

  final bool isAuthenticated;
  final String? userId;
  final String? email;
}

abstract class AuthRepository {
  ResultFuture<void> signInWithPassword({
    required String email,
    required String password,
  });

  ResultFuture<void> signOut();

  AuthState get currentAuthState;
}
