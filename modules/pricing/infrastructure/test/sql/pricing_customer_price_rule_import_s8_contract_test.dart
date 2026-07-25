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

  test('catalog import resolver draft is internal-only provider', () {
    final sql = File(
      '${root.path}/supabase/migrations/_drafts/'
      '003_catalog_pricing_import_product_unit_resolver.sql',
    ).readAsStringSync();

    expect(
      sql,
      contains('-- Touches: _resolve_product_unit_for_pricing_import'),
    );
    expect(sql, contains('catalog._resolve_product_unit_for_pricing_import('));
    expect(sql, contains("'resolution', 'resolved'"));
    expect(sql, contains("'resolution', 'not_found'"));
    expect(sql, contains("'resolution', 'ambiguous'"));
    expect(sql, contains('is_base_unit = true'));
    expect(sql, contains('p.reference_id = v_reference'));
    expect(sql, isNot(contains('lower(btrim(p.reference_id))')));
    expect(sql, contains("p.business_status = 'active'"));
    expect(sql, contains('pu.is_active = true'));
    expect(sql, contains("'minor_units_valid'"));
    expect(sql, isNot(contains('trunc(')));
    expect(sql, contains('count(distinct pu.id)'));
    expect(sql, contains('from public, anon, authenticated, service_role'));
  });

  test('S8 pricing import draft defines schema, RPCs, and boundaries', () {
    final sql = File(
      '${root.path}/supabase/migrations/_drafts/'
      '010_pricing_customer_price_rule_import_s8.sql',
    ).readAsStringSync();

    expect(_touches(sql), _createdFunctions(sql));
    expect(sql, contains('003_catalog_pricing_import_product_unit_resolver.sql'));
    expect(
      sql,
      contains(
        'create table if not exists pricing.customer_price_rule_imports',
      ),
    );
    expect(
      sql,
      contains(
        'create table if not exists pricing.customer_price_rule_import_rows',
      ),
    );
    expect(sql, contains('unique (import_id, row_number)'));
    expect(sql, contains('enable row level security'));
    expect(sql, contains('revoke all on pricing.customer_price_rule_imports'));
    expect(sql, contains('customer_price_rule_import_rows_page_idx'));
    expect(sql, contains("'excel_import'"));
    expect(sql, contains('source_import_id'));
    expect(sql, contains('source_import_row_id'));
    expect(
      sql,
      contains(
        'source_import_id uuid references '
        'pricing.customer_price_rule_imports(id)',
      ),
    );
    expect(
      sql,
      contains(
        'source_import_row_id uuid references '
        'pricing.customer_price_rule_import_rows(id)',
      ),
    );
    expect(
      sql,
      contains(
        'import_id uuid references pricing.customer_price_rule_imports(id)',
      ),
    );
    expect(
      sql,
      contains(
        'import_row_id uuid references '
        'pricing.customer_price_rule_import_rows(id)',
      ),
    );
    expect(sql, contains("'import_created'"));
    expect(sql, contains("'import_updated'"));
    expect(sql, contains("'pricing.customer_price_rule.import'"));
    expect(sql, contains('pricing.create_customer_price_rule_import('));
    expect(sql, contains('pricing.get_customer_price_rule_import('));
    expect(sql, contains('pricing.confirm_customer_price_rule_import('));
    expect(sql, contains('pricing.cancel_customer_price_rule_import('));
    expect(sql, contains('pricing._evaluate_customer_price_rule_import_row('));
    expect(sql, contains('partner._get_customer_snapshot_for_pricing('));
    expect(sql, contains('catalog._resolve_product_unit_for_pricing_import('));
    expect(sql, contains("'IMPORT_MODE_MISMATCH'"));
    expect(sql, contains("'EFFECTIVE_FROM_DEFAULTED'"));
    expect(sql, contains("'BELOW_FLOOR_BLOCKED'"));
    expect(sql, contains("'DUPLICATE_ACTIVE_RULE'"));
    expect(sql, contains('order by r.row_number asc, r.id asc'));
    expect(sql, contains('for update'));
    expect(sql, contains('pg_advisory_xact_lock'));
    expect(sql, contains('hashtextextended'));
    expect(sql, contains("'is_replay', true"));
    expect(sql, contains("'reason', 'acknowledgementRequired'"));
    expect(
      RegExp(r'from\s+partner\.', caseSensitive: false).hasMatch(sql),
      isFalse,
    );
    expect(
      RegExp(r'from\s+catalog\.', caseSensitive: false).hasMatch(sql),
      isFalse,
    );
  });

  test('S8 preview redacts internal floor and matched-rule identifiers', () {
    final sql = File(
      '${root.path}/supabase/migrations/_drafts/'
      '010_pricing_customer_price_rule_import_s8.sql',
    ).readAsStringSync();
    final preview = _functionBody(sql, '_import_row_preview');

    expect(preview, contains('p_can_view_rules boolean'));
    expect(preview, contains('p_can_view_floor boolean'));
    expect(preview, contains("- 'floor_price_minor'"));
    expect(
      preview,
      contains('when p_can_view_rules then p_row.matched_rule_id'),
    );
    expect(preview, isNot(contains('p_row.product_snapshot::text')));
  });

  test(
    'S8 cursor is integer Base64URL and maps invalid input to validation',
    () {
      final sql = File(
        '${root.path}/supabase/migrations/_drafts/'
        '010_pricing_customer_price_rule_import_s8.sql',
      ).readAsStringSync();
      final getBody = _functionBody(sql, 'get_customer_price_rule_import');

      expect(
        getBody,
        contains("'rowNumber', (v_items -> -1 ->> 'row_number')::integer"),
      );
      expect(getBody, contains("translate("));
      expect(getBody, contains("'+/'"));
      expect(getBody, contains("'-_'"));
      expect(getBody, contains("rtrim("));
      expect(getBody, contains("'VALIDATION_ERROR'"));
    },
  );

  test('S8 confirm performs authoritative rule and activity mutations', () {
    final sql = File(
      '${root.path}/supabase/migrations/_drafts/'
      '010_pricing_customer_price_rule_import_s8.sql',
    ).readAsStringSync();
    final confirm = _functionBody(sql, 'confirm_customer_price_rule_import');

    expect(confirm, contains('partner._get_customer_snapshot_for_pricing('));
    expect(
      confirm,
      contains('catalog._resolve_product_unit_for_pricing_import('),
    );
    expect(confirm, contains('insert into pricing.customer_price_rules'));
    expect(confirm, contains('update pricing.customer_price_rules'));
    expect(
      confirm,
      contains('insert into pricing.customer_price_rule_activities'),
    );
    expect(confirm, contains("'excel_import'"));
    expect(confirm, contains('source_import_id'));
    expect(confirm, contains('source_import_row_id'));
    expect(confirm, contains('import_id'));
    expect(confirm, contains('import_row_id'));
    expect(
      confirm,
      contains(
        'v_row.matched_rule_version is distinct from '
        "(v_eval ->> 'matched_rule_version')::integer",
      ),
    );
    expect(
      confirm.indexOf('pg_advisory_xact_lock'),
      lessThan(confirm.indexOf('into v_conflicting_rule_id')),
    );
    expect(
      confirm,
      isNot(contains('coalesce(v_row.matched_rule_id, gen_random_uuid())')),
    );
  });

  test('S8 confirm policy keeps terminal replay before version rejection', () {
    final sql = File(
      '${root.path}/supabase/migrations/_drafts/'
      '010_pricing_customer_price_rule_import_s8.sql',
    ).readAsStringSync();

    final replayIndex = sql.indexOf("'is_replay', true");
    final versionCheckIndex = sql.indexOf(
      "v_batch.version <> p_expected_version",
      replayIndex,
    );
    expect(replayIndex, greaterThan(-1));
    expect(versionCheckIndex, greaterThan(replayIndex));
  });

  test('no timestamped migration was added for S8', () {
    final canonical = Directory('${root.path}/supabase/migrations')
        .listSync()
        .whereType<File>()
        .where(
          (file) => RegExp(
            r'^[0-9].*import.*\.sql$',
          ).hasMatch(file.uri.pathSegments.last),
        )
        .toList();
    expect(canonical, isEmpty);
  });
}

Set<String> _createdFunctions(String sql) => RegExp(
  r'create\s+or\s+replace\s+function\s+(?:pricing|catalog)\.([a-z0-9_]+)',
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
