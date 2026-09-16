import 'package:vet45_adapters/vet45_adapters.dart';
import 'package:vet45_einvoice_application/application.dart';
import 'package:vet45_shared_infrastructure/infrastructure.dart';

import '../../errors/einvoice_error_mapper.dart';
import 'publish_series_lease_rpc_mapper.dart';

final class SupabasePublishSeriesLeaseGateway
    implements IPublishSeriesLeaseGateway {
  SupabasePublishSeriesLeaseGateway({
    required SupabaseSchemaRpcClient rpcClient,
  }) : _rpcClient = rpcClient;

  final SupabaseSchemaRpcClient _rpcClient;

  static const defaultLeaseSeconds = 300;

  @override
  Future<PublishSeriesLeaseAcquireOutcome> tryAcquire({
    required String tenantId,
    required String attemptId,
    required String ownerToken,
  }) async {
    try {
      final rows = await _rpcClient.callList(
        'acquire_publish_series_lease',
        params: PublishSeriesLeaseRpcMapper.acquireParams(
          tenantId: tenantId,
          attemptId: attemptId,
          ownerToken: ownerToken,
          leaseSeconds: defaultLeaseSeconds,
        ),
      );
      if (rows.isEmpty) {
        throw RpcException('acquire_publish_series_lease returned no rows');
      }
      return PublishSeriesLeaseRpcMapper.acquireOutcomeFromRow(rows.first);
    } on RpcException catch (error) {
      throw mapEinvoiceRpcError(error);
    }
  }

  @override
  Future<PublishSeriesLeaseRenewOutcome> renew({
    required String tenantId,
    required String providerConnectionId,
    required String invoiceSeries,
    required String ownerToken,
    required int leaseVersion,
  }) async {
    try {
      final rows = await _rpcClient.callList(
        'renew_publish_series_lease',
        params: PublishSeriesLeaseRpcMapper.renewParams(
          tenantId: tenantId,
          providerConnectionId: providerConnectionId,
          invoiceSeries: invoiceSeries,
          ownerToken: ownerToken,
          leaseVersion: leaseVersion,
          leaseSeconds: defaultLeaseSeconds,
        ),
      );
      if (rows.isEmpty) {
        throw RpcException('renew_publish_series_lease returned no rows');
      }
      return PublishSeriesLeaseRpcMapper.renewOutcomeFromRow(rows.first);
    } on RpcException catch (error) {
      throw mapEinvoiceRpcError(error);
    }
  }

  @override
  Future<void> release({
    required String tenantId,
    required String providerConnectionId,
    required String invoiceSeries,
    required String ownerToken,
    required int leaseVersion,
  }) async {
    try {
      await _rpcClient.callScalar<Object?>(
        'release_publish_series_lease',
        params: PublishSeriesLeaseRpcMapper.releaseParams(
          tenantId: tenantId,
          providerConnectionId: providerConnectionId,
          invoiceSeries: invoiceSeries,
          ownerToken: ownerToken,
          leaseVersion: leaseVersion,
        ),
      );
    } on RpcException catch (error) {
      throw mapEinvoiceRpcError(error);
    }
  }
}
