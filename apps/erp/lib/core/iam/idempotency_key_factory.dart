import 'package:uuid/uuid.dart';

/// Creates idempotency keys scoped to a user intent.
abstract interface class IdempotencyKeyFactory {
  String next(String intent);
}

/// Production factory: `'$intent-<uuid-v4>'`.
final class UuidIdempotencyKeyFactory implements IdempotencyKeyFactory {
  const UuidIdempotencyKeyFactory();

  static const Uuid _uuid = Uuid();

  @override
  String next(String intent) => '$intent-${_uuid.v4()}';
}
