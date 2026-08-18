import 'package:vet45_adapters/vet45_adapters.dart';
import 'package:vet45_einvoice_application/application.dart';
import 'package:vet45_shared_infrastructure/infrastructure.dart';

import '../errors/einvoice_error_mapper.dart';
import 'einvoice_rpc_mapper.dart';

final class SupabaseIssuanceProfileGateway implements IIssuanceProfileGateway {
  SupabaseIssuanceProfileGateway({required SupabaseSchemaRpcClient rpcClient})
    : _rpcClient = rpcClient;

  final SupabaseSchemaRpcClient _rpcClient;

  @override
  Future<IssuanceProfileDto> getProfile({
    required String tenantId,
    required String actorId,
  }) async {
    try {
      final row = await _firstRow('get_issuance_profile', {
        'p_tenant_id': tenantId,
        'p_actor_id': actorId,
      });
      return EinvoiceRpcMapper.mapIssuanceProfile(row);
    } on RpcException catch (error) {
      throw mapEinvoiceRpcError(error);
    }
  }

  @override
  Future<IssuanceProfileDto> setDefaultConfiguration(
    SetDefaultIssuanceConfigurationCommand command,
  ) async {
    try {
      final row = await _firstRow('set_default_issuance_configuration', {
        'p_tenant_id': command.tenantId,
        'p_actor_id': command.actorId,
        'p_template_id': command.templateId.trim(),
        'p_signing_config_id': command.signingConfigId.trim(),
        if (command.expectedProfileVersion != null)
          'p_expected_profile_version': command.expectedProfileVersion,
      });
      return EinvoiceRpcMapper.mapIssuanceProfile(row);
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
