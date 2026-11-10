/// 106 · 1,5 · 0,25 — không làm tròn số lẻ.
String formatQuantity(double q) {
  if (q == q.roundToDouble()) return q.toInt().toString();
  return q
      .toStringAsFixed(3)
      .replaceFirst(RegExp(r'0+$'), '')
      .replaceAll('.', ',');
}

/// Định dạng số lượng kèm đơn vị tính: "41 hộp", "1,5 chai".
String formatStockQuantity(num q, String uom) =>
    '${formatQuantity(q.toDouble())} $uom';

