import 'partner_schema_rpc.dart';
import 'partner_transaction_history_ingestor.dart';

/// Drains `partner.inbox_messages` and projects transaction history rows.
final class PartnerInboxProcessor {
  PartnerInboxProcessor({
    required PartnerSchemaRpc rpcClient,
    required PartnerTransactionHistoryIngestor ingestor,
  })  : _rpcClient = rpcClient,
        _ingestor = ingestor;

  final PartnerSchemaRpc _rpcClient;
  final PartnerTransactionHistoryIngestor _ingestor;

  Future<bool> processOnce({
    required String tenantId,
    int batchSize = 10,
  }) async {
    final rows = await _rpcClient.callList(
      'claim_inbox_batch',
      params: <String, dynamic>{
        'p_tenant_id': tenantId,
        'p_limit': batchSize,
      },
    );

    if (rows.isEmpty) {
      return false;
    }

    for (final row in rows) {
      final messageId = row['message_id'] as String;
      final claimToken = row['claim_token'] as String;
      final eventType = row['event_type'] as String;
      final payload = Map<String, dynamic>.from(row['payload'] as Map);
      final occurredOn = DateTime.parse(row['occurred_at'] as String);

      try {
        await _ingestor.ingest(
          eventType: eventType,
          messageId: messageId,
          occurredOn: occurredOn,
          payload: payload,
        );
        await _rpcClient.callScalar<void>(
          'complete_inbox_message',
          params: <String, dynamic>{
            'p_tenant_id': tenantId,
            'p_message_id': messageId,
            'p_claim_token': claimToken,
          },
        );
      } catch (error) {
        await _rpcClient.callScalar<void>(
          'fail_inbox_message',
          params: <String, dynamic>{
            'p_tenant_id': tenantId,
            'p_message_id': messageId,
            'p_claim_token': claimToken,
            'p_error': error.toString(),
          },
        );
        rethrow;
      }
    }

    return true;
  }
}
