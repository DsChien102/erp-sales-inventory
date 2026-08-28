import 'package:vet45_adapters/vet45_adapters.dart';
import 'package:vet45_einvoice_application/application.dart';
import 'package:vet45_einvoice_domain/domain.dart';
import 'package:vet45_shared_infrastructure/infrastructure.dart';

import '../errors/einvoice_error_mapper.dart';
import 'einvoice_rpc_mapper.dart';

final class SupabaseIssuanceReadinessReadGateway
    implements IIssuanceReadinessReadGateway {
  SupabaseIssuanceReadinessReadGateway({
    required SupabaseSchemaRpcClient rpcClient,
  }) : _rpcClient = rpcClient;

  final SupabaseSchemaRpcClient _rpcClient;

  @override
  Future<IssuanceReadinessInput> load({
    required String tenantId,
    required String actorId,
    required String salesOrderId,
  }) async {
    try {
      final rows = await _rpcClient.callList(
        'get_issuance_readiness',
        params: {
          'p_tenant_id': tenantId,
          'p_actor_id': actorId,
          'p_sales_order_id': salesOrderId,
        },
      );
      if (rows.isEmpty) {
        throw RpcException('get_issuance_readiness returned no rows');
      }
      return EinvoiceRpcMapper.issuanceReadinessInputFromRow(
        Map<String, dynamic>.from(rows.first),
      );
    } on RpcException catch (error) {
      throw mapEinvoiceRpcError(error);
    }
  }
}
