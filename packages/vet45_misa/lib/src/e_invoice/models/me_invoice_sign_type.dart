/// HSM signing types supported by Vet45 (§6).
enum MeInvoiceSignType {
  /// Ký số qua HSM, có hiển thị CKS.
  hsmWithCks(2),

  /// Ký số sau loại HĐ MTT, không hiển thị CKS.
  hsmNoCks(5);

  const MeInvoiceSignType(this.wireValue);

  final int wireValue;
}
