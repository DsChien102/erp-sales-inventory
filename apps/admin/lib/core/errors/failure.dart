/// Application-level failures for repository/use case boundaries.
sealed class Failure {
  const Failure(this.message);

  final String message;
}

final class AuthFailure extends Failure {
  const AuthFailure([super.message = 'Authentication required']);
}

final class ValidationFailure extends Failure {
  const ValidationFailure(super.message);
}

final class IdempotencyMismatchFailure extends Failure {
  const IdempotencyMismatchFailure([
    super.message = 'Idempotency key reused with different request',
  ]);
}

final class IdempotencyInProgressFailure extends Failure {
  const IdempotencyInProgressFailure([
    super.message = 'Request with this idempotency key is still in progress',
  ]);
}

final class NotFoundFailure extends Failure {
  const NotFoundFailure([super.message = 'Resource not found']);
}

final class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'Network or server error']);
}

final class UnknownFailure extends Failure {
  const UnknownFailure([super.message = 'An unexpected error occurred']);
}
