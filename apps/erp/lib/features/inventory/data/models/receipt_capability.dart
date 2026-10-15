class ReceiptCapability {
  const ReceiptCapability({
    required this.canQuickReceive,
    required this.warehouseLocked,
  });

  final bool canQuickReceive;
  final bool warehouseLocked;
}
