import '../../../../core/errors/result.dart';
import '../repositories/auth_repository.dart';

class SignOutUseCase {
  SignOutUseCase(this._repository);

  final AuthRepository _repository;

  ResultFuture<void> call() => _repository.signOut();
}
