/// Vietnam-time (ICT) date/time display helpers.
///
/// Backend timestamps are UTC instants (Postgres `timestamptz`, parsed as UTC).
/// These helpers convert to **Indochina Time (UTC+7)** using a *fixed* offset —
/// never the device timezone — so the same wall-clock time is shown on a Vietnam
/// phone, a UTC simulator, and a UTC server alike. Vietnam has observed no DST
/// since 1975, so a constant +7 offset is exact.
///
/// The value returned by [toIct] is a UTC-labelled `DateTime` that carries ICT
/// wall-clock components. Only read its `year`/`month`/`day`/`hour`/`minute`
/// fields (or format it directly) — never call `toLocal()` on it, which would
/// re-apply the device offset and double-shift the time.
abstract final class VDateTime {
  const VDateTime._();

  /// Fixed Indochina Time offset (UTC+7, no DST).
  static const Duration ictOffset = Duration(hours: 7);

  /// The instant [value] expressed as ICT wall time (UTC-labelled).
  ///
  /// `value.toUtc()` normalises the input first, so both UTC-labelled and
  /// device-local `DateTime`s resolve to the same instant before the shift.
  static DateTime toIct(DateTime value) => value.toUtc().add(ictOffset);

  /// `dd/MM/yyyy`
  static String date(DateTime value) {
    final t = toIct(value);
    return '${_pad2(t.day)}/${_pad2(t.month)}/${t.year}';
  }

  /// `HH:mm`
  static String time(DateTime value) {
    final t = toIct(value);
    return '${_pad2(t.hour)}:${_pad2(t.minute)}';
  }

  /// `dd/MM/yyyy · HH:mm`
  static String dateTime(DateTime value) {
    final t = toIct(value);
    return '${_pad2(t.day)}/${_pad2(t.month)}/${t.year} · ${_pad2(t.hour)}:${_pad2(t.minute)}';
  }

  /// Formats a pure calendar date (`DateTime`) as `dd/MM/yyyy` without timezone shifting.
  ///
  /// Use this for pure dates like `dueAt`, `effectiveFrom`, where year/month/day
  /// must not be shifted by any offset.
  static String calendarDate(DateTime value) {
    return '${_pad2(value.day)}/${_pad2(value.month)}/${value.year}';
  }

  /// Parses a calendar date string (e.g. `YYYY-MM-DD`) and formats as `dd/MM/yyyy`
  /// without timezone interference.
  static String parseAndFormatCalendarDate(
    String? dateStr, {
    String fallback = 'Không giới hạn',
  }) {
    if (dateStr == null || dateStr.trim().isEmpty) return fallback;
    final trimmed = dateStr.trim();
    final parts = trimmed.split('-');
    if (parts.length == 3) {
      final year = parts[0];
      final month = parts[1].padLeft(2, '0');
      final day = parts[2].split('T').first.split(' ').first.padLeft(2, '0');
      return '$day/$month/$year';
    }
    try {
      final d = DateTime.parse(trimmed);
      return '${_pad2(d.day)}/${_pad2(d.month)}/${d.year}';
    } catch (_) {
      return trimmed;
    }
  }

  /// Returns the current business date in Vietnam (ICT).
  ///
  /// The returned `DateTime` has `hour = 0, minute = 0, second = 0` in UTC,
  /// carrying the Vietnam calendar date.
  static DateTime currentBusinessDate([DateTime? now]) {
    final t = toIct(now ?? DateTime.now());
    return DateTime.utc(t.year, t.month, t.day);
  }

  /// Returns the UTC instant range `[fromUtc, toUtc)` corresponding to
  /// full Vietnam business day(s).
  ///
  /// For example, for a single day in ICT (00:00:00 to 23:59:59.999),
  /// [fromUtc] is 17:00:00 UTC of the previous day, and [toUtc] is 17:00:00 UTC
  /// of the target day.
  static ({DateTime fromUtc, DateTime toUtc}) businessDayRangeUtc({
    DateTime? now,
    int days = 1,
  }) {
    final ict = toIct(now ?? DateTime.now());
    final endIctDate = DateTime.utc(ict.year, ict.month, ict.day + 1);
    final startIctDate = DateTime.utc(ict.year, ict.month, ict.day - (days - 1));
    return (
      fromUtc: startIctDate.subtract(ictOffset),
      toUtc: endIctDate.subtract(ictOffset),
    );
  }

  static String _pad2(int n) => n.toString().padLeft(2, '0');
}
