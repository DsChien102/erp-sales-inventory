import 'package:uuid/uuid.dart';

/// Factory generating client-side idempotency keys (RefID) for E-Invoice commands.
class OrderEInvoiceIdempotencyKeyFactory {
  const OrderEInvoiceIdempotencyKeyFactory();

  /// Generates a standard UUID v4 plain string.
  String next() => const Uuid().v4();
}

/// Deterministic key factory for tests.
class DeterministicOrderEInvoiceIdempotencyKeyFactory
    implements OrderEInvoiceIdempotencyKeyFactory {
  DeterministicOrderEInvoiceIdempotencyKeyFactory(List<String> keys) : _keys = List.of(keys);

  final List<String> _keys;
  int _index = 0;

  @override
  String next() {
    if (_index < _keys.length) {
      return _keys[_index++];
    }
    return 'deterministic-key-${_index++}';
  }
}
