String formatDate(DateTime? dateTime) {
  if (dateTime == null) return '-';
  final date = dateTime.toLocal();
  final hour = date.hour.toString().padLeft(2, '0');
  final minute = date.minute.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  final month = date.month.toString().padLeft(2, '0');
  final year = date.year;
  return '$hour:$minute $day/$month/$year';
}

String formatCurrency(int? amount) {
  if (amount == null) return '0 đ';
  final isNegative = amount < 0;
  final absAmount = amount.abs();
  final formatted = absAmount.toString().replaceAllMapped(
    RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
    (Match m) => '${m[1]}.',
  );
  return '${isNegative ? "-" : ""}$formatted đ';
}

(String? contactPerson, String? actualNote) parseNote(String? rawNote) {
  if (rawNote == null || rawNote.isEmpty) return (null, null);
  final regex = RegExp(
    r'^\[Người liên hệ:\s*([^\]]+)\]\s*(.*)$',
    dotAll: true,
  );
  final match = regex.firstMatch(rawNote);
  if (match != null) {
    final contact = match.group(1)?.trim();
    final actual = match.group(2)?.trim();
    return (contact, actual == null || actual.isEmpty ? null : actual);
  }
  return (null, rawNote);
}
