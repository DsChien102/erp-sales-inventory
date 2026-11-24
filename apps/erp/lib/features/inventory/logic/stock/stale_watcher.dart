class StaleWatcher {
  final DateTime Function() _now;
  final Duration limit;

  const StaleWatcher({
    DateTime Function() now = DateTime.now,
    this.limit = const Duration(minutes: 5),
  }) : _now = now;

  bool isStale(DateTime asOf) => _now().difference(asOf) > limit;
}

