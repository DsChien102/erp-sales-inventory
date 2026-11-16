import 'package:erp/core/formatting/money_formatter.dart';
import 'package:erp/features/assistant/data.dart';

const _empty = '—';

/// Chỉ định dạng để hiển thị, không tính toán trên số.
String formatAssistantCell(ColumnKind kind, Object? value) {
  if (value == null) return _empty;
  switch (kind) {
    case ColumnKind.chu:
      return value.toString();
    case ColumnKind.tien:
      if (value is! num || !value.isFinite) return value.toString();
      return MoneyFormatter.formatMinor(value.round());
    case ColumnKind.so:
      if (value is! num || !value.isFinite) return value.toString();
      return _decimal(value);
    case ColumnKind.phanTram:
      if (value is! num || !value.isFinite) return value.toString();
      return '${_decimal(value)}%';
    case ColumnKind.ngay:
      final m = value is String ? RegExp(r'^(\d{4})-(\d{2})-(\d{2})').firstMatch(value) : null;
      if (m == null) return value.toString();
      return '${m.group(3)}/${m.group(2)}/${m.group(1)}';
  }
}

/// Tối đa 1 số lẻ, phân nhóm nghìn bằng dấu chấm, thập phân bằng dấu phẩy.
String _decimal(num value) {
  final rounded = double.parse(value.toStringAsFixed(1));
  final whole = rounded.truncate();
  final negative = rounded < 0;
  final fraction = ((rounded.abs() - whole.abs()) * 10).round();
  final grouped = MoneyFormatter.formatMinorPlain(whole.abs());
  final sign = negative ? '-' : '';
  return fraction == 0 ? '$sign$grouped' : '$sign$grouped,$fraction';
}
