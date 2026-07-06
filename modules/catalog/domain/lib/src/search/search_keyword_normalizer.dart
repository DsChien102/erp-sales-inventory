final class SearchKeywordNormalizer {
  const SearchKeywordNormalizer._();

  static String? normalizeKeyword(String? keyword) {
    if (keyword == null) {
      return null;
    }
    final value = keyword.trim();
    return value.isEmpty ? null : value;
  }
}
