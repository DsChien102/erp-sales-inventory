import 'package:erp/core/formatting/money_formatter.dart';
import 'package:erp/features/inventory/data/supplier_rebate/supplier_rebate_models.dart';

/// Phân tích chuỗi số tiền người dùng nhập; bỏ dấu `.`, khoảng trắng và `đ`.
int? parseMoneyInput(String raw) {
  final cleaned = raw.replaceAll(RegExp(r'[\s.đĐ]'), '');
  if (cleaned.isEmpty || !RegExp(r'^[0-9]+$').hasMatch(cleaned)) {
    return null;
  }
  return int.tryParse(cleaned);
}

/// Kiểm tra số tiền ghi nhận chiết khấu trong `[1, base]`.
String? rebateAmountError(int? amount, int base) {
  if (amount == null) {
    return 'Nhập số tiền ghi nhận';
  }
  if (amount < 1 || amount > base) {
    return 'Số tiền từ 1 đ đến ${MoneyFormatter.formatMinor(base)}';
  }
  return null;
}

/// Chỉ bắt buộc nhập lý do khi số tiền ghi nhận khác số đề xuất.
bool needsOverrideReason(int? amount, int proposed) {
  return amount != null && amount != proposed;
}

/// Kiểm tra lý do khác đề xuất khi [required] là `true`.
String? overrideReasonError(String raw, {required bool required}) {
  if (!required) {
    return null;
  }
  final trimmed = raw.trim();
  if (trimmed.isEmpty) {
    return 'Nhập lý do khi số tiền khác đề xuất';
  }
  if (trimmed.length > 300) {
    return 'Lý do tối đa 300 ký tự';
  }
  return null;
}

/// Kiểm tra số chứng từ không rỗng và tối đa 60 ký tự.
String? documentNoError(String raw) {
  final trimmed = raw.trim();
  if (trimmed.isEmpty) {
    return 'Nhập số chứng từ';
  }
  if (trimmed.length > 60) {
    return 'Số chứng từ tối đa 60 ký tự';
  }
  return null;
}

/// Kiểm tra ngày chứng từ nằm trong `[startedOn, today]` (so theo ngày).
String? documentDateError(DateTime date, DateTime startedOn, DateTime today) {
  final d = DateTime(date.year, date.month, date.day);
  final s = DateTime(startedOn.year, startedOn.month, startedOn.day);
  final t = DateTime(today.year, today.month, today.day);
  if (d.isBefore(s) || d.isAfter(t)) {
    return 'Ngày chứng từ không được sau hôm nay hoặc trước ngày bắt đầu chương trình';
  }
  return null;
}

/// Trả `partnerId` của nhà cung cấp ngoài hệ thống có bình quân giá gốc thấp nhất.
String? cheapestSupplierId(List<SupplierCompareRow> rows) {
  final eligible = rows
      .where((r) => !r.isSystem && r.avgLandedUnitCost != null)
      .toList();
  if (eligible.length < 2) {
    return null;
  }
  var best = eligible.first;
  for (var i = 1; i < eligible.length; i++) {
    final candidate = eligible[i];
    if (candidate.avgLandedUnitCost! < best.avgLandedUnitCost!) {
      best = candidate;
    }
  }
  return best.partnerId;
}

/// Kiểm tra tổng phần phân bổ vào tồn có đổi từ lúc xem trước hay không.
bool stockChangedSincePreview(
  int? previewInventoryTotal,
  int recordedInventoryTotal,
) {
  return previewInventoryTotal != null &&
      previewInventoryTotal != recordedInventoryTotal;
}

