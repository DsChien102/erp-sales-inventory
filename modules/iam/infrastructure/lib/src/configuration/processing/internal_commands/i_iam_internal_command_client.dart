/// Claimed internal-command row for worker processing.
final class ClaimedInternalCommand {
  const ClaimedInternalCommand({
    required this.commandId,
    required this.commandType,
    required this.payload,
    required this.enqueuedAt,
    required this.claimToken,
    this.sourceEventId,
  });

  final String commandId;
  final String commandType;
  final Map<String, dynamic> payload;
  final DateTime enqueuedAt;
  final String claimToken;
  final String? sourceEventId;

  /// Row shape expected by [InternalCommandSerializer.deserializeRow].
  Map<String, dynamic> toSerializerRow() {
    return <String, dynamic>{
      'command_id': commandId,
      'command_type': commandType,
      'payload': payload,
      if (sourceEventId != null) 'source_event_id': sourceEventId,
      'enqueued_at': enqueuedAt.toIso8601String(),
      'claim_token': claimToken,
    };
  }
}

/// Claim / complete / fail RPCs for `iam.internal_commands`.
abstract interface class IIamInternalCommandClient {
  Future<List<ClaimedInternalCommand>> claimBatch({
    required String tenantId,
    required int limit,
  });

  Future<void> complete({
    required String tenantId,
    required String commandId,
    required String claimToken,
  });

  Future<void> fail({
    required String tenantId,
    required String commandId,
    required String claimToken,
    required String error,
  });
}
