import 'package:vet45_adapters/vet45_adapters.dart';
import 'package:vet45_einvoice_application/application.dart';
import 'package:vet45_einvoice_domain/domain.dart';
import 'package:vet45_shared_infrastructure/infrastructure.dart';

import '../errors/einvoice_error_mapper.dart';
import 'einvoice_rpc_mapper.dart';

final class SupabaseConfigurationReadinessReadGateway
    implements IConfigurationReadinessReadGateway {
  SupabaseConfigurationReadinessReadGateway({
    required SupabaseSchemaRpcClient rpcClient,
  }) : _rpcClient = rpcClient;

  final SupabaseSchemaRpcClient _rpcClient;

  @override
  Future<ConfigurationReadinessDto> getReadiness({
    required String tenantId,
    required String actorId,
    IssuancePurpose? purpose,
  }) async {
    try {
      final rows = await _rpcClient.callList(
        'get_configuration_readiness',
        params: {
          'p_tenant_id': tenantId,
          'p_actor_id': actorId,
          if (purpose != null) 'p_purpose': purpose.name,
        },
      );
      if (rows.isEmpty) {
        throw RpcException('get_configuration_readiness returned no rows');
      }
      return EinvoiceRpcMapper.mapConfigurationReadiness(
        Map<String, dynamic>.from(rows.first),
      );
    } on RpcException catch (error) {
      throw mapEinvoiceRpcError(error);
    }
  }
}
