import 'package:vet45_einvoice_application/application.dart';

/// In-memory lease for worker concurrency tests (single process, thread-safe enough for async Dart tests).
final class InMemoryPublishSeriesLeaseGateway
    implements IPublishSeriesLeaseGateway {
  InMemoryPublishSeriesLeaseGateway({
    this.leaseDuration = const Duration(minutes: 5),
    this.busyRetryAfter = const Duration(seconds: 5),
    String? Function(String attemptId)? attemptSeriesResolver,
    Map<String, String> attemptSeriesById = const {
      '1': '1C25TYY',
      '2': '1C25TYY',
      '3': '2K26TYY',
    },
  }) : _attemptSeriesResolver = attemptSeriesResolver,
       _attemptSeriesById = Map.unmodifiable(attemptSeriesById);

  final Duration leaseDuration;
  final Duration busyRetryAfter;
  final String? Function(String attemptId)? _attemptSeriesResolver;
  final Map<String, String> _attemptSeriesById;

  final Map<String, _LeaseRecord> _leases = {};
  int acquireCalls = 0;
  int releaseCalls = 0;

  String _key({
    required String tenantId,
    required String providerConnectionId,
    required String invoiceSeries,
  }) => '$tenantId|$providerConnectionId|$invoiceSeries';

  @override
  Future<PublishSeriesLeaseAcquireOutcome> tryAcquire({
    required String tenantId,
    required String attemptId,
    required String ownerToken,
  }) async {
    acquireCalls++;
    final providerConnectionId = 'conn-$tenantId';
    final invoiceSeries =
        _attemptSeriesResolver?.call(attemptId) ??
        _attemptSeriesById[attemptId];
    if (invoiceSeries == null) {
      throw StateError(
        'Missing immutable series fixture for attempt $attemptId',
      );
    }
    final key = _key(
      tenantId: tenantId,
      providerConnectionId: providerConnectionId,
      invoiceSeries: invoiceSeries,
    );
    final now = DateTime.now().toUtc();
    final existing = _leases[key];

    if (existing != null &&
        existing.leasedUntil.isAfter(now) &&
        existing.ownerToken != ownerToken) {
      return PublishSeriesLeaseBusy(retryAfter: busyRetryAfter);
    }

    final leaseVersion = switch (existing) {
      null => 1,
      _ when existing.ownerToken == ownerToken => existing.leaseVersion,
      _ => existing.leaseVersion + 1,
    };
    final leasedUntil = now.add(leaseDuration);
    _leases[key] = _LeaseRecord(
      ownerToken: ownerToken,
      leaseVersion: leaseVersion,
      leasedUntil: leasedUntil,
    );
    return PublishSeriesLeaseAcquired(
      providerConnectionId: providerConnectionId,
      invoiceSeries: invoiceSeries,
      leaseVersion: leaseVersion,
      leasedUntil: leasedUntil,
    );
  }

  @override
  Future<PublishSeriesLeaseRenewOutcome> renew({
    required String tenantId,
    required String providerConnectionId,
    required String invoiceSeries,
    required String ownerToken,
    required int leaseVersion,
  }) async {
    final key = _key(
      tenantId: tenantId,
      providerConnectionId: providerConnectionId,
      invoiceSeries: invoiceSeries,
    );
    final now = DateTime.now().toUtc();
    final existing = _leases[key];
    if (existing == null ||
        existing.ownerToken != ownerToken ||
        existing.leaseVersion != leaseVersion ||
        !existing.leasedUntil.isAfter(now)) {
      return const PublishSeriesLeaseLost();
    }
    final leasedUntil = now.add(leaseDuration);
    _leases[key] = _LeaseRecord(
      ownerToken: ownerToken,
      leaseVersion: leaseVersion,
      leasedUntil: leasedUntil,
    );
    return PublishSeriesLeaseRenewed(leasedUntil: leasedUntil);
  }

  @override
  Future<void> release({
    required String tenantId,
    required String providerConnectionId,
    required String invoiceSeries,
    required String ownerToken,
    required int leaseVersion,
  }) async {
    releaseCalls++;
    final key = _key(
      tenantId: tenantId,
      providerConnectionId: providerConnectionId,
      invoiceSeries: invoiceSeries,
    );
    final existing = _leases[key];
    if (existing == null ||
        existing.ownerToken != ownerToken ||
        existing.leaseVersion != leaseVersion) {
      return;
    }
    _leases[key] = _LeaseRecord(
      ownerToken: ownerToken,
      leaseVersion: leaseVersion,
      leasedUntil: DateTime.now().toUtc(),
    );
  }

  void expireLease({
    required String tenantId,
    required String providerConnectionId,
    required String invoiceSeries,
  }) {
    final key = _key(
      tenantId: tenantId,
      providerConnectionId: providerConnectionId,
      invoiceSeries: invoiceSeries,
    );
    final existing = _leases[key];
    if (existing == null) {
      return;
    }
    _leases[key] = _LeaseRecord(
      ownerToken: existing.ownerToken,
      leaseVersion: existing.leaseVersion,
      leasedUntil: DateTime.now().toUtc().subtract(const Duration(seconds: 1)),
    );
  }
}

final class _LeaseRecord {
  _LeaseRecord({
    required this.ownerToken,
    required this.leaseVersion,
    required this.leasedUntil,
  });

  final String ownerToken;
  final int leaseVersion;
  final DateTime leasedUntil;
}
