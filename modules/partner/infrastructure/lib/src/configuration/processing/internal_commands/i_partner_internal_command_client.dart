/// A claimed durable internal-command row from `partner.internal_commands`.
final class PartnerInternalCommandRow {
  const PartnerInternalCommandRow({
    required this.commandId,
    required this.claimToken,
    required this.commandType,
    required this.payload,
  });

  final String commandId;
  final String claimToken;
  final String commandType;
  final Map<String, dynamic> payload;
}

/// Durable internal-command queue port (partner schema RPC contract).
abstract interface class IPartnerInternalCommandClient {
  Future<void> enqueue({
    required String tenantId,
    required String commandId,
    required String commandType,
    required Map<String, dynamic> payload,
    String? sourceEventId,
  });

  Future<List<PartnerInternalCommandRow>> claimBatch({
    required String tenantId,
    int batchSize = 10,
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
