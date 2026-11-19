/// Extracts `schema.function` names from CREATE FUNCTION statements.
List<String> extractFunctionsFromSql(String sql) {
  final pattern = RegExp(
    r'create\s+(?:or\s+replace\s+)?function\s+([a-z0-9_]+)\.([a-z0-9_]+)\s*\(',
    caseSensitive: false,
    multiLine: true,
  );

  final names = <String>[];
  for (final match in pattern.allMatches(sql)) {
    final qualified = '${match.group(1)}.${match.group(2)}';
    if (!names.contains(qualified)) {
      names.add(qualified);
    }
  }
  return names;
}

/// Returns bare function names (without schema) from SQL.
List<String> extractFunctionNamesFromSql(String sql) {
  final pattern = RegExp(
    r'create\s+(?:or\s+replace\s+)?function\s+[a-z0-9_]+\.([a-z0-9_]+)\s*\(',
    caseSensitive: false,
    multiLine: true,
  );

  final names = <String>[];
  for (final match in pattern.allMatches(sql)) {
    final name = match.group(1)!;
    if (!names.contains(name)) {
      names.add(name);
    }
  }
  return names;
}
