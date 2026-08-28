import 'package:vet45_adapters/vet45_adapters.dart';
import 'package:vet45_einvoice_application/application.dart';
import 'package:vet45_shared_infrastructure/infrastructure.dart';

import '../../errors/einvoice_error_mapper.dart';
import 'issuance_rpc_mapper.dart';

final class SupabaseOrderInvoiceProjectionReadGateway
    implements IOrderInvoiceProjectionReadGateway {
  SupabaseOrderInvoiceProjectionReadGateway({
    required SupabaseSchemaRpcClient rpcClient,
  }) : _rpcClient = rpcClient;

  final SupabaseSchemaRpcClient _rpcClient;

  @override
  Future<OrderInvoiceProjectionDto> getBySalesOrder({
    required String tenantId,
    required String actorId,
    required String salesOrderId,
  }) async {
    try {
      final rows = await _rpcClient.callList(
        'get_order_invoice_projection',
        params: IssuanceRpcMapper.orderInvoiceProjectionParams(
          tenantId: tenantId,
          actorId: actorId,
          salesOrderId: salesOrderId,
        ),
      );
      if (rows.isEmpty) {
        throw RpcException('get_order_invoice_projection returned no rows');
      }
      return IssuanceRpcMapper.orderInvoiceProjectionFromRow(
        Map<String, dynamic>.from(rows.first),
      );
    } on RpcException catch (error) {
      throw mapEinvoiceRpcError(error);
    }
  }
}
