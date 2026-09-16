/// Raised when another worker holds the publish lease for the same InvSeries.
///
/// Worker processing must reschedule the internal command without incrementing
/// permanent failure counters or opening reconciliation.
final class PublishSeriesLeaseBusyException implements Exception {
  const PublishSeriesLeaseBusyException({required this.retryAfter});

  final Duration retryAfter;

  @override
  String toString() => 'PublishSeriesLeaseBusyException(retryAfter: ${retryAfter.inSeconds}s)';
}
