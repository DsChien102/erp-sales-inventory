/// Formats a custom field group name for display without changing stored data.
String customFieldGroupDisplayName(String name) {
  final trimmed = name.trim();
  if (trimmed.isEmpty) {
    return trimmed;
  }

  final firstRune = String.fromCharCode(trimmed.runes.first).toUpperCase();
  final remainingRunes = String.fromCharCodes(trimmed.runes.skip(1));
  return '$firstRune$remainingRunes';
}
