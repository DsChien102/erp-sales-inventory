import 'dart:io';

import 'package:test/test.dart';

Directory _repoRoot() {
  var dir = Directory.current;
  while (!Directory('${dir.path}/supabase/migrations/_drafts').existsSync()) {
    final parent = dir.parent;
    if (parent.path == dir.path) {
      break;
    }
    dir = parent;
  }
  return dir;
}

void main() {
  final root = _repoRoot();
  final sqlPath =
      '${root.path}/supabase/migrations/_drafts/'
      'pricing_customer_price_rule_history_s10.sql';

  test('S10 draft header, dependencies, and Touches match replaced functions', () {
    final sql = File(sqlPath).readAsStringSync();

    expect(sql, contains('-- Kind: patch'));
    expect(sql, contains('-- Intent: pricing_customer_price_rule_history_s10'));
    expect(
      sql,
      contains(
        '-- Touches: _customer_price_rule_history_snapshot, get_customer_price_rule_history',
      ),
    );
    expect(sql, contains('pricing_customer_price_rule_s1.sql'));
    expect(sql, contains('pricing_customer_price_rule_update_s5.sql'));
    expect(sql, contains('pricing_customer_price_rule_disable_s6.sql'));
    expect(sql, contains('pricing_customer_price_rule_reenable_s7.sql'));
    expect(sql, contains('pricing_customer_price_rule_import_s8.sql'));
    expect(sql, contains('pricing_remembered_price_from_order_s9.sql'));
    expect(_touches(sql), _createdFunctions(sql));
  });

  test('no timestamped S10 migration and no REGISTRY edit', () {
    final canonical = Directory('${root.path}/supabase/migrations')
        .listSync()
        .whereType<File>()
        .where(
          (file) => RegExp(
            r'^[0-9].*customer_price_rule_history.*\.sql$',
          ).hasMatch(file.uri.pathSegments.last),
        )
        .toList();
    expect(canonical, isEmpty);
    expect(
      File('${root.path}/supabase/migrations/REGISTRY.yaml').readAsStringSync(),
      isNot(contains('get_customer_price_rule_history')),
    );
  });

  test('S10 covering keyset index and public RPC signature', () {
    final sql = File(sqlPath).readAsStringSync();
    final history = _functionBody(sql, 'get_customer_price_rule_history');

    expect(sql, contains('customer_price_rule_activities_history_page_idx'));
    expect(sql, contains('created_at desc'));
    expect(sql, contains('id desc'));
    expect(history, contains('p_tenant_id uuid'));
    expect(history, contains('p_rule_id uuid'));
    expect(history, contains('p_cursor text default null'));
    expect(history, contains('p_limit integer default 50'));
    expect(history, contains('language plpgsql'));
    expect(history, contains('stable'));
    expect(history, contains('security definer'));
    expect(history, contains("set search_path = ''"));
  });

  test('S10 checks permission before rule existence', () {
    final sql = File(sqlPath).readAsStringSync();
    final history = _functionBody(sql, 'get_customer_price_rule_history');

    final permissionIndex = history.indexOf(
      "'pricing.customer_price_rule.view_history'",
    );
    final ruleLookupIndex = history.indexOf(
      'from pricing.customer_price_rules r',
    );
    final notFoundIndex = history.indexOf("'NOT_FOUND'");

    expect(permissionIndex, greaterThan(-1));
    expect(ruleLookupIndex, greaterThan(permissionIndex));
    expect(notFoundIndex, greaterThan(ruleLookupIndex));
    expect(history, contains("r.status <> 'deleted'"));
  });

  test('S10 cursor decode, tuple predicate, limit+1, and next cursor encoding', () {
    final sql = File(sqlPath).readAsStringSync();
    final history = _functionBody(sql, 'get_customer_price_rule_history');

    expect(history, contains("translate(p_cursor, '-_', '+/')"));
    expect(history, contains("decode(v_encoded, 'base64')"));
    expect(history, contains("'createdAt'"));
    expect(history, contains("jsonb_build_object('cursor', 'invalid')"));
    expect(history, contains('a.created_at < v_cursor_created_at'));
    expect(
      history,
      contains('a.created_at = v_cursor_created_at'),
    );
    expect(history, contains('and a.id < v_cursor_id'));
    expect(history, contains('limit p_limit + 1'));
    expect(history, contains("translate("));
    expect(history, contains("'base64'"));
    expect(history, contains("'+/'"));
    expect(history, contains("'-_'"));
  });

  test('S10 maps actor fallback, source fallback, reason, and S8/S9 traces', () {
    final sql = File(sqlPath).readAsStringSync();
    final history = _functionBody(sql, 'get_customer_price_rule_history');

    expect(history, contains("'System/Migration'"));
    expect(history, contains('left(r.created_by::text, 8)'));
    expect(history, contains("r.new_value ->> 'source_type'"));
    expect(history, contains("r.old_value ->> 'source_type'"));
    expect(history, contains("'import_created'"));
    expect(history, contains("'import_updated'"));
    expect(history, contains("'excel_import'"));
    expect(history, contains("'memory_created'"));
    expect(history, contains("'memory_updated'"));
    expect(history, contains("'sales_order'"));
    expect(history, contains('v_rule.source_type'));
    expect(history, contains("r.new_value ->> 'reason'"));
    expect(history, contains("r.new_value ->> 'disabled_reason'"));
    expect(history, contains("'import_id', d.import_id"));
    expect(history, contains("'import_row_id', d.import_row_id"));
    expect(history, contains("'order_id', d.source_order_id"));
    expect(history, contains("'order_line_id', d.source_order_line_id"));
    expect(history, contains("'memory_request_id', d.source_memory_request_id"));
    expect(history, contains("'sold_at', d.source_sold_at"));
  });

  test('S10 floor sanitizer redacts known keys without mutating DB rows', () {
    final sql = File(sqlPath).readAsStringSync();
    final helper = _functionBody(sql, '_customer_price_rule_history_snapshot');
    final history = _functionBody(sql, 'get_customer_price_rule_history');

    expect(helper, contains("'floor_price_snapshot_minor'"));
    expect(helper, contains("'floor_price_minor'"));
    expect(helper, contains("'floor_price'"));
    expect(helper, contains('p_can_view_floor'));
    expect(history, contains('override_floor_price'));
    expect(history, contains('sensitive_values_hidden'));
    expect(history, isNot(contains('update pricing.customer_price_rule_activities')));
    expect(history, isNot(contains('delete from pricing.customer_price_rule_activities')));
  });

  test('S10 helper is internal-only and public RPC is granted', () {
    final sql = File(sqlPath).readAsStringSync();

    expect(
      sql,
      contains(
        'revoke all on function pricing._customer_price_rule_history_snapshot',
      ),
    );
    expect(
      sql,
      contains(
        'revoke all on function pricing.get_customer_price_rule_history',
      ),
    );
    expect(
      sql,
      contains(
        'grant execute on function pricing.get_customer_price_rule_history',
      ),
    );
    expect(sql, contains('to authenticated, service_role'));
    expect(sql, isNot(contains('grant select on pricing.customer_price_rule_activities')));
  });
}

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
