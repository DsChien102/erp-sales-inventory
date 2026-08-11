import 'package:vet45_adapters/vet45_adapters.dart';
import 'package:vet45_iam_application/application.dart';
import 'package:vet45_shared_infrastructure/infrastructure.dart';

import '../../errors/iam_blocked_error_mapper.dart';

final class SupabaseAssignableInvitationRoleReadPort
    implements IAssignableInvitationRoleReadPort {
  SupabaseAssignableInvitationRoleReadPort({
    required SupabaseSchemaRpcClient rpcClient,
  }) : _rpcClient = rpcClient;

  final SupabaseSchemaRpcClient _rpcClient;

  @override
  Future<List<AssignableRoleOptionDto>> listAssignableRoles({
    required String tenantId,
  }) async {
    try {
      final rows = await _rpcClient.callList(
        'list_assignable_invitation_roles',
        params: <String, dynamic>{
          'p_tenant_id': tenantId,
        },
      );
      return rows
          .map((row) {
            final roleId = row['role_id'];
            final label = row['label'];
            return AssignableRoleOptionDto(
              roleId: roleId == null ? '' : roleId.toString(),
              label: label == null ? '' : label.toString(),
            );
          })
          .where((row) => row.roleId.isNotEmpty && row.label.isNotEmpty)
          .toList(growable: false);
    } on RpcException catch (error) {
      throw mapIamBlockedRpcError(error);
    }
  }
}
