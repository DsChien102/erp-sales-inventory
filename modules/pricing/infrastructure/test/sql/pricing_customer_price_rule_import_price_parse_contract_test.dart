import 'dart:io';

import 'package:test/test.dart';

Directory _repoRoot() {
  var dir = Directory.current;
  while (!Directory('${dir.path}/supabase/migrations/_drafts').existsSync()) {
    final parent = dir.parent;
    if (parent.path == dir.path) break;
    dir = parent;
  }
  return dir;
}

void main() {
  final root = _repoRoot();

  test('018 declares exact touches and remains draft-only', () {
    final sql = _sql(root);

    expect(_touches(sql), {'_evaluate_customer_price_rule_import_row'});
    expect(_touches(sql), _createdFunctions(sql));

    final timestamped = Directory('${root.path}/supabase/migrations')
        .listSync()
        .whereType<File>()
        .where(
          (file) => RegExp(
            r'^[0-9].*price_parse.*\.sql$',
          ).hasMatch(file.uri.pathSegments.last),
        )
        .toList();
    expect(timestamped, isEmpty);
  });

  test('evaluator parses Excel N.0 VN thousands and rejects fraction', () {
    final evaluator = _functionBody(
      _sql(root),
      '_evaluate_customer_price_rule_import_row',
    );

    expect(evaluator, contains(r"^\d{1,3}(\.\d{3})+$"));
    expect(evaluator, contains('100.000'));
    expect(evaluator, contains(r'^\d+\.(0{1,2})$'));
    expect(evaluator, contains('100000.0'));
    expect(evaluator, contains("split_part(v_price_text, '.', 1)"));
    expect(evaluator, contains(r'^\d{1,3}(,\d{3})+$'));
    expect(
      evaluator,
      contains("jsonb_build_array('INVALID_PRICE')"),
    );
    expect(evaluator, contains('non-zero fractional part'));
    expect(
      evaluator,
      isNot(
        contains(
          "regexp_replace(coalesce(v_price_text, ''), '[,._[:space:]]', '', 'g')",
        ),
      ),
    );
  });
}

String _sql(Directory root) => File(
  '${root.path}/supabase/migrations/_drafts/'
  '018_pricing_customer_price_rule_import_price_parse.sql',
).readAsStringSync();

Set<String> _createdFunctions(String sql) => RegExp(
  r'create\s+or\s+replace\s+function\s+pricing\.([a-z0-9_]+)',
  caseSensitive: false,
).allMatches(sql).map((match) => match.group(1)!).toSet();

Set<String> _touches(String sql) {
  final line = RegExp(
    r'^-- Touches:\s*(.+)$',
    multiLine: true,
  ).firstMatch(sql)?.group(1);
  return line
          ?.split(',')
          .map((name) => name.trim())
          .where((name) => name.isNotEmpty)
          .toSet() ??
      const {};
}

String _functionBody(String sql, String name) {
  final start = sql.indexOf('function pricing.$name(');
  expect(start, greaterThan(-1), reason: 'Function $name must exist.');
  final end = sql.indexOf('\n\$\$;', start);
  expect(end, greaterThan(start), reason: 'Function $name must terminate.');
  return sql.substring(start, end);
}
