/// Deep-link metadata for opening the source transaction in its owning module.
final class PartnerTransactionSourceNavigationDto {
  const PartnerTransactionSourceNavigationDto({
    required this.sourceModule,
    required this.sourceType,
    required this.sourceId,
    this.requiredPermission,
  });

  final String sourceModule;
  final String sourceType;
  final String sourceId;
  final String? requiredPermission;
}
