/// Claimed Sales outbox row for worker processing.
final class ClaimedSalesOutboxMessage {
  const ClaimedSalesOutboxMessage({
    required this.messageId,
    required this.eventType,
    required this.payload,
    required this.occurredAt,
    required this.claimToken,
  });

  final String messageId;
  final String eventType;
  final Map<String, dynamic> payload;
  final DateTime occurredAt;
  final String claimToken;
}

/// Worker-facing Sales outbox client: claim / complete / fail only.
///
/// **Enqueue belongs in mutation RPC** (`enqueue_outbox_message` same
/// transaction as the business write) — never from Dart application/infra.
abstract interface class ISalesOutboxClient {
  Future<List<ClaimedSalesOutboxMessage>> claimBatch({
    required String tenantId,
    required int limit,
  });

  Future<void> complete({
    required String tenantId,
    required String messageId,
    required String claimToken,
  });

  Future<void> fail({
    required String tenantId,
    required String messageId,
    required String claimToken,
    required String error,
  });
}
