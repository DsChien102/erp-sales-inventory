import '../repositories/auth_repository.dart';

class GetAuthStateUseCase {
  GetAuthStateUseCase(this._repository);

  final AuthRepository _repository;

  AuthState call() => _repository.currentAuthState;
}
