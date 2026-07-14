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
