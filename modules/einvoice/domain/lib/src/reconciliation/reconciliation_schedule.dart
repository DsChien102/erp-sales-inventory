/// Schedule and limits for provider reconciliation poll cadence.
abstract final class ReconciliationSchedule {
  /// Maximum number of reconciliation check attempts before marking unresolved.
  static const int maxChecks = 5;

  /// Returns the duration to wait before executing [checkSequence] (1-based index 1..5).
  ///
  /// Throws [RangeError] if [checkSequence] is less than 1 or greater than [maxChecks].
  static Duration delayBeforeCheck(int checkSequence) {
    if (checkSequence < 1 || checkSequence > maxChecks) {
      throw RangeError.range(
        checkSequence,
        1,
        maxChecks,
        'checkSequence',
        'checkSequence must be between 1 and $maxChecks inclusive.',
      );
    }

    return switch (checkSequence) {
      1 => const Duration(seconds: 30),
      2 => const Duration(minutes: 2),
      3 => const Duration(minutes: 10),
      4 => const Duration(minutes: 30),
      5 => const Duration(hours: 2),
      _ => throw RangeError.range(checkSequence, 1, maxChecks, 'checkSequence'),
    };
  }

  /// Whether the reconciliation process should transition to unresolved
  /// after [completedChecks] check attempts have completed without definitive result.
  static bool shouldMarkUnresolved(int completedChecks) {
    return completedChecks >= maxChecks;
  }
}
