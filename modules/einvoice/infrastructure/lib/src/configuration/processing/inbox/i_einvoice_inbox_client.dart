/// Claimed inbox row for worker processing.
final class ClaimedInboxMessage {
  const ClaimedInboxMessage({
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

/// Inbox receive / claim / complete / fail for `einvoice.inbox_messages`.
abstract interface class IEinvoiceInboxClient {
  Future<String> receive({
    required String tenantId,
    required String messageId,
    required String eventType,
    required Map<String, dynamic> payload,
    required DateTime occurredAt,
  });

  Future<List<ClaimedInboxMessage>> claimBatch({
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
