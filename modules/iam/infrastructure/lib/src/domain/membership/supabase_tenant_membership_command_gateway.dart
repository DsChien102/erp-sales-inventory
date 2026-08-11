import 'package:vet45_adapters/vet45_adapters.dart';
import 'package:vet45_iam_application/application.dart';
import 'package:vet45_shared_infrastructure/infrastructure.dart';

import '../../errors/iam_blocked_error_mapper.dart';
import 'supabase_tenant_membership_read_gateway.dart';

final class SupabaseTenantMembershipCommandGateway
    implements ITenantMembershipCommandGateway {
  SupabaseTenantMembershipCommandGateway({
    required SupabaseSchemaRpcClient rpcClient,
  }) : _rpcClient = rpcClient;

  final SupabaseSchemaRpcClient _rpcClient;

  @override
  Future<TenantMemberDetailDto> deactivate({
    required String tenantId,
    required String membershipId,
    required int expectedVersion,
  }) {
    return _mutate(
      'deactivate_membership',
      tenantId: tenantId,
      membershipId: membershipId,
      expectedVersion: expectedVersion,
    );
  }

  @override
  Future<TenantMemberDetailDto> reactivate({
    required String tenantId,
    required String membershipId,
    required int expectedVersion,
  }) {
    return _mutate(
      'reactivate_membership',
      tenantId: tenantId,
      membershipId: membershipId,
      expectedVersion: expectedVersion,
    );
  }

  @override
  Future<TenantMemberDetailDto> remove({
    required String tenantId,
    required String membershipId,
    required int expectedVersion,
  }) {
    return _mutate(
      'remove_membership',
      tenantId: tenantId,
      membershipId: membershipId,
      expectedVersion: expectedVersion,
    );
  }

  Future<TenantMemberDetailDto> _mutate(
    String rpc, {
    required String tenantId,
    required String membershipId,
    required int expectedVersion,
  }) async {
    try {
      final result = await _rpcClient.callMap(
        rpc,
        params: <String, dynamic>{
          'p_tenant_id': tenantId,
          'p_membership_id': membershipId,
          'p_expected_version': expectedVersion,
        },
      );
      return mapTenantMemberDetail(result);
    } on RpcException catch (error) {
      throw mapIamBlockedRpcError(error);
    }
  }
}
