import 'dart:io';

import 'apply_dev_service.dart';
import 'sql_object_parser.dart';
import 'sql_source_discovery.dart';

enum SchemaDriftKind { missing, bodyMismatch, overloadCount }

class SchemaDriftMismatch {
  const SchemaDriftMismatch({
    required this.qualifiedName,
    required this.kind,
    this.detail,
  });

  final String qualifiedName;
  final SchemaDriftKind kind;
  final String? detail;

  @override
  String toString() =>
      '$qualifiedName (${kind.name})${detail == null ? '' : ': $detail'}';
}

class SchemaDriftResult {
  const SchemaDriftResult({
    required this.matched,
    required this.mismatches,
  });

  final List<String> matched;
  final List<SchemaDriftMismatch> mismatches;

  bool get isClean => mismatches.isEmpty;
}

/// Compares declarative SQL sources on disk with live Postgres definitions.
///
/// Intended for CI after `supabase db reset`: every source object must exist
/// in the DB with a matching normalized function/view body (triggers/policies:
/// existence via `pg_get_triggerdef` / `pg_policies`).
class SchemaDriftService {
  SchemaDriftService({
    required SqlExecutor executor,
    SqlSourceDiscovery? discovery,
  })  : _executor = executor,
        _discovery = discovery ?? SqlSourceDiscovery();

  final SqlExecutor _executor;
  final SqlSourceDiscovery _discovery;

  Future<SchemaDriftResult> check(Directory repoRoot) async {
    final sources = _discovery.discover(repoRoot);
    final matched = <String>[];
    final mismatches = <SchemaDriftMismatch>[];

    for (final source in sources) {
      final mismatch = switch (source.kind) {
        SqlObjectKind.function => await _checkFunction(source),
        SqlObjectKind.view => await _checkView(source),
        SqlObjectKind.trigger => await _checkTrigger(source),
        SqlObjectKind.policy => await _checkPolicy(source),
      };
      if (mismatch == null) {
        matched.add(source.qualifiedName);
      } else {
        mismatches.add(mismatch);
      }
    }

    return SchemaDriftResult(matched: matched, mismatches: mismatches);
  }

  Future<SchemaDriftMismatch?> _checkFunction(SqlSource source) async {
    final parts = source.qualifiedName.split('.');
    final schema = parts[0];
    final name = parts[1];
    final rows = await _executor.query(
      "select pg_get_functiondef(p.oid) as def, "
      "pg_get_function_identity_arguments(p.oid) as args "
      'from pg_proc p '
      'join pg_namespace n on n.oid = p.pronamespace '
      "where n.nspname = '${_escape(schema)}' "
      "and p.proname = '${_escape(name)}' "
      'order by 2;',
    );

    if (rows.isEmpty) {
      return SchemaDriftMismatch(
        qualifiedName: source.qualifiedName,
        kind: SchemaDriftKind.missing,
        detail: 'no function found in database',
      );
    }

    final sourceObjects = parseSqlObjects(source.content)
        .where((object) => object.kind == SqlObjectKind.function)
        .toList();
    if (rows.length != sourceObjects.length) {
      return SchemaDriftMismatch(
        qualifiedName: source.qualifiedName,
        kind: SchemaDriftKind.overloadCount,
        detail:
            'source has ${sourceObjects.length} overload(s), '
            'database has ${rows.length}',
      );
    }

    final dbBodies = [
      for (final row in rows) normalizeSqlBody(row['def']!.toString()),
    ]..sort();
    final sourceBodies = [
      for (final object in sourceObjects) normalizeSqlBody(object.sql),
    ]..sort();

    for (var index = 0; index < sourceBodies.length; index++) {
      if (sourceBodies[index] != dbBodies[index]) {
        return SchemaDriftMismatch(
          qualifiedName: source.qualifiedName,
          kind: SchemaDriftKind.bodyMismatch,
          detail: 'normalized body differs from pg_get_functiondef',
        );
      }
    }
    return null;
  }

  Future<SchemaDriftMismatch?> _checkView(SqlSource source) async {
    final rows = await _executor.query(
      "select pg_get_viewdef('${_escape(source.qualifiedName)}'::regclass, true) "
      'as def;',
    );
    if (rows.isEmpty || rows.first['def'] == null) {
      return SchemaDriftMismatch(
        qualifiedName: source.qualifiedName,
        kind: SchemaDriftKind.missing,
        detail: 'view not found',
      );
    }
    final sourceSql = parseSqlObjects(source.content).single.sql;
    final sourceBody = normalizeSqlBody(sourceSql);
    final dbBody = normalizeSqlBody(
      'create view ${source.qualifiedName} as ${rows.first['def']}',
    );
    if (sourceBody != dbBody) {
      return SchemaDriftMismatch(
        qualifiedName: source.qualifiedName,
        kind: SchemaDriftKind.bodyMismatch,
        detail: 'normalized view body differs from pg_get_viewdef',
      );
    }
    return null;
  }

  Future<SchemaDriftMismatch?> _checkTrigger(SqlSource source) async {
    final object = parseSqlObjects(source.content).single;
    final table = object.table;
    if (table == null) {
      return SchemaDriftMismatch(
        qualifiedName: source.qualifiedName,
        kind: SchemaDriftKind.missing,
        detail: 'trigger source missing ON table',
      );
    }
    final tableParts = table.split('.');
    final rows = await _executor.query(
      'select pg_get_triggerdef(t.oid, true) as def '
      'from pg_trigger t '
      'join pg_class c on c.oid = t.tgrelid '
      'join pg_namespace n on n.oid = c.relnamespace '
      'where not t.tgisinternal '
      "and t.tgname = '${_escape(object.name)}' "
      "and n.nspname = '${_escape(tableParts[0])}' "
      "and c.relname = '${_escape(tableParts[1])}';",
    );
    if (rows.isEmpty) {
      return SchemaDriftMismatch(
        qualifiedName: source.qualifiedName,
        kind: SchemaDriftKind.missing,
        detail: 'trigger not found on $table',
      );
    }
    if (normalizeSqlBody(object.sql) !=
        normalizeSqlBody(rows.first['def']!.toString())) {
      return SchemaDriftMismatch(
        qualifiedName: source.qualifiedName,
        kind: SchemaDriftKind.bodyMismatch,
        detail: 'normalized trigger differs from pg_get_triggerdef',
      );
    }
    return null;
  }

  Future<SchemaDriftMismatch?> _checkPolicy(SqlSource source) async {
    final object = parseSqlObjects(source.content).single;
    final table = object.table;
    if (table == null) {
      return SchemaDriftMismatch(
        qualifiedName: source.qualifiedName,
        kind: SchemaDriftKind.missing,
        detail: 'policy source missing ON table',
      );
    }
    final tableParts = table.split('.');
    final rows = await _executor.query(
      'select pol.polname as name '
      'from pg_policy pol '
      'join pg_class c on c.oid = pol.polrelid '
      'join pg_namespace n on n.oid = c.relnamespace '
      "where pol.polname = '${_escape(object.name)}' "
      "and n.nspname = '${_escape(tableParts[0])}' "
      "and c.relname = '${_escape(tableParts[1])}';",
    );
    if (rows.isEmpty) {
      return SchemaDriftMismatch(
        qualifiedName: source.qualifiedName,
        kind: SchemaDriftKind.missing,
        detail: 'policy not found on $table',
      );
    }
    // Policy expression formatting from catalogs is lossy; existence is enough.
    return null;
  }

  String _escape(String value) => value.replaceAll("'", "''");
}

/// Normalizes SQL so source files and `pg_get_*def` can be compared.
///
/// Focuses on the executable body: strips comments, collapses whitespace,
/// lowercases, maps common type aliases, and drops `or replace` / dollar-tag
/// differences.
String normalizeSqlBody(String sql) {
  var text = sql.replaceAll('\r\n', '\n');
  text = text.replaceAll(RegExp(r'/\*[\s\S]*?\*/'), ' ');
  text = text.replaceAll(RegExp(r'--[^\n]*'), ' ');
  text = text.toLowerCase();

  // Collapse dollar-quoted bodies to a generic marker content only.
  text = text.replaceAllMapped(
    RegExp(r'\$([a-zA-Z_]*)\$(.*?)\$\1\$', dotAll: true),
    (match) => ' \$body\$ ${match.group(2)!.trim()} \$body\$ ',
  );

  text = text
      .replaceAll('create or replace function', 'create function')
      .replaceAll('create or replace view', 'create view')
      .replaceAll(RegExp(r'\binteger\b'), 'int')
      .replaceAll(RegExp(r'\bcharacter varying\b'), 'varchar')
      .replaceAll(RegExp(r'\breturns\s+integer\b'), 'returns int');

  text = text.replaceAll(RegExp(r'\s+'), ' ').trim();
  if (text.endsWith(';')) {
    text = text.substring(0, text.length - 1).trimRight();
  }
  return text;
}
