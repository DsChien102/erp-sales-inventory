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
      '011_pricing_remembered_price_from_order_s9.sql';

  test('S9 draft header, dependencies, and Touches match replaced functions', () {
    final sql = File(sqlPath).readAsStringSync();

    expect(sql, contains('-- Kind: patch'));
    expect(sql, contains('-- Intent: pricing_remembered_price_from_order_s9'));
    expect(
      sql,
      contains(
        '-- Touches: _remembered_price_outcome, save_remembered_price_from_order, get_customer_price_rule_detail',
      ),
    );
    expect(sql, contains('004_pricing_customer_price_rule_s1.sql'));
    expect(sql, contains('001_partner_pricing_customer_snapshot.sql'));
    expect(sql, contains('002_catalog_pricing_price_band_snapshot.sql'));
    expect(_touches(sql), _createdFunctions(sql));
  });

  test('no timestamped S9 migration and no REGISTRY edit', () {
    final canonical = Directory('${root.path}/supabase/migrations')
        .listSync()
        .whereType<File>()
        .where(
          (file) => RegExp(
            r'^[0-9].*remembered_price.*\.sql$',
          ).hasMatch(file.uri.pathSegments.last),
        )
        .toList();
    expect(canonical, isEmpty);
    expect(
      File('${root.path}/supabase/migrations/REGISTRY.yaml').readAsStringSync(),
      isNot(contains('save_remembered_price_from_order')),
    );
  });

  test('S9 draft defines remembered_price_requests schema and security', () {
    final sql = File(sqlPath).readAsStringSync();

    expect(
      sql,
      contains(
        'create extension if not exists pgcrypto with schema extensions',
      ),
    );
    expect(
      sql,
      contains('create table if not exists pricing.remembered_price_requests'),
    );
    expect(sql, contains('unique (tenant_id, idempotency_key)'));
    expect(sql, contains('source_order_id'));
    expect(sql, contains('source_order_line_id'));
    expect(sql, contains('sold_price_minor'));
    expect(sql, contains('currency_code'));
    expect(sql, contains('sold_at'));
    expect(sql, contains('payload_hash'));
    expect(sql, contains('result_type'));
    expect(sql, contains('reason_code'));
    expect(sql, contains('rule_id'));
    expect(sql, contains('rule_version'));
    expect(sql, contains('warnings'));
    expect(sql, contains('enable row level security'));
    expect(sql, contains('revoke all on pricing.remembered_price_requests'));
    expect(sql, contains('remembered_price_requests_tenant_idempotency_idx'));
    expect(sql, contains('remembered_price_requests_order_line_idx'));
    expect(sql, contains('remembered_price_requests_result_rule_idx'));
  });

  test('S9 draft extends rule type, activity, and source trace columns', () {
    final sql = File(sqlPath).readAsStringSync();

    expect(sql, contains("'remembered_price'"));
    expect(sql, contains("'special_price'"));
    expect(sql, contains("'memory_created'"));
    expect(sql, contains("'memory_updated'"));
    expect(sql, contains("'import_created'"));
    expect(sql, contains("'import_updated'"));
    expect(sql, contains('source_memory_request_id'));
    expect(sql, contains('source_sold_at'));
    expect(sql, contains('source_memory_request_id uuid'));
    expect(sql, contains('references pricing.remembered_price_requests(id)'));
  });

  test('S9 public RPC uses exact params and save_memory permission', () {
    final sql = File(sqlPath).readAsStringSync();
    final save = _functionBody(sql, 'save_remembered_price_from_order');

    expect(sql, contains('pricing.save_remembered_price_from_order('));
    expect(save, contains('p_tenant_id uuid'));
    expect(save, contains('p_request_id uuid'));
    expect(save, contains('p_source_order_id uuid'));
    expect(save, contains('p_source_order_line_id uuid'));
    expect(save, contains('p_customer_id uuid'));
    expect(save, contains('p_product_id uuid'));
    expect(save, contains('p_product_unit_id uuid'));
    expect(save, contains('p_sold_price_minor bigint'));
    expect(save, contains('p_currency_code text'));
    expect(save, contains('p_sold_at timestamptz'));
    expect(save, contains('p_idempotency_key text'));
    expect(save, contains("'pricing.customer_price_rule.save_memory'"));
    expect(save, contains('extensions.digest('));
    expect(save, contains("'sha256'"));
  });

  test('S9 save RPC acquires idempotency lock before replay lookup', () {
    final sql = File(sqlPath).readAsStringSync();
    final save = _functionBody(sql, 'save_remembered_price_from_order');

    final lockIndex = save.indexOf("':memory:idempotency:'");
    final replayIndex = save.indexOf(
      '_remembered_price_outcome(v_existing, true)',
    );
    final partnerIndex = save.indexOf(
      'partner._get_customer_snapshot_for_pricing(',
    );

    expect(lockIndex, greaterThan(-1));
    expect(replayIndex, greaterThan(lockIndex));
    expect(partnerIndex, greaterThan(replayIndex));
  });

  test('S9 save RPC handles idempotency conflict and anonymous skip', () {
    final sql = File(sqlPath).readAsStringSync();
    final save = _functionBody(sql, 'save_remembered_price_from_order');

    expect(save, contains("'IDEMPOTENCY_CONFLICT'"));
    expect(save, contains("'ANONYMOUS_CUSTOMER'"));
    expect(save, contains("'skipped'"));
  });

  test('S9 save RPC uses shared rule-key lock and provider-only reads', () {
    final sql = File(sqlPath).readAsStringSync();
    final save = _functionBody(sql, 'save_remembered_price_from_order');

    expect(save, contains("':rule:'"));
    expect(
      save,
      contains('catalog._get_product_price_band_snapshot_for_pricing('),
    );
    expect(
      RegExp(r'from\s+partner\.', caseSensitive: false).hasMatch(save),
      isFalse,
    );
    expect(
      RegExp(r'from\s+catalog\.', caseSensitive: false).hasMatch(save),
      isFalse,
    );
  });

  test('S9 save RPC stores deterministic business outcomes', () {
    final sql = File(sqlPath).readAsStringSync();
    final save = _functionBody(sql, 'save_remembered_price_from_order');

    for (final code in [
      'REFERENCE_INVALID',
      'BELOW_FLOOR_BLOCKED',
      'MANUAL_RULE_PROTECTED',
      'REMEMBERED_RULE_DISABLED',
      'RULE_REVIEW_REQUIRED',
      'DUPLICATE_ACTIVE_RULE',
      'STALE_SALE_EVENT',
      'PRICE_UNCHANGED',
    ]) {
      expect(save, contains("'$code'"), reason: 'missing outcome $code');
    }
    expect(save, contains("'remembered_price'"));
    expect(save, contains("'sales_order'"));
    expect(save, contains("'memory_created'"));
    expect(save, contains("'memory_updated'"));
    expect(save, contains("'memory:' || p_request_id::text"));
    expect(save, contains("at time zone 'UTC'"));
  });

  test('S9 helper is internal-only and public RPC is granted to clients', () {
    final sql = File(sqlPath).readAsStringSync();

    expect(sql, contains('pricing._remembered_price_outcome('));
    expect(
      sql,
      contains('revoke all on function pricing._remembered_price_outcome'),
    );
    expect(
      sql,
      contains(
        'grant execute on function pricing.save_remembered_price_from_order',
      ),
    );
    expect(sql, contains('to authenticated, service_role'));
  });

  test('S9 detail projection exposes redacted source_memory_request_id', () {
    final sql = File(sqlPath).readAsStringSync();
    final detail = _functionBody(sql, 'get_customer_price_rule_detail');

    expect(detail, contains('source_memory_request_id'));
    expect(detail, contains('view_history'));
    expect(detail, contains('_get_customer_price_rule_detail_s3('));
    expect(detail, contains('source_order_id'));
    expect(detail, contains('source_import_id'));
  });

  test('S9 save RPC does not swallow technical errors', () {
    final sql = File(sqlPath).readAsStringSync();
    final save = _functionBody(sql, 'save_remembered_price_from_order');

    expect(save, isNot(contains('exception when others')));
    expect(save, isNot(contains('sqlstate')));
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
