import 'package:vet45_adapters/vet45_adapters.dart';
import 'package:vet45_iam_application/application.dart';
import 'package:vet45_shared_infrastructure/infrastructure.dart';

import '../../errors/iam_error_mapper.dart';

/// Supabase adapter for [IPlatformUserPreferencePort] (LastSelectedTenant).
final class SupabasePlatformUserPreferencePort
    implements IPlatformUserPreferencePort {
  SupabasePlatformUserPreferencePort({
    required SupabaseSchemaRpcClient rpcClient,
  }) : _rpcClient = rpcClient;

  final SupabaseSchemaRpcClient _rpcClient;

  @override
  Future<String?> getLastSelectedTenantId() async {
    try {
      return await _rpcClient.callScalar<String>('get_last_selected_tenant');
    } on RpcException catch (error) {
      throw mapIamRpcError(error);
    }
  }

  @override
  Future<void> setLastSelectedTenantId(String? tenantId) async {
    try {
      await _rpcClient.callScalar<Object?>(
        'set_last_selected_tenant',
        params: <String, dynamic>{'p_tenant_id': tenantId},
      );
    } on RpcException catch (error) {
      throw mapIamRpcError(error);
    }
  }
}
