import 'package:vet45_adapters/vet45_adapters.dart';
import 'package:vet45_einvoice_application/application.dart';
import 'package:vet45_shared_infrastructure/infrastructure.dart';

import '../errors/einvoice_error_mapper.dart';
import 'einvoice_rpc_mapper.dart';

final class SupabaseProviderConnectionReadGateway
    implements IProviderConnectionReadGateway {
  SupabaseProviderConnectionReadGateway({
    required SupabaseSchemaRpcClient rpcClient,
  }) : _rpcClient = rpcClient;

  final SupabaseSchemaRpcClient _rpcClient;

  @override
  Future<ProviderConnectionScreenDto> getConnectionScreen({
    required String tenantId,
    required String actorId,
  }) async {
    try {
      final row = await _firstRow('get_provider_connection_screen', {
        'p_tenant_id': tenantId,
        'p_actor_id': actorId,
      });
      return EinvoiceRpcMapper.mapConnectionScreen(row);
    } on RpcException catch (error) {
      throw mapEinvoiceRpcError(error);
    }
  }

  @override
  Future<List<ProviderTemplateDto>> listProviderTemplates(
    ListProviderTemplatesQuery query,
  ) async {
    try {
      final rows = await _rpcClient.callList(
        'list_provider_templates',
        params: {
          'p_tenant_id': query.tenantId,
          'p_actor_id': query.actorId,
          if (query.invoiceWithCode != null)
            'p_invoice_with_code': query.invoiceWithCode,
          if (query.year != null) 'p_year': query.year,
        },
      );
      return EinvoiceRpcMapper.mapTemplateList(rows);
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
