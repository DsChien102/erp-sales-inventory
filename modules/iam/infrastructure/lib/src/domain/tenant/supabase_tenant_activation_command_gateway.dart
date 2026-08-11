import 'package:vet45_adapters/vet45_adapters.dart';
import 'package:vet45_iam_application/application.dart';
import 'package:vet45_iam_domain/domain.dart';
import 'package:vet45_shared_infrastructure/infrastructure.dart';

import '../../errors/iam_blocked_error_mapper.dart';

final class SupabaseTenantActivationCommandGateway
    implements ITenantActivationCommandGateway {
  SupabaseTenantActivationCommandGateway({
    required SupabaseSchemaRpcClient rpcClient,
  }) : _rpcClient = rpcClient;

  final SupabaseSchemaRpcClient _rpcClient;

  @override
  Future<TenantActivationResultDto> activate({
    required String tenantId,
    required int expectedVersion,
    required String idempotencyKey,
  }) async {
    try {
      final result = await _rpcClient.callMap(
        'activate_tenant',
        params: <String, dynamic>{
          'p_tenant_id': tenantId,
          'p_expected_version': expectedVersion,
          'p_idempotency_key': idempotencyKey,
        },
      );
      return TenantActivationResultDto(
        tenantId: result['tenant_id'] as String,
        status: _mapLifecycle(result['status'] as String?),
        activatedAt: DateTime.parse(result['activated_at'] as String),
        version: (result['version'] as num?)?.toInt() ?? 1,
      );
    } on RpcException catch (error) {
      throw mapIamBlockedRpcError(error);
    }
  }
}

TenantLifecycleStatus _mapLifecycle(String? raw) {
  return switch (raw) {
    'provisioning' => TenantLifecycleStatus.provisioning,
    'suspended' => TenantLifecycleStatus.suspended,
    'closed' => TenantLifecycleStatus.closed,
    _ => TenantLifecycleStatus.active,
  };
}
