/// Outcome of attempting to acquire a publish dispatch lease for one InvSeries.
sealed class PublishSeriesLeaseAcquireOutcome {
  const PublishSeriesLeaseAcquireOutcome();
}

final class PublishSeriesLeaseAcquired extends PublishSeriesLeaseAcquireOutcome {
  const PublishSeriesLeaseAcquired({
    required this.providerConnectionId,
    required this.invoiceSeries,
    required this.leaseVersion,
    required this.leasedUntil,
  });

  final String providerConnectionId;
  final String invoiceSeries;
  final int leaseVersion;
  final DateTime leasedUntil;
}

final class PublishSeriesLeaseBusy extends PublishSeriesLeaseAcquireOutcome {
  const PublishSeriesLeaseBusy({required this.retryAfter});

  final Duration retryAfter;
}

/// Outcome of renewing an already acquired fenced lease.
sealed class PublishSeriesLeaseRenewOutcome {
  const PublishSeriesLeaseRenewOutcome();
}

final class PublishSeriesLeaseRenewed extends PublishSeriesLeaseRenewOutcome {
  const PublishSeriesLeaseRenewed({required this.leasedUntil});

  final DateTime leasedUntil;
}

final class PublishSeriesLeaseLost extends PublishSeriesLeaseRenewOutcome {
  const PublishSeriesLeaseLost();
}

/// Durable cross-worker lease for serializing MISA publish per InvSeries.
abstract interface class IPublishSeriesLeaseGateway {
  Future<PublishSeriesLeaseAcquireOutcome> tryAcquire({
    required String tenantId,
    required String attemptId,
    required String ownerToken,
  });

  Future<PublishSeriesLeaseRenewOutcome> renew({
    required String tenantId,
    required String providerConnectionId,
    required String invoiceSeries,
    required String ownerToken,
    required int leaseVersion,
  });

  Future<void> release({
    required String tenantId,
    required String providerConnectionId,
    required String invoiceSeries,
    required String ownerToken,
    required int leaseVersion,
  });
}
