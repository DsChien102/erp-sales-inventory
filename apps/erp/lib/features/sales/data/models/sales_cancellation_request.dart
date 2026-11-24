/// Yêu cầu xác nhận huỷ đơn hàng phía client (không chứa tenantId / actorId).
final class SalesOrderCancellationRequest {
  const SalesOrderCancellationRequest({
    required this.commandId,
    required this.salesOrderId,
    required this.reasonText,
    required this.idempotencyKey,
    required this.payloadHash,
    required this.correlationId,
    required this.expectedOrderVersion,
    required this.expectedSettlementVersion,
  });

  final String commandId;
  final String salesOrderId;
  final String reasonText;
  final String idempotencyKey;
  final String payloadHash;
  final String correlationId;
  final int expectedOrderVersion;
  final int expectedSettlementVersion;
}

