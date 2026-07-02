/// A claimed inbound message from `partner.inbox_messages`.
final class PartnerInboxMessage {
  const PartnerInboxMessage({
    required this.messageId,
    required this.claimToken,
    required this.eventType,
    required this.payload,
    required this.occurredOn,
  });

  final String messageId;
  final String claimToken;
  final String eventType;
  final Map<String, dynamic> payload;
  final DateTime occurredOn;
}

/// Inbox queue port for partner-consumed integration events (claim-token contract).
abstract interface class IPartnerInboxClient {
  Future<List<PartnerInboxMessage>> claimBatch({
    required String tenantId,
    int batchSize = 10,
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
