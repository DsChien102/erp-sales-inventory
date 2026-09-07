import 'package:vet45_adapters/vet45_adapters.dart';
import 'package:vet45_einvoice_application/application.dart';
import 'package:vet45_shared_infrastructure/infrastructure.dart';

import '../errors/einvoice_error_mapper.dart';
import 'einvoice_rpc_mapper.dart';

final class SupabaseInvoicePreviewGateway implements IInvoicePreviewGateway {
  SupabaseInvoicePreviewGateway({required SupabaseSchemaRpcClient rpcClient})
    : _rpcClient = rpcClient;

  final SupabaseSchemaRpcClient _rpcClient;

  @override
  Future<String> persistRequestAndEnqueue({
    required String tenantId,
    required String actorId,
    required String salesOrderId,
    required int expectedOrderVersion,
  }) async {
    try {
      final rows = await _rpcClient.callList(
        'request_invoice_preview',
        params: {
          'p_tenant_id': tenantId,
          'p_actor_id': actorId,
          'p_sales_order_id': salesOrderId,
          'p_expected_order_version': expectedOrderVersion,
        },
      );
      if (rows.isEmpty) {
        throw RpcException('request_invoice_preview returned no rows');
      }
      return (rows.first as Map)['preview_request_id'] as String;
    } on RpcException catch (error) {
      throw mapEinvoiceRpcError(error);
    }
  }

  @override
  Future<InvoicePreviewResultDto?> readCached({
    required String tenantId,
    required String actorId,
    required String salesOrderId,
  }) async {
    try {
      final rows = await _rpcClient.callList(
        'get_invoice_preview',
        params: {
          'p_tenant_id': tenantId,
          'p_actor_id': actorId,
          'p_sales_order_id': salesOrderId,
        },
      );
      if (rows.isEmpty) return null;
      return EinvoiceRpcMapper.invoicePreviewResultFromRow(
        Map<String, dynamic>.from(rows.first),
      );
    } on RpcException catch (error) {
      throw mapEinvoiceRpcError(error);
    }
  }

  @override
  Future<void> storeResult({
    required String tenantId,
    required String previewRequestId,
    String? viewerRef,
    Map<String, Object?>? previewPayload,
  }) async {
    try {
      await _rpcClient.callList(
        'store_preview_result',
        params: {
          'p_tenant_id': tenantId,
          'p_preview_request_id': previewRequestId,
          if (viewerRef != null) 'p_viewer_ref': viewerRef,
          if (previewPayload != null) 'p_preview_payload': previewPayload,
          'p_status': 'ready',
        },
      );
    } on RpcException catch (error) {
      throw mapEinvoiceRpcError(error);
    }
  }
}
