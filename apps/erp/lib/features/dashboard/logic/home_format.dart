/// Hàm thuần định dạng Trang chủ "Bảng giá chợ" (10-8b, Q8).
library;

/// Lời chào theo giờ máy: 5–11 sáng, 12–17 chiều, còn lại tối.
String greetingForHour(int hour) {
  if (hour >= 5 && hour < 12) return 'Chào buổi sáng';
  if (hour >= 12 && hour < 18) return 'Chào buổi chiều';
  return 'Chào buổi tối';
}

const _weekdayNames = ['Thứ Hai', 'Thứ Ba', 'Thứ Tư', 'Thứ Năm', 'Thứ Sáu', 'Thứ Bảy', 'Chủ Nhật'];

String _two(int v) => v.toString().padLeft(2, '0');

/// `Thứ Hai · 23/11`; Chủ nhật → `Chủ Nhật · 29/11`.
String dateLine(DateTime d) => '${_weekdayNames[d.weekday - 1]} · ${_two(d.day)}/${_two(d.month)}';

/// Nhãn cột 7 ngày: `T2`…`T7`, `CN`; hôm nay `NAY`.
String weekdayShort(DateTime d, {required bool today}) {
  if (today) return 'NAY';
  if (d.weekday == DateTime.sunday) return 'CN';
  return 'T${d.weekday + 1}';
}

/// Số triệu, tối đa [digits] chữ số thập phân, bỏ số 0 cuối, dấu phẩy.
String _millions(int minor, int digits) {
  var s = (minor / 1000000).toStringAsFixed(digits);
  if (s.contains('.')) {
    s = s.replaceFirst(RegExp(r'0+$'), '').replaceFirst(RegExp(r'\.$'), '');
  }
  if (s == '-0') s = '0';
  return s.replaceAll('.', ',');
}

/// Nhãn cột: `8420000` → `8,42`; `6100000` → `6,1`; `0` → `0`.
String millions(int minor) => _millions(minor, 2);

/// Tổng tuần: `52720000` → `52,7 triệu`.
String millionsTotal(int minor) => '${_millions(minor, 1)} triệu';

typedef HomeDelta = ({String text, bool up});

/// ▲/▼ % doanh thu so với hôm qua; hôm qua 0 → `null` (ẩn).
HomeDelta? percentDelta(int today, int yesterday) {
  if (yesterday == 0) return null;
  final pct = ((today - yesterday) / yesterday * 100).round();
  return (text: '${pct.abs()}%', up: pct >= 0);
}

/// ▲/▼ số đơn so với hôm qua; bằng nhau → `null` (ẩn).
HomeDelta? countDelta(int today, int yesterday) {
  if (today == yesterday) return null;
  return (text: '${(today - yesterday).abs()}', up: today > yesterday);
}
