final class OpenAutoIssuanceProcessDto {
  const OpenAutoIssuanceProcessDto({
    required this.processId,
    required this.salesOrderId,
    this.partnerId,
    this.status,
  });

  final String processId;
  final String salesOrderId;
  final String? partnerId;
  final String? status;
}
