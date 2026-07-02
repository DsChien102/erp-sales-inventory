import 'package:vet45_partner_application/application.dart';
import 'package:vet45_partner_domain/domain.dart';

import 'partner_schema_rpc.dart';

/// Drains `partner.internal_commands` for durable projection writes.
final class PartnerInternalCommandProcessor {
  PartnerInternalCommandProcessor({
    required PartnerSchemaRpc rpcClient,
    required RecordPartnerTransactionHistoryCommandHandler recordHandler,
  })  : _rpcClient = rpcClient,
        _recordHandler = recordHandler;

  final PartnerSchemaRpc _rpcClient;
  final RecordPartnerTransactionHistoryCommandHandler _recordHandler;

  Future<bool> processOnce({
    required String tenantId,
    int batchSize = 10,
  }) async {
    final rows = await _rpcClient.callList(
      'claim_internal_commands_batch',
      params: <String, dynamic>{
        'p_tenant_id': tenantId,
        'p_limit': batchSize,
      },
    );

    if (rows.isEmpty) {
      return false;
    }

    for (final row in rows) {
      final commandId = row['command_id'] as String;
      final claimToken = row['claim_token'] as String;
      final commandType = row['command_type'] as String;
      final payload = Map<String, dynamic>.from(row['payload'] as Map);

      try {
        await _dispatch(commandType, payload);
        await _rpcClient.callScalar<void>(
          'complete_internal_command',
          params: <String, dynamic>{
            'p_tenant_id': tenantId,
            'p_command_id': commandId,
            'p_claim_token': claimToken,
          },
        );
      } catch (error) {
        await _rpcClient.callScalar<void>(
          'fail_internal_command',
          params: <String, dynamic>{
            'p_tenant_id': tenantId,
            'p_command_id': commandId,
            'p_claim_token': claimToken,
            'p_error': error.toString(),
          },
        );
        rethrow;
      }
    }

    return true;
  }

  Future<void> _dispatch(String commandType, Map<String, dynamic> payload) {
    if (commandType != RecordPartnerTransactionHistoryCommand.commandType) {
      throw UnsupportedError('Unsupported internal command: $commandType');
    }

    return _recordHandler.handle(
      RecordPartnerTransactionHistoryCommand(
        tenantId: payload['tenant_id'] as String,
        businessPartnerId: payload['business_partner_id'] as String,
        transactionRole: PartnerRole.values.byName(
          payload['transaction_role'] as String,
        ),
        sourceModule: payload['source_module'] as String,
        sourceType: payload['source_type'] as String,
        sourceId: payload['source_id'] as String,
        sourceCode: payload['source_code'] as String?,
        transactionDate: DateTime.parse(payload['transaction_date'] as String),
        amount: (payload['amount'] as num?)?.toDouble(),
        status: payload['status'] as String?,
        description: payload['description'] as String?,
      ),
    );
  }
}
