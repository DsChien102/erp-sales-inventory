import 'package:vet45_einvoice_application/application.dart';
import 'package:vet45_shared_infrastructure/infrastructure.dart';

abstract final class PublishSeriesLeaseRpcMapper {
  static Map<String, dynamic> acquireParams({
    required String tenantId,
    required String attemptId,
    required String ownerToken,
    required int leaseSeconds,
  }) {
    return {
      'p_tenant_id': tenantId,
      'p_attempt_id': attemptId,
      'p_owner_token': ownerToken,
      'p_lease_seconds': leaseSeconds,
    };
  }

  static Map<String, dynamic> releaseParams({
    required String tenantId,
    required String providerConnectionId,
    required String invoiceSeries,
    required String ownerToken,
    required int leaseVersion,
  }) {
    return {
      'p_tenant_id': tenantId,
      'p_provider_connection_id': providerConnectionId,
      'p_invoice_series': invoiceSeries,
      'p_owner_token': ownerToken,
      'p_lease_version': leaseVersion,
    };
  }

  static Map<String, dynamic> renewParams({
    required String tenantId,
    required String providerConnectionId,
    required String invoiceSeries,
    required String ownerToken,
    required int leaseVersion,
    required int leaseSeconds,
  }) {
    return {
      'p_tenant_id': tenantId,
      'p_provider_connection_id': providerConnectionId,
      'p_invoice_series': invoiceSeries,
      'p_owner_token': ownerToken,
      'p_lease_version': leaseVersion,
      'p_lease_seconds': leaseSeconds,
    };
  }

  static PublishSeriesLeaseAcquireOutcome acquireOutcomeFromRow(
    Map<String, dynamic> row,
  ) {
    final acquired = row['acquired'] == true;
    if (!acquired) {
      final retryAfterSeconds = _positiveInt(row['retry_after_seconds']);
      if (retryAfterSeconds == null) {
        throw RpcException(
          'acquire_publish_series_lease missing retry_after_seconds',
        );
      }
      return PublishSeriesLeaseBusy(
        retryAfter: Duration(seconds: retryAfterSeconds),
      );
    }
    final providerConnectionId = row['provider_connection_id']?.toString();
    final invoiceSeries = row['invoice_series']?.toString();
    final leaseVersion = _positiveInt(row['lease_version']);
    final leasedUntil = _dateTime(row['leased_until']);
    if (providerConnectionId == null ||
        providerConnectionId.isEmpty ||
        invoiceSeries == null ||
        invoiceSeries.isEmpty ||
        leaseVersion == null ||
        leasedUntil == null) {
      throw RpcException(
        'acquire_publish_series_lease missing fenced lease metadata',
      );
    }
    return PublishSeriesLeaseAcquired(
      providerConnectionId: providerConnectionId,
      invoiceSeries: invoiceSeries,
      leaseVersion: leaseVersion,
      leasedUntil: leasedUntil,
    );
  }

  static PublishSeriesLeaseRenewOutcome renewOutcomeFromRow(
    Map<String, dynamic> row,
  ) {
    if (row['renewed'] != true) {
      return const PublishSeriesLeaseLost();
    }
    final leasedUntil = _dateTime(row['leased_until']);
    if (leasedUntil == null) {
      throw RpcException('renew_publish_series_lease missing leased_until');
    }
    return PublishSeriesLeaseRenewed(leasedUntil: leasedUntil);
  }

  static int? _positiveInt(Object? value) {
    final parsed = switch (value) {
      int number => number,
      num number => number.toInt(),
      String text => int.tryParse(text),
      _ => null,
    };
    return parsed != null && parsed > 0 ? parsed : null;
  }

  static DateTime? _dateTime(Object? value) {
    if (value is DateTime) {
      return value.toUtc();
    }
    if (value is String) {
      return DateTime.tryParse(value)?.toUtc();
    }
    return null;
  }
}
