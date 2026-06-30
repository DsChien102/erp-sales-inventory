import 'package:vet45_adapters/vet45_adapters.dart';
import 'package:vet45_iam_application/application.dart';
import 'package:vet45_shared_infrastructure/infrastructure.dart';

import '../../errors/iam_error_mapper.dart';

final class SupabaseIamAccessGateway implements IIamAccessGateway {
  SupabaseIamAccessGateway({
    required SupabaseSchemaRpcClient rpcClient,
  }) : _rpcClient = rpcClient;

  final SupabaseSchemaRpcClient _rpcClient;

  @override
  Future<PrincipalAccessDto?> getSessionContext({String? tenantId}) async {
    try {
      final result = await _rpcClient.callMap(
        'get_session_context',
        params: tenantId == null
            ? null
            : <String, dynamic>{'p_tenant_id': tenantId},
      );

      if (result.isEmpty) {
        return null;
      }

      return _mapPrincipalAccess(result);
    } on RpcException catch (error) {
      throw mapIamRpcError(error);
    }
  }

  @override
  Future<List<TenantMembershipDto>> listUserTenants() async {
    try {
      final rows = await _rpcClient.callList('list_user_tenants');
      return rows
          .map(
            (row) => TenantMembershipDto(
              tenantId: row['tenant_id'] as String,
              name: row['name'] as String,
              role: row['role'] as String,
            ),
          )
          .toList(growable: false);
    } on RpcException catch (error) {
      throw mapIamRpcError(error);
    }
  }

  @override
  Future<bool> hasPermission({
    required String tenantId,
    required String permission,
  }) async {
    try {
      final result = await _rpcClient.callScalar<bool>(
        'has_permission',
        params: <String, dynamic>{
          'p_tenant_id': tenantId,
          'p_permission': permission,
        },
      );
      return result ?? false;
    } on RpcException catch (error) {
      throw mapIamRpcError(error);
    }
  }

  @override
  Future<bool> isMember(String tenantId) async {
    final context = await getSessionContext(tenantId: tenantId);
    return context != null;
  }

  @override
  Future<String> bootstrapOwner({String tenantName = 'My Store'}) async {
    try {
      final tenantId = await _rpcClient.callScalar<String>(
        'bootstrap_owner',
        params: <String, dynamic>{'p_tenant_name': tenantName},
      );
      if (tenantId == null) {
        throw RpcException('bootstrap_owner returned null tenant id');
      }
      return tenantId;
    } on RpcException catch (error) {
      throw mapIamRpcError(error);
    }
  }

  PrincipalAccessDto _mapPrincipalAccess(Map<String, dynamic> json) {
    final permissionsRaw = json['permissions'];
    final permissions = switch (permissionsRaw) {
      final List<dynamic> list => list.map((e) => e as String).toList(),
      _ => const <String>[],
    };

    return PrincipalAccessDto(
      userId: json['user_id'] as String,
      tenantId: json['tenant_id'] as String,
      role: json['role'] as String,
      permissions: permissions,
    );
  }
}
