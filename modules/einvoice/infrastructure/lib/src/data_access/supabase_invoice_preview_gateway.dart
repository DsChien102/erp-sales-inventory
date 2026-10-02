import 'package:vet45_adapters/vet45_adapters.dart';
import 'package:vet45_einvoice_application/application.dart';
import 'package:vet45_einvoice_domain/domain.dart';
import 'package:vet45_shared_infrastructure/infrastructure.dart';

import '../errors/einvoice_error_mapper.dart';
import 'einvoice_rpc_mapper.dart';
import 'electronic_invoice_rpc_mapper.dart';

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
    required String salesOrderId,
    required String requestId,
    required String status,
    String? viewerRef,
    String? failureCode,
    String? failureMessage,
    FailureSource? failureSource,
  }) async {
    try {
      await _rpcClient.callList(
        'store_preview_result',
        params: {
          'p_tenant_id': tenantId,
          'p_sales_order_id': salesOrderId,
          'p_request_id': requestId,
          'p_status': status,
          'p_viewer_ref': viewerRef,
          'p_failure_code': failureCode,
          'p_failure_message': failureMessage,
          'p_failure_source': ElectronicInvoiceRpcMapper.failureSourceToRpc(
            failureSource,
          ),
        },
      );
    } on RpcException catch (error) {
      throw mapEinvoiceRpcError(error);
    }
  }
}
