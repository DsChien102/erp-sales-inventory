enum SqlObjectKind { function, view, trigger, policy }

/// A stateless SQL object definition found in a SQL script.
class SqlObject {
  const SqlObject({
    required this.kind,
    required this.schema,
    required this.name,
    required this.sql,
    this.signature,
    this.table,
  });

  final SqlObjectKind kind;

  /// Schema of the object; for triggers and policies, the schema of [table].
  final String schema;
  final String name;

  /// `schema.name(args)` with whitespace collapsed; functions only.
  final String? signature;

  /// `schema.table` the trigger or policy is attached to.
  final String? table;

  /// Verbatim statement from `create` up to and including the terminating `;`.
  final String sql;

  String get qualifiedName => '$schema.$name';
}

/// Parses function (every overload), view, trigger and policy definitions.
List<SqlObject> parseSqlObjects(String sql) {
  final objects = <SqlObject>[];
  for (final statement in splitSqlStatements(sql)) {
    final object = _parseStatement(statement);
    if (object != null) {
      objects.add(object);
    }
  }
  return objects;
}

/// Splits [sql] on top-level `;`, honouring quotes, dollar quotes and comments.
///
/// Leading whitespace and comments are excluded from each statement.
List<String> splitSqlStatements(String sql) {
  final statements = <String>[];
  var start = -1;
  var i = 0;

  void markStart() {
    if (start == -1) {
      start = i;
    }
  }

  while (i < sql.length) {
    final c = sql[i];
    if (sql.startsWith('--', i)) {
      final end = sql.indexOf('\n', i);
      i = end == -1 ? sql.length : end + 1;
    } else if (sql.startsWith('/*', i)) {
      final end = sql.indexOf('*/', i + 2);
      i = end == -1 ? sql.length : end + 2;
    } else if (c == "'" || c == '"') {
      markStart();
      i = _skipQuoted(sql, i, c);
    } else if ((c == r'$' ? _dollarTag(sql, i) : null) case final tag?) {
      markStart();
      final end = sql.indexOf(tag, i + tag.length);
      i = end == -1 ? sql.length : end + tag.length;
    } else if (c == ';') {
      if (start != -1) {
        statements.add(sql.substring(start, i + 1));
        start = -1;
      }
      i++;
    } else {
      if (c.trim().isNotEmpty) {
        markStart();
      }
      i++;
    }
  }
  if (start != -1 && sql.substring(start).trim().isNotEmpty) {
    statements.add(sql.substring(start).trimRight());
  }
  return statements;
}

int _skipQuoted(String sql, int i, String quote) {
  var j = i + 1;
  while (j < sql.length) {
    if (sql[j] == quote) {
      if (j + 1 < sql.length && sql[j + 1] == quote) {
        j += 2;
        continue;
      }
      return j + 1;
    }
    j++;
  }
  return sql.length;
}

final _dollarTagPattern = RegExp(r'\$([A-Za-z_][A-Za-z0-9_]*)?\$');

String? _dollarTag(String sql, int i) {
  if (i > 0 && RegExp(r'[A-Za-z0-9_]').hasMatch(sql[i - 1])) {
    return null;
  }
  final match = _dollarTagPattern.matchAsPrefix(sql, i);
  return match?.group(0);
}

const _ident = r'(?:"(?:[^"]|"")+"|[A-Za-z_][A-Za-z0-9_$]*)';
const _qualified = '($_ident)\\s*\\.\\s*($_ident)';

final _functionHead = RegExp(
  '^create\\s+(?:or\\s+replace\\s+)?function\\s+$_qualified\\s*\\(',
  caseSensitive: false,
);
final _viewHead = RegExp(
  '^create\\s+(?:or\\s+replace\\s+)?(?:(?:temp|temporary)\\s+)?'
  '(?:recursive\\s+)?(?:materialized\\s+)?view\\s+'
  '(?:if\\s+not\\s+exists\\s+)?$_qualified',
  caseSensitive: false,
);
final _triggerHead = RegExp(
  '^create\\s+(?:or\\s+replace\\s+)?(?:constraint\\s+)?trigger\\s+($_ident)'
  '[\\s\\S]*?\\bon\\s+$_qualified',
  caseSensitive: false,
);
final _policyHead = RegExp(
  '^create\\s+policy\\s+($_ident)\\s+on\\s+$_qualified',
  caseSensitive: false,
);

SqlObject? _parseStatement(String statement) {
  if (_functionHead.firstMatch(statement) case final m?) {
    final openParen = m.end - 1;
    final closeParen = _matchingParen(statement, openParen);
    if (closeParen == -1) {
      return null;
    }
    final schema = _identifier(m.group(1)!);
    final name = _identifier(m.group(2)!);
    final args = _collapseWhitespace(
      statement.substring(openParen + 1, closeParen),
    );
    return SqlObject(
      kind: SqlObjectKind.function,
      schema: schema,
      name: name,
      signature: '$schema.$name($args)',
      sql: statement,
    );
  }
  if (_viewHead.firstMatch(statement) case final m?) {
    return SqlObject(
      kind: SqlObjectKind.view,
      schema: _identifier(m.group(1)!),
      name: _identifier(m.group(2)!),
      sql: statement,
    );
  }
  for (final (pattern, kind) in [
    (_triggerHead, SqlObjectKind.trigger),
    (_policyHead, SqlObjectKind.policy),
  ]) {
    if (pattern.firstMatch(statement) case final m?) {
      final schema = _identifier(m.group(2)!);
      return SqlObject(
        kind: kind,
        schema: schema,
        name: _identifier(m.group(1)!),
        table: '$schema.${_identifier(m.group(3)!)}',
        sql: statement,
      );
    }
  }
  return null;
}

int _matchingParen(String sql, int open) {
  var depth = 0;
  var i = open;
  while (i < sql.length) {
    final c = sql[i];
    if (c == "'" || c == '"') {
      i = _skipQuoted(sql, i, c);
      continue;
    }
    if (c == '(') {
      depth++;
    } else if (c == ')') {
      depth--;
      if (depth == 0) {
        return i;
      }
    }
    i++;
  }
  return -1;
}

String _identifier(String raw) {
  if (raw.startsWith('"')) {
    return raw.substring(1, raw.length - 1).replaceAll('""', '"');
  }
  return raw.toLowerCase();
}

String _collapseWhitespace(String value) {
  return value
      .trim()
      .replaceAll(RegExp(r'\s+'), ' ')
      .replaceAll('( ', '(')
      .replaceAll(' )', ')');
}
