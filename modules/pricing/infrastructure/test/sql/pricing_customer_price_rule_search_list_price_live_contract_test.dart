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
  test('015 search list price prefers Catalog-live then snapshot fallback', () {
    final sql = File(
      '${_repoRoot().path}/supabase/migrations/_drafts/'
      '015_pricing_customer_price_rule_search_list_price_live.sql',
    ).readAsStringSync();

    expect(
      sql,
      contains('-- Touches: search_customer_price_rules'),
    );
    expect(sql, contains('pricing.search_customer_price_rules('));
    expect(
      sql,
      contains('catalog._get_product_price_band_snapshot_for_pricing('),
    );
    expect(sql, contains('selected_list_price_minor'));
    expect(sql, contains('list_price_snapshot_minor'));
    expect(sql, contains("r.status <> 'deleted'"));
    expect(sql, contains('r.deleted_at is null'));
    expect(
      sql,
      contains("'list_price', case"),
    );
  });
}
