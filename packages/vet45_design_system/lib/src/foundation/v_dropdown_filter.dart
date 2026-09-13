import 'package:flutter/material.dart';

import 'v_text_normalizer.dart';

List<DropdownMenuEntry<T>> filterDropdownEntries<T>(
  List<DropdownMenuEntry<T>> entries,
  String filter,
) {
  final normalizedFilter = VTextNormalizer.normalizeForSearch(filter);
  return entries
      .where(
        (entry) => VTextNormalizer.normalizeForSearch(entry.label).contains(
          normalizedFilter,
        ),
      )
      .toList();
}

/// Default combobox filter: normalized [searchText] contains normalized [query].
bool matchesComboboxSearch(String query, String searchText) {
  return matchesNormalizedComboboxSearch(
    VTextNormalizer.normalizeForSearch(query),
    searchText,
  );
}

/// Same as [matchesComboboxSearch] when [normalizedQuery] is already computed.
bool matchesNormalizedComboboxSearch(String normalizedQuery, String searchText) {
  if (normalizedQuery.isEmpty) return true;
  return VTextNormalizer.normalizeForSearch(searchText).contains(normalizedQuery);
}
