final class CustomerSnapshotDto {
  const CustomerSnapshotDto({
    required this.customerId,
    required this.displayName,
    this.phoneNumber,
    this.taxCode,
    this.existingDebtMinor = 0,
    this.buyerType,
    this.invoiceLegalName,
    this.invoiceAddress,
    this.invoiceEmail,
  });

  final String customerId;
  final String displayName;
  final String? phoneNumber;
  final String? taxCode;
  final int existingDebtMinor;

  /// `individual` hoặc `organization`, đúng tên enum BuyerType của Theme 08.
  /// Null khi khách lẻ — Theme 08 tự suy ra `retail` từ việc không có partner.
  final String? buyerType;

  /// Tên trên hóa đơn; ưu tiên invoiceName của hồ sơ, không phải displayName.
  final String? invoiceLegalName;
  final String? invoiceAddress;
  final String? invoiceEmail;
}
