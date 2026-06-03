import 'package:fpdart/fpdart.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'failure.dart';

/// Maps Supabase/Postgres errors to [Failure] for the domain layer.
Failure mapExceptionToFailure(Object error, [StackTrace? stackTrace]) {
  if (error is AuthException) {
    return AuthFailure(error.message);
  }

  if (error is PostgrestException) {
    final message = error.message;
    final code = error.code ?? '';

    if (code == 'PGRST301' || message.toLowerCase().contains('jwt')) {
      return AuthFailure(message);
    }

    final lower = message.toLowerCase();
    if (lower.contains('idempotency') && lower.contains('mismatch')) {
      return IdempotencyMismatchFailure(message);
    }
    if (lower.contains('idempotency') &&
        (lower.contains('in progress') || lower.contains('progress'))) {
      return IdempotencyInProgressFailure(message);
    }
    if (lower.contains('not found') || lower.contains('does not exist')) {
      return NotFoundFailure(message);
    }

    return ValidationFailure(message);
  }

  if (error is Failure) {
    return error;
  }

  return UnknownFailure(error.toString());
}

Future<Either<Failure, T>> guard<T>(Future<T> Function() run) async {
  try {
    return Right(await run());
  } catch (e, st) {
    return Left(mapExceptionToFailure(e, st));
  }
}
