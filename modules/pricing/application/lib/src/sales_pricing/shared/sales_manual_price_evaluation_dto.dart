final class SalesManualPriceEvaluationDto {
  const SalesManualPriceEvaluationDto({
    required this.allowed,
    required this.requiresAcknowledgement,
    required this.normalizedUnitPriceMinor,
    required this.floorPriceMinor,
    required this.canViewFloor,
    required this.warningCodes,
    required this.blockingCode,
    required this.message,
  });

  final bool allowed;
  final bool requiresAcknowledgement;
  final int normalizedUnitPriceMinor;
  final int? floorPriceMinor;
  final bool canViewFloor;
  final List<String> warningCodes;
  final String? blockingCode;
  final String? message;
}
