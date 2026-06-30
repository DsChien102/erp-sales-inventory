final class SearchKeywordNormalizer {
  const SearchKeywordNormalizer._();

  static String? normalizeKeyword(String? keyword) {
    if (keyword == null) {
      return null;
    }
    final value = keyword.trim();
    return value.isEmpty ? null : value;
  }

  static String normalizePhoneKeyword(String keyword) {
    final trimmed = keyword.trim();
    final withPlus = trimmed.startsWith('+');
    final digits = trimmed.replaceAll(RegExp(r'[^0-9]'), '');
    return withPlus ? '+$digits' : digits;
  }
}
