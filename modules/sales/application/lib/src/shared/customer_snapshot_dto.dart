final class CustomerSnapshotDto {
  const CustomerSnapshotDto({
    required this.customerId,
    required this.displayName,
    this.phoneNumber,
    this.taxCode,
    this.existingDebtMinor = 0,
  });

  final String customerId;
  final String displayName;
  final String? phoneNumber;
  final String? taxCode;
  final int existingDebtMinor;
}
