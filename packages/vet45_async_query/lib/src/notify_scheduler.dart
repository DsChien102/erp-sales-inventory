/// Batches observer notifications within the same event loop turn.
class NotifyScheduler {
  NotifyScheduler();

  final _pending = <void Function()>[];
  bool _scheduled = false;

  void schedule(void Function() callback) {
    _pending.add(callback);
    if (_scheduled) return;
    _scheduled = true;
    Future<void>.microtask(_flush);
  }

  void _flush() {
    _scheduled = false;
    final callbacks = List<void Function()>.from(_pending);
    _pending.clear();
    for (final callback in callbacks) {
      callback();
    }
  }

  void dispose() {
    _pending.clear();
    _scheduled = false;
  }
}
