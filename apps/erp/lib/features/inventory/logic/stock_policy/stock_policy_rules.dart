import 'package:erp/features/inventory/logic/stock/stock_indicator_rules.dart';

const capRowError = 'Mục tiêu phải lớn hơn hoặc bằng ngưỡng.';
const capDaysError = 'Số ngày cận hạn phải lớn hơn 0.';

/// Kiểm tra lỗi dòng ngưỡng cảnh báo / mức tồn mục tiêu.
/// Số lượng là số nguyên ≥ 0; mục tiêu ≥ ngưỡng.
/// Sản phẩm chưa cấu hình có thể để trống cả 2 ô.
String? thresholdRowError(
  String threshold,
  String target, {
  required bool configured,
}) {
  final tStr = threshold.trim();
  final gStr = target.trim();

  if (tStr.isEmpty && gStr.isEmpty) {
    return configured ? capRowError : null;
  }
  if (tStr.isEmpty || gStr.isEmpty) {
    return capRowError;
  }

  final t = int.tryParse(tStr);
  final g = int.tryParse(gStr);
  if (t == null || g == null) {
    return capRowError;
  }
  if (t < 0 || g < t) {
    return capRowError;
  }
  return null;
}

/// Ở chế độ một sản phẩm / sheet, cả 2 ô trống thì bị chặn (chưa nhập).
bool singleBlocked(
  String threshold,
  String target, {
  required bool configured,
}) {
  final tStr = threshold.trim();
  final gStr = target.trim();
  final empty = tStr.isEmpty && gStr.isEmpty;
  final err = thresholdRowError(threshold, target, configured: configured);
  return empty || err != null;
}

/// Kiểm tra lỗi ô số ngày cận hạn mặc định (trống = hợp lệ / chưa đặt).
String? defaultDaysError(String text) {
  final s = text.trim();
  if (s.isEmpty) return null;
  final d = int.tryParse(s);
  if (d == null || d <= 0) return capDaysError;
  return null;
}

/// Kiểm tra lỗi ô số ngày cận hạn riêng (trống = lỗi; phải > 0).
String? overrideDaysError(String text) {
  final s = text.trim();
  if (s.isEmpty) return capDaysError;
  final d = int.tryParse(s);
  if (d == null || d <= 0) return capDaysError;
  return null;
}

/// Đếm số sản phẩm tồn thấp trong danh sách.
int lowCount(
  Iterable<
          ({
            num available,
            num? threshold,
            bool hasExpired,
            bool hasNearExpiry,
          })>
      items,
) {
  var count = 0;
  for (final item in items) {
    final inds = stockIndicators(
      available: item.available,
      threshold: item.threshold,
      hasExpired: item.hasExpired,
      hasNearExpiry: item.hasNearExpiry,
    );
    if (inds.contains(StockIndicator.low)) {
      count++;
    }
  }
  return count;
}

