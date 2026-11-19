import 'sql_object_parser.dart';
import 'sql_source_discovery.dart';

/// Renders a declarative source the way generated migrations / apply-dev emit it:
/// functions and views verbatim; triggers/policies preceded by `drop … if exists`.
String renderDeclarativeSource(SqlSource source) {
  if (source.kind == SqlObjectKind.function ||
      source.kind == SqlObjectKind.view) {
    return source.content.trimRight();
  }

  final parts = <String>[];
  for (final object in parseSqlObjects(source.content)) {
    parts
      ..add(dropRelationIfExists(object))
      ..add(object.sql);
  }
  return parts.join('\n');
}

String dropRelationIfExists(SqlObject object) {
  final table = object.table;
  if (table == null) {
    throw StateError(
      'trigger/policy ${object.qualifiedName} is missing ON table',
    );
  }
  return dropRelationParts(
    kind: object.kind,
    name: object.name,
    table: table,
  );
}

/// Renders `drop … if exists` from a lock target `"name on schema.table"`.
String dropRelationFromLockTarget(SqlObjectKind kind, String target) {
  const separator = ' on ';
  final index = target.toLowerCase().lastIndexOf(separator);
  if (index == -1) {
    throw StateError('invalid trigger/policy lock target: $target');
  }
  return dropRelationParts(
    kind: kind,
    name: target.substring(0, index),
    table: target.substring(index + separator.length),
  );
}

String dropRelationParts({
  required SqlObjectKind kind,
  required String name,
  required String table,
}) {
  final quotedName = quoteIdent(name);
  final onTable = table.split('.').map(quoteIdent).join('.');
  return switch (kind) {
    SqlObjectKind.trigger =>
      'drop trigger if exists $quotedName on $onTable;',
    SqlObjectKind.policy =>
      'drop policy if exists $quotedName on $onTable;',
    SqlObjectKind.function || SqlObjectKind.view =>
      throw StateError('relation drop is only for trigger/policy'),
  };
}

/// Quotes identifiers that are not plain lowercase Postgres names.
String quoteIdent(String name) {
  if (RegExp(r'^[a-z_][a-z0-9_]*$').hasMatch(name)) {
    return name;
  }
  return '"${name.replaceAll('"', '""')}"';
}

final _regionPattern = RegExp(
  r'^--\s*region:\s*(\S+)\s*$',
  multiLine: true,
);

/// Named regions from a generated migration (`-- region: functions`, …).
///
/// Keys are region names (`pre`, `functions`, `views`, `triggers`, `policies`,
/// `post`). Values are the body after the marker (trimmed).
Map<String, String> extractMigrationRegions(String sql) {
  final matches = _regionPattern.allMatches(sql).toList();
  if (matches.isEmpty) {
    return const {};
  }

  final regions = <String, String>{};
  for (var index = 0; index < matches.length; index++) {
    final match = matches[index];
    final name = match.group(1)!;
    final start = match.end;
    final end = index + 1 < matches.length ? matches[index + 1].start : sql.length;
    regions[name] = sql.substring(start, end).trim();
  }
  return regions;
}

/// Object-kind regions that tools generate (never hand-edit).
const generatedObjectRegionNames = {
  'functions',
  'views',
  'triggers',
  'policies',
};

String regionNameForKind(SqlObjectKind kind) => objectKindDirs[kind]!;
