import 'package:vet45_adapters/vet45_adapters.dart';
import 'package:vet45_einvoice_application/application.dart';
import 'package:vet45_shared_infrastructure/infrastructure.dart';

import '../errors/einvoice_error_mapper.dart';

final class SupabaseBuyerInvoiceDataGateway
    implements IBuyerInvoiceDataGateway {
  SupabaseBuyerInvoiceDataGateway({
    required SupabaseSchemaRpcClient rpcClient,
  }) : _rpcClient = rpcClient;

  final SupabaseSchemaRpcClient _rpcClient;

  @override
  Future<BuyerCompletionContext> loadCompletionContext({
    required String tenantId,
    required String actorId,
    required String salesOrderId,
    required int expectedOrderVersion,
  }) {
    // DEFERRED (fake-seam): loading the completion context needs the base
    // BuyerInvoiceSnapshot from Theme 05 (sales.* not in DB yet) plus the current
    // buyer_invoice_completions row via a dedicated `load_buyer_completion_context`
    // RPC returning base_*/resolved_values/status/... (EinvoiceRpcMapper
    // .buyerCompletionContextFromRow already maps that shape). Until Theme 05
    // lands, fail loudly instead of returning a mis-mapped readiness row.
    throw UnimplementedError(
      'load_buyer_completion_context RPC pending Theme 05 sales schema',
    );
  }

  @override
  Future<void> saveLockedCompletion({
    required String tenantId,
    required String actorId,
    required String salesOrderId,
    required String salesOrderVersion,
    required List<String> eligibleFields,
    required Map<String, String?> resolvedValues,
  }) async {
    // Command boundary carries an int version; the RPC param is int per the frozen
    // contract, but the column is varchar(100). Do not silently coerce non-int
    // versions — surface a clear error if Theme 05 ever emits a non-numeric version.
    final versionInt = int.tryParse(salesOrderVersion);
    if (versionInt == null) {
      throw RpcException(
        'VALIDATION_ERROR: sales_order_version "$salesOrderVersion" is not an int',
      );
    }
    try {
      await _rpcClient.callList(
        'complete_buyer_invoice_data',
        params: {
          'p_tenant_id': tenantId,
          'p_actor_id': actorId,
          'p_sales_order_id': salesOrderId,
          'p_expected_order_version': versionInt,
          'p_eligible_fields': eligibleFields,
          'p_resolved_values': resolvedValues,
        },
      );
    } on RpcException catch (error) {
      throw mapEinvoiceRpcError(error);
    }
  }
}
