import 'package:vet45_partner_application/application.dart';
import 'package:vet45_adapters/vet45_adapters.dart';
import 'package:vet45_shared_infrastructure/infrastructure.dart';

import '../../errors/partner_error_mapper.dart';

final class SupabasePartnerTransactionHistoryWriteGateway
    implements IPartnerTransactionHistoryWriteGateway {
  SupabasePartnerTransactionHistoryWriteGateway({
    required SupabaseSchemaRpcClient rpcClient,
  }) : _rpcClient = rpcClient;

  final SupabaseSchemaRpcClient _rpcClient;

  @override
  Future<void> upsert(RecordPartnerTransactionHistoryCommand command) async {
    try {
      await _rpcClient.callScalar<String>(
        'upsert_transaction_history',
        params: <String, dynamic>{
          'p_tenant_id': command.tenantId,
          'p_business_partner_id': command.businessPartnerId,
          'p_transaction_role': command.transactionRole.name,
          'p_source_module': command.sourceModule,
          'p_source_type': command.sourceType,
          'p_source_id': command.sourceId,
          'p_source_code': command.sourceCode,
          'p_transaction_date': command.transactionDate.toUtc().toIso8601String(),
          'p_amount': command.amount,
          'p_status': command.status,
          'p_description': command.description,
        },
      );
    } on RpcException catch (error) {
      throw mapPartnerRpcError(error);
    }
  }
}
