import '../../../../core/errors/result.dart';
import '../repositories/auth_repository.dart';

class SignInUseCase {
  SignInUseCase(this._repository);

  final AuthRepository _repository;

  ResultFuture<void> call({
    required String email,
    required String password,
  }) {
    return _repository.signInWithPassword(email: email, password: password);
  }
}
