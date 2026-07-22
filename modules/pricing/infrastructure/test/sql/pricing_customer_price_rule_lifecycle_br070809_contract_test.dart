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

  test('013 import overlap draft promotes duplicate to warning and auto-disable', () {
    final sql = File(
      '${root.path}/supabase/migrations/_drafts/'
      '013_pricing_customer_price_rule_import_overlap_policy.sql',
    ).readAsStringSync();

    expect(
      sql,
      contains(
        '-- Touches: _evaluate_customer_price_rule_import_row, confirm_customer_price_rule_import',
      ),
    );
    expect(
      sql,
      contains("v_warnings := v_warnings || jsonb_build_array('DUPLICATE_ACTIVE_RULE')"),
    );
    expect(
      sql,
      isNot(contains("v_errors := v_errors || jsonb_build_array('DUPLICATE_ACTIVE_RULE')")),
    );
    expect(
      sql,
      isNot(
        contains(
          "error_codes = jsonb_build_array('DUPLICATE_ACTIVE_RULE')",
        ),
      ),
    );
    expect(
      sql,
      contains('pricing._auto_disable_overlapping_customer_price_rules('),
    );
    expect(sql, contains("'import_created'"));
    expect(sql, contains("'import_updated'"));
  });

  test('014 lifecycle draft adds delete resolve exclusion and deleted_at', () {
    final sql = File(
      '${root.path}/supabase/migrations/_drafts/'
      '014_pricing_customer_price_rule_lifecycle_eligibility.sql',
    ).readAsStringSync();

    expect(
      sql,
      contains(
        '-- Touches: _auto_disable_overlapping_customer_price_rules, delete_customer_price_rule, resolve_applicable_customer_price_rule',
      ),
    );
    expect(sql, contains('add column if not exists deleted_at timestamptz'));
    expect(
      sql,
      contains('customer_price_rules_deleted_at_status_consistency'),
    );
    expect(
      sql,
      contains('customer_price_rules_active_period_no_overlap'),
    );
    expect(sql, contains('btree_gist'));
    expect(sql, contains("'deleted'"));
    expect(sql, contains('pricing.delete_customer_price_rule('));
    expect(sql, contains('pricing.resolve_applicable_customer_price_rule('));
    expect(sql, contains("'pricing.customer_price_rule.delete'"));
    expect(sql, contains('r.deleted_at is null'));
    expect(
      sql,
      contains("'created', 'updated', 'disabled', 'reenabled', 'deleted'"),
    );
  });
}
