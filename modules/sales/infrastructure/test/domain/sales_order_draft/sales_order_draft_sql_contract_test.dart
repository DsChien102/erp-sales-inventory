import 'dart:io';

import 'package:test/test.dart';

void main() {
  late final String sql;
  late final String normalizedSql;

  setUpAll(() {
    sql = _draftSqlFile().readAsStringSync();
    normalizedSql = _squash(sql);
  });

  test('draft RPC owner declares rebuild header and five public RPCs', () {
    expect(sql, contains('-- Kind: draft'));
    expect(sql, contains('-- Intent: sales_draft_rpcs'));
    expect(sql, contains('sales.save_sales_order_draft'));
    expect(sql, contains('sales.update_sales_order_draft'));
    expect(sql, contains('sales.list_sales_order_drafts'));
    expect(sql, contains('sales.get_sales_order_draft_for_restore'));
    expect(sql, contains('sales.cancel_sales_order_draft'));
    expect(sql, contains('create or replace function sales.save_sales_order_draft'));
    expect(sql, contains('create or replace function sales.update_sales_order_draft'));
    expect(sql, contains('create or replace function sales.list_sales_order_drafts'));
    expect(sql, contains('create or replace function sales.get_sales_order_draft_for_restore'));
    expect(sql, contains('create or replace function sales.cancel_sales_order_draft'));
    expect(sql, isNot(contains('create table public.')));
    expect(sql, isNot(contains('create table sales.')));
  });

  test('uses shared actor and idempotency helpers instead of inline duplicates', () {
    expect(sql, isNot(contains('create or replace function sales._assert_draft_actor(')));
    expect(sql, isNot(contains('create or replace function sales._begin_sales_idempotency(')));

    for (final function in <String>[
      'sales.save_sales_order_draft',
      'sales.update_sales_order_draft',
      'sales.list_sales_order_drafts',
      'sales.get_sales_order_draft_for_restore',
      'sales.cancel_sales_order_draft',
    ]) {
      final body = _squash(_functionSql(sql, function));
      expect(
        body,
        contains(
          'language plpgsql security definer '
          'set search_path = sales, iam, public, pg_temp as \$\$',
        ),
        reason: '$function must pin security-definer search_path.',
      );
      expect(body, contains('sales._assert_sales_actor('));
    }

    expect(
      _squash(_functionSql(sql, 'sales.save_sales_order_draft')),
      contains("sales._assert_sales_actor(p_tenant_id, p_actor_id, p_store_id, 'sales.draft.create')"),
    );
    expect(
      _squash(_functionSql(sql, 'sales.update_sales_order_draft')),
      contains("sales._assert_sales_actor(p_tenant_id, p_actor_id, p_store_id, 'sales.draft.update')"),
    );
    expect(
      _squash(_functionSql(sql, 'sales.list_sales_order_drafts')),
      contains("sales._assert_sales_actor(p_tenant_id, p_actor_id, p_store_id, 'sales.draft.restore')"),
    );
    expect(
      _squash(_functionSql(sql, 'sales.get_sales_order_draft_for_restore')),
      contains("sales._assert_sales_actor(p_tenant_id, p_actor_id, p_store_id, 'sales.draft.restore')"),
    );
    expect(
      _squash(_functionSql(sql, 'sales.cancel_sales_order_draft')),
      contains("sales._assert_sales_actor(p_tenant_id, p_actor_id, p_store_id, 'sales.draft.delete')"),
    );
  });

  test('filters mutations and reads by store scope on rebuild columns', () {
    for (final function in <String>[
      'sales.update_sales_order_draft',
      'sales.get_sales_order_draft_for_restore',
      'sales.cancel_sales_order_draft',
    ]) {
      final body = _squash(_functionSql(sql, function));
      expect(body, contains('and store_id = p_store_id'));
      expect(body, contains('and id = p_draft_id'));
    }

    final listBody = _squash(_functionSql(sql, 'sales.list_sales_order_drafts'));
    expect(listBody, contains('and store_id = p_store_id'));
    expect(listBody, contains("and status = 'active'"));
  });

  test('uses distinct idempotency scopes with shared begin/complete helpers', () {
    final saveBody = _squash(_functionSql(sql, 'sales.save_sales_order_draft'));
    final updateBody = _squash(_functionSql(sql, 'sales.update_sales_order_draft'));
    final cancelBody = _squash(_functionSql(sql, 'sales.cancel_sales_order_draft'));

    for (final body in <String>[saveBody, updateBody, cancelBody]) {
      expect(body, contains('sales._begin_sales_idempotency('));
      expect(body, contains('sales._complete_sales_idempotency('));
      expect(body, contains("'replay'"));
    }

    expect(saveBody, contains("'save_sales_order_draft'"));
    expect(updateBody, contains("'update_sales_order_draft'"));
    expect(cancelBody, contains("'cancel_sales_order_draft'"));
    expect(saveBody, isNot(contains("'update_sales_order_draft'")));
    expect(saveBody, isNot(contains("'cancel_sales_order_draft'")));
    expect(updateBody, isNot(contains("'save_sales_order_draft'")));
    expect(updateBody, isNot(contains("'cancel_sales_order_draft'")));
    expect(cancelBody, isNot(contains("'save_sales_order_draft'")));
    expect(cancelBody, isNot(contains("'update_sales_order_draft'")));
  });

  test('enforces expected version before update/cancel mutation', () {
    final updateBody = _squash(_functionSql(sql, 'sales.update_sales_order_draft'));
    expect(updateBody, contains("status <> 'active'"));
    expect(updateBody, contains('version <> p_expected_version'));
    expect(updateBody, contains("'STALE_DATA'"));

    final cancelBody = _squash(_functionSql(sql, 'sales.cancel_sales_order_draft'));
    expect(cancelBody, contains("status = 'cancelled'"));
    expect(cancelBody, contains("status <> 'active'"));
    expect(cancelBody, contains('version <> p_expected_version'));

    final restoreBody = _squash(
      _functionSql(sql, 'sales.get_sales_order_draft_for_restore'),
    );
    expect(restoreBody, contains("status <> 'active'"));
    expect(restoreBody, contains('p_expected_version'));
  });

  test('persists child lines and rebuilds legacy payload without cross-module tables', () {
    expect(sql, contains('create or replace function sales._write_draft_lines('));
    expect(sql, contains('create or replace function sales._draft_payload('));
    expect(sql, contains('create or replace function sales._draft_preview_snapshot('));
    expect(sql, contains('insert into sales.sales_order_draft_lines'));

    final saveBody = _squash(_functionSql(sql, 'sales.save_sales_order_draft'));
    expect(saveBody, contains('sales._write_draft_lines('));
    expect(saveBody, contains('sales._draft_payload('));
    expect(saveBody, contains('sales._draft_preview_snapshot('));

    final payloadBody = _squash(_functionSql(sql, 'sales._draft_payload'));
    expect(payloadBody, contains("'customer'"));
    expect(payloadBody, contains("'order_note'"));
    expect(payloadBody, contains("'pricing_preview_token'"));
    expect(payloadBody, contains("'needs_revalidation'"));
    expect(payloadBody, contains('total_amount_minor'));

    final writeLinesBody = _squash(_functionSql(sql, 'sales._write_draft_lines'));
    expect(writeLinesBody, contains("'applied_unit_price_minor'"));
    expect(writeLinesBody, contains("'product_name'"));
    expect(writeLinesBody, contains("'product_sku'"));

    expect(sql, isNot(contains('from catalog.')));
    expect(sql, isNot(contains('join catalog.')));
    expect(sql, isNot(contains('from partner.')));
    expect(sql, isNot(contains('join partner.')));
    expect(sql, isNot(contains('from pricing.')));
    expect(sql, isNot(contains('join pricing.')));
  });

  test('grants execute only on the five public draft RPCs', () {
    for (final function in <String>[
      'sales.save_sales_order_draft',
      'sales.update_sales_order_draft',
      'sales.list_sales_order_drafts',
      'sales.get_sales_order_draft_for_restore',
      'sales.cancel_sales_order_draft',
    ]) {
      expect(normalizedSql, contains('revoke all on function $function'));
      expect(normalizedSql, contains('grant execute on function $function'));
    }
    expect(normalizedSql, contains('to authenticated;'));
    expect(
      normalizedSql,
      contains('revoke all on function sales._draft_payload'),
    );
    expect(
      normalizedSql,
      contains('revoke all on function sales._write_draft_lines'),
    );
  });
}

File _draftSqlFile() {
  const relativePath =
      'supabase/migrations/_drafts/007_sales_draft_rpcs.sql';
  final candidates = [
    File(relativePath),
    File('../../../$relativePath'),
    File('../../../../$relativePath'),
  ];
  for (final candidate in candidates) {
    if (candidate.existsSync()) {
      return candidate;
    }
  }
  return candidates.first;
}

String _functionSql(String sql, String function) {
  final start = sql.indexOf('create or replace function $function(');
  if (start < 0) throw StateError('Missing function $function.');
  final end = sql.indexOf('\n\$\$;', start);
  if (end < 0) throw StateError('Missing terminator for $function.');
  return sql.substring(start, end + '\n\$\$;'.length);
}

String _squash(String value) => value.replaceAll(RegExp(r'\s+'), ' ').trim();
