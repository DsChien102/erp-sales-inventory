/// Formats catalog money for display — round to nearest đồng, thousand separators.
/// Matches Product Control Center / detail price labels (e.g. `115.000 đ`).
String formatCatalogCurrency(double? value) {
  if (value == null) return '--';
  final intVal = value.round();
  final buffer = StringBuffer();
  final s = intVal.toString();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) {
      buffer.write('.');
    }
    buffer.write(s[i]);
  }
  return '${buffer.toString()} đ';
}
