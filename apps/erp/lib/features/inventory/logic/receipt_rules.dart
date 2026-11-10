import '../data/models/lot_date.dart';
import '../data/models/receipt_item_draft.dart';
import 'inventory_format.dart';

export 'inventory_format.dart';

enum LotIssue {
  emptyQuantity, // Nhập ít nhất một số lượng
  negativeQuantity, // Số lượng không được âm
  missingLotCode, // Nhập số lô
  duplicateLotCode, // Số lô bị trùng trong mặt hàng này
  missingExpiry, // Nhập hạn dùng
  expiryNotAfterManufacture, // Hạn dùng phải sau ngày sản xuất
  lotConflict, // Lô đã có trong hệ thống với hạn dùng khác
}

class ReceiptItemValidation {
  const ReceiptItemValidation(this.lotIssues);

  /// Cùng thứ tự với item.lots.
  final List<Set<LotIssue>> lotIssues;

  bool get isValid => lotIssues.isNotEmpty && lotIssues.every((s) => s.isEmpty);
}

ReceiptItemValidation validateReceiptItem(ReceiptItemDraft item) {
  final counts = <String, int>{};
  for (final lot in item.lots) {
    final code = lot.lotCode.trim().toUpperCase();
    if (code.isNotEmpty) counts[code] = (counts[code] ?? 0) + 1;
  }
  return ReceiptItemValidation([
    for (final lot in item.lots)
      <LotIssue>{
        if ([lot.accepted, lot.quarantine, lot.damaged, lot.rejected]
            .any((q) => q < 0))
          LotIssue.negativeQuantity,
        if (lot.totalReceived <= 0) LotIssue.emptyQuantity,
        if (item.isLotTracked && lot.lotCode.trim().isEmpty)
          LotIssue.missingLotCode,
        if (item.isLotTracked &&
            (counts[lot.lotCode.trim().toUpperCase()] ?? 0) > 1)
          LotIssue.duplicateLotCode,
        if (item.isLotTracked && item.requiresExpiry && lot.expiryDate == null)
          LotIssue.missingExpiry,
        if (lot.expiryDate != null &&
            lot.manufactureDate != null &&
            !lot.expiryDate!.start.isAfter(lot.manufactureDate!.start))
          LotIssue.expiryNotAfterManufacture,
        if (item.isLotTracked &&
            lot.expiryDate != null &&
            _knownExpiry(item, lot.lotCode) != null &&
            !lot.expiryDate!.isConsistentWith(_knownExpiry(item, lot.lotCode)!))
          LotIssue.lotConflict,
      },
  ]);
}

LotDate? _knownExpiry(ReceiptItemDraft item, String lotCode) =>
    item.knownLotExpiry[lotCode.trim().toUpperCase()];

String lotIssueMessage(LotIssue issue) => switch (issue) {
      LotIssue.emptyQuantity => 'Nhập ít nhất một số lượng',
      LotIssue.negativeQuantity => 'Số lượng không được âm',
      LotIssue.missingLotCode => 'Nhập số lô',
      LotIssue.duplicateLotCode => 'Số lô bị trùng trong mặt hàng này',
      LotIssue.missingExpiry => 'Nhập hạn dùng',
      LotIssue.expiryNotAfterManufacture => 'Hạn dùng phải sau ngày sản xuất',
      LotIssue.lotConflict => 'Lô này đã có trong hệ thống với hạn dùng khác',
    };

/// "120 đạt · 2 cách ly · 1 hỏng · 5 từ chối" hoặc "Chưa ghi nhận" (prototype `classificationText`).
String classificationText(ReceiptItemDraft item) {
  if (item.totalReceived <= 0) return 'Chưa ghi nhận';
  return [
    if (item.isLotTracked) '${item.lots.length} lô',
    if (item.totalAccepted > 0) '${formatQuantity(item.totalAccepted)} đạt',
    if (item.totalQuarantine > 0) '${formatQuantity(item.totalQuarantine)} cách ly',
    if (item.totalDamaged > 0) '${formatQuantity(item.totalDamaged)} hỏng',
    if (item.totalRejected > 0) '${formatQuantity(item.totalRejected)} từ chối',
  ].join(' · ');
}

const receiptErrorMessages = {
  'APPROVAL_ALREADY_DECIDED': 'Yêu cầu này đã được xử lý trước đó.',
  'SELF_APPROVAL_NOT_ALLOWED': 'Bạn đã gửi yêu cầu này nên không thể tự duyệt.',
  'APPROVER_CONFIGURATION_MISSING':
      'Chưa thể tạo phiếu. Cần cấu hình người duyệt đủ quyền và phạm vi rồi gửi lại trong phiên hiện tại.',
};
