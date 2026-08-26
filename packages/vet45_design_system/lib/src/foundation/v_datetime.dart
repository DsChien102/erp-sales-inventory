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

  static String _pad2(int n) => n.toString().padLeft(2, '0');
}
