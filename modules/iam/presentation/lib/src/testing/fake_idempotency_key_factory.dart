import 'package:vet45_iam_presentation/src/shared/idempotency_key_factory.dart';

/// Deterministic [IdempotencyKeyFactory] for tests.
final class FakeIdempotencyKeyFactory implements IdempotencyKeyFactory {
  FakeIdempotencyKeyFactory([this.value = 'test-idempotency-key']);

  final String value;
  int calls = 0;

  @override
  String next(String intent) {
    calls += 1;
    return '$intent-$value';
  }
}
