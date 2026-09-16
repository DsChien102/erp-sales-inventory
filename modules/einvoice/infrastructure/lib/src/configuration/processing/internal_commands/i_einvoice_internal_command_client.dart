enum InternalCommandDisposition { retry, deadLetter }

/// Claimed internal-command row for worker processing.
final class ClaimedInternalCommand {
  const ClaimedInternalCommand({
    required this.commandId,
    required this.commandType,
    required this.payload,
    required this.enqueuedAt,
    required this.claimToken,
    this.sourceEventId,
    this.retryCount = 0,
  });

  final String commandId;
  final String commandType;
  final Map<String, dynamic> payload;
  final DateTime enqueuedAt;
  final String claimToken;
  final String? sourceEventId;
  final int retryCount;

  /// Row shape expected by [InternalCommandSerializer.deserializeRow].
  Map<String, dynamic> toSerializerRow() {
    return <String, dynamic>{
      'command_id': commandId,
      'command_type': commandType,
      'payload': payload,
      if (sourceEventId != null) 'source_event_id': sourceEventId,
      'enqueued_at': enqueuedAt.toIso8601String(),
      'claim_token': claimToken,
      'retry_count': retryCount,
    };
  }
}

/// Claim / complete / fail / retry RPCs for `einvoice.internal_commands`.
abstract interface class IEinvoiceInternalCommandClient {
  Future<int> seedDueReconciliationCommands({
    required String tenantId,
    int limit = 50,
  });

  Future<List<ClaimedInternalCommand>> claimBatch({
    required String tenantId,
    required int limit,
  });

  Future<void> complete({
    required String tenantId,
    required String commandId,
    required String claimToken,
  });

  Future<InternalCommandDisposition> retryOrDeadLetter({
    required String tenantId,
    required String commandId,
    required String claimToken,
    required String error,
  });

  Future<void> fail({
    required String tenantId,
    required String commandId,
    required String claimToken,
    required String error,
  });

  /// Requeue a claimed command after a short delay without incrementing retry_count.
  Future<void> reschedule({
    required String tenantId,
    required String commandId,
    required String claimToken,
    required Duration delay,
  });
}
