import 'package:erp/core/formatting/money_formatter.dart';
import 'package:erp/features/inventory/logic/inventory_format.dart';

String _pad2(int n) => n.toString().padLeft(2, '0');

/// Nhãn dòng biến động (thẻ kho, 056). `kind` = `movement_kind`, `intentType` = `intent_type`.
String movementLabel(String kind, String intentType, String? reason) {
  switch (kind) {
    case 'RECEIPT':
      return 'Nhận hàng';
    case 'SALE':
      return intentType == 'RETURN_EXCHANGE' ? 'Đổi hàng' : 'Bán hàng';
    case 'SALE_REVERSAL':
      return intentType == 'SALES_CANCELLATION' ? 'Huỷ đơn' : 'Trả hàng';
    case 'RETURN_IN':
      return 'Trả hàng';
    case 'COUNT_GAIN':
      return 'Kiểm kê thừa';
    case 'COUNT_LOSS':
    case 'WRITE_OFF':
      switch (reason) {
        case 'DAMAGED':
          return 'Hỏng';
        case 'EXPIRED':
          return 'Hết hạn';
        case 'LOSS':
          return 'Thất thoát';
        default:
          return 'Kiểm kê thiếu';
      }
    default:
      return 'Biến động kho';
  }
}

/// `+20` · `−2` (U+2212) · `0`.
String signedQty(num v) {
  if (v == 0) return '0';
  final text = formatQuantity(v.abs().toDouble());
  return v > 0 ? '+$text' : '−$text';
}

/// `null` ⇒ `—`; `35.2` ⇒ `35,2%`.
String marginText(num? pct) {
  if (pct == null) return '—';
  final fixed = pct.toStringAsFixed(1).replaceAll('.', ',');
  return '$fixed%';
}

/// `dd/MM/yyyy · HH:mm` (giờ máy).
String asOfText(DateTime t) {
  final l = t.toLocal();
  return '${_pad2(l.day)}/${_pad2(l.month)}/${l.year} · '
      '${_pad2(l.hour)}:${_pad2(l.minute)}';
}

/// Đơn giá gốc bình quân: `103.000 đ` · `93,64 đ` (tối đa 2 chữ số lẻ).
String unitCostText(num v) {
  final rounded = (v * 100).round() / 100;
  final whole = rounded.truncate();
  final cents = ((rounded - whole).abs() * 100).round();
  final grouped = MoneyFormatter.formatMinorPlain(whole);
  if (cents == 0) return '$grouped đ';
  final frac = cents.toString().padLeft(2, '0').replaceFirst(RegExp(r'0$'), '');
  return '$grouped,$frac đ';
}
