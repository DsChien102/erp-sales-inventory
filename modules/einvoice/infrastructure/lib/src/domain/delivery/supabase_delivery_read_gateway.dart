import 'package:vet45_adapters/vet45_adapters.dart';
import 'package:vet45_einvoice_application/application.dart';
import 'package:vet45_shared_infrastructure/infrastructure.dart';

import '../../errors/einvoice_error_mapper.dart';
import 'delivery_rpc_mapper.dart';

final class SupabaseDeliveryReadGateway implements IDeliveryReadGateway {
  SupabaseDeliveryReadGateway({required SupabaseSchemaRpcClient rpcClient})
    : _rpcClient = rpcClient;

  final SupabaseSchemaRpcClient _rpcClient;

  @override
  Future<SendInvoiceSheetContextDto> getSendSheetContext({
    required String tenantId,
    required String actorId,
    required String salesOrderId,
  }) async {
    try {
      final rows = await _rpcClient.callList(
        'get_send_invoice_sheet_context',
        params: DeliveryRpcMapper.sendSheetContextParams(
          tenantId: tenantId,
          actorId: actorId,
          salesOrderId: salesOrderId,
        ),
      );
      if (rows.isEmpty) {
        throw RpcException('get_send_invoice_sheet_context returned no rows');
      }
      return DeliveryRpcMapper.sendSheetContextFromRow(
        Map<String, dynamic>.from(rows.first),
      );
    } on RpcException catch (error) {
      throw mapEinvoiceRpcError(error);
    }
  }

  @override
  Future<InvoiceDeliveryHistoryDto> getHistory({
    required String tenantId,
    required String actorId,
    required String salesOrderId,
  }) async {
    try {
      final rows = await _rpcClient.callList(
        'get_invoice_delivery_history',
        params: DeliveryRpcMapper.historyParams(
          tenantId: tenantId,
          actorId: actorId,
          salesOrderId: salesOrderId,
        ),
      );
      if (rows.isEmpty) {
        throw RpcException('get_invoice_delivery_history returned no rows');
      }
      return DeliveryRpcMapper.historyFromRow(
        Map<String, dynamic>.from(rows.first),
      );
    } on RpcException catch (error) {
      throw mapEinvoiceRpcError(error);
    }
  }
}
