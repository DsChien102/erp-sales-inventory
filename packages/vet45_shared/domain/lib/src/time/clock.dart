/// Abstraction for reading the current time in domain and application code.
abstract interface class IClock {
  DateTime now();
}

/// Production [IClock] backed by the system clock.
final class SystemClock implements IClock {
  const SystemClock();

  @override
  DateTime now() => DateTime.now();
}
