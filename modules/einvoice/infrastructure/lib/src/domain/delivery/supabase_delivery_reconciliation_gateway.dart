import 'package:vet45_adapters/vet45_adapters.dart';
import 'package:vet45_einvoice_application/application.dart';
import 'package:vet45_shared_infrastructure/infrastructure.dart';

import '../../errors/einvoice_error_mapper.dart';
import 'delivery_rpc_mapper.dart';

final class SupabaseDeliveryReconciliationGateway
    implements IDeliveryReconciliationGateway {
  SupabaseDeliveryReconciliationGateway({
    required SupabaseSchemaRpcClient rpcClient,
  }) : _rpcClient = rpcClient;

  final SupabaseSchemaRpcClient _rpcClient;

  @override
  Future<DeliveryReconciliationContextDto?> loadContext({
    required String tenantId,
    required String reconciliationCaseId,
    required int checkSequence,
  }) async {
    try {
      final rows = await _rpcClient.callList(
        'load_delivery_reconciliation_context',
        params: DeliveryRpcMapper.loadReconciliationContextParams(
          tenantId: tenantId,
          reconciliationCaseId: reconciliationCaseId,
          checkSequence: checkSequence,
        ),
      );
      if (rows.isEmpty) {
        return null;
      }
      return DeliveryRpcMapper.reconciliationContextFromRow(
        Map<String, dynamic>.from(rows.first),
      );
    } on RpcException catch (error) {
      throw mapEinvoiceRpcError(error);
    }
  }

  @override
  Future<DeliveryReconciliationResultDto> recordCheck(
    DeliveryReconciliationCheckRecord record,
  ) async {
    try {
      final rows = await _rpcClient.callList(
        'record_delivery_reconciliation_check',
        params: DeliveryRpcMapper.recordReconciliationCheckParams(record),
      );
      if (rows.isEmpty) {
        throw RpcException(
          'record_delivery_reconciliation_check returned no rows',
        );
      }
      return DeliveryRpcMapper.reconciliationResultFromRow(
        Map<String, dynamic>.from(rows.first),
      );
    } on RpcException catch (error) {
      throw mapEinvoiceRpcError(error);
    }
  }
}
