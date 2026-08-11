import 'package:vet45_adapters/vet45_adapters.dart';
import 'package:vet45_iam_application/application.dart';
import 'package:vet45_iam_domain/domain.dart';
import 'package:vet45_shared_infrastructure/infrastructure.dart';

import '../../errors/iam_blocked_error_mapper.dart';

final class SupabaseTenantReadinessGateway implements ITenantReadinessGateway {
  SupabaseTenantReadinessGateway({
    required SupabaseSchemaRpcClient rpcClient,
  }) : _rpcClient = rpcClient;

  final SupabaseSchemaRpcClient _rpcClient;

  @override
  Future<TenantReadinessDto> getReadiness({required String tenantId}) async {
    try {
      final result = await _rpcClient.callMap(
        'get_tenant_readiness',
        params: <String, dynamic>{'p_tenant_id': tenantId},
      );
      return _mapReadiness(result);
    } on RpcException catch (error) {
      throw mapIamBlockedRpcError(error);
    }
  }

  TenantReadinessDto _mapReadiness(Map<String, dynamic> row) {
    return TenantReadinessDto(
      tenantId: row['tenant_id'] as String,
      status: _mapLifecycle(row['status'] as String?),
      blockers: _mapStringList(row['blockers']),
      warnings: _mapStringList(row['warnings']),
      evaluatedAt: DateTime.parse(row['evaluated_at'] as String),
      tenantVersion: (row['tenant_version'] as num?)?.toInt() ?? 1,
      canActivate: row['can_activate'] as bool? ?? false,
    );
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

List<String> _mapStringList(Object? raw) {
  if (raw is! List) {
    return const [];
  }
  return raw.map((e) => e.toString()).toList();
}
