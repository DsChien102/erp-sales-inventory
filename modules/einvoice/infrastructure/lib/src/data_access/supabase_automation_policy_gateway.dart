import 'package:vet45_adapters/vet45_adapters.dart';
import 'package:vet45_einvoice_application/application.dart';
import 'package:vet45_shared_infrastructure/infrastructure.dart';

import '../errors/einvoice_error_mapper.dart';
import 'einvoice_rpc_mapper.dart';

final class SupabaseAutomationPolicyGateway
    implements IAutomationPolicyGateway {
  SupabaseAutomationPolicyGateway({required SupabaseSchemaRpcClient rpcClient})
    : _rpcClient = rpcClient;

  final SupabaseSchemaRpcClient _rpcClient;

  @override
  Future<AutomationPolicyDto> getPolicy({
    required String tenantId,
    required String actorId,
  }) async {
    try {
      final row = await _firstRow('get_automation_policy', {
        'p_tenant_id': tenantId,
        'p_actor_id': actorId,
      });
      return EinvoiceRpcMapper.mapAutomationPolicy(row);
    } on RpcException catch (error) {
      throw mapEinvoiceRpcError(error);
    }
  }

  @override
  Future<AutomationPolicyDto> updatePolicy(
    UpdateAutomationPolicyCommand command,
  ) async {
    try {
      final row = await _firstRow('update_automation_policy', {
        'p_tenant_id': command.tenantId,
        'p_actor_id': command.actorId,
        if (command.autoIssueEnabled != null)
          'p_auto_issue_enabled': command.autoIssueEnabled,
        if (command.autoSendEnabled != null)
          'p_auto_send_enabled': command.autoSendEnabled,
        'p_expected_policy_version': command.expectedPolicyVersion,
      });
      return EinvoiceRpcMapper.mapAutomationPolicy(row);
    } on RpcException catch (error) {
      throw mapEinvoiceRpcError(error);
    }
  }

  Future<Map<String, dynamic>> _firstRow(
    String rpc,
    Map<String, dynamic> params,
  ) async {
    final rows = await _rpcClient.callList(rpc, params: params);
    if (rows.isEmpty) {
      throw RpcException('RPC $rpc returned no rows');
    }
    return Map<String, dynamic>.from(rows.first);
  }
}
