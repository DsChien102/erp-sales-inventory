import 'dart:io';

import 'package:test/test.dart';

/// SQL contract tests — Sales refactor bảng 3 `sales.sales_order_drafts`
/// (docs/superpowers/specs/sales-schema-refactor/03-sales-order-drafts.md).
void main() {
  final schemaSql = _readMigration('20260830005_sales_rebuild_schema.sql');
  final draftSql = _readMigration('20260830007_sales_draft_rpcs.sql');

  test('drafts table uses explicit columns instead of preview_snapshot', () {
    final start = schemaSql.indexOf(
      'create table if not exists sales.sales_order_drafts (',
    );
    final table = schemaSql.substring(start, schemaSql.indexOf('\n);', start));
    for (final column in [
      'updated_by_user_id uuid not null,',
      'customer_snapshot jsonb,',
      'pricing_preview_token text,',
      'needs_revalidation boolean not null default false,',
    ]) {
      expect(table, contains(column), reason: column);
    }
    expect(
      table,
      contains("check (status in ('active', 'converted', 'cancelled', 'expired'))"),
    );
    for (final removed in [
      'sales_shift_id',
      'preview_snapshot',
      'expires_at',
      'expired_at',
      'converted_at',
      'cancelled_at',
    ]) {
      expect(table, isNot(contains(removed)), reason: removed);
    }
  });

  test('draft RPC file no longer references preview_snapshot', () {
    expect(draftSql, isNot(contains('preview_snapshot')));
    expect(draftSql, isNot(contains('_draft_preview_snapshot')));
    expect(draftSql, isNot(contains('cancelled_at')));
    expect(
      draftSql,
      contains(
        'revoke all on function sales._draft_customer_snapshot(jsonb) from public, anon, authenticated;',
      ),
    );
  });

  test('payload maps legacy keys from explicit columns', () {
    final payload = _lastFunctionBlock(draftSql, 'sales._draft_payload');
    expect(payload, contains("'saved_at', v_draft.updated_at,"));
    expect(
      payload,
      contains("'saved_by_actor_id', v_draft.updated_by_user_id::text,"),
    );
    expect(payload, contains("'customer', v_draft.customer_snapshot,"));
    expect(
      payload,
      contains("'pricing_preview_token', v_draft.pricing_preview_token,"),
    );
    expect(
      payload,
      contains("'needs_revalidation', v_draft.needs_revalidation,"),
    );

    final restore = _lastFunctionBlock(
      draftSql,
      'sales.get_sales_order_draft_for_restore',
    );
    expect(restore, contains("'saved_at', v_draft.updated_at,"));
    expect(
      restore,
      contains("'saved_by_actor_id', v_draft.updated_by_user_id::text"),
    );
  });

  test('mutations write updated_by_user_id and customer_snapshot', () {
    final save = _lastFunctionBlock(draftSql, 'sales.save_sales_order_draft');
    expect(save, contains('sales._draft_customer_snapshot(p_customer)'));
    expect(save, contains('created_by_user_id, updated_by_user_id,'));
    expect(save, isNot(contains('v_saved_at')));

    final update = _lastFunctionBlock(draftSql, 'sales.update_sales_order_draft');
    expect(
      update,
      contains('customer_snapshot = sales._draft_customer_snapshot(p_customer),'),
    );
    expect(update, contains('updated_by_user_id = p_actor_id,'));

    final cancel = _lastFunctionBlock(draftSql, 'sales.cancel_sales_order_draft');
    expect(cancel, contains('updated_by_user_id = p_actor_id,'));
  });

  test('finalize converts draft without converted_at', () {
    final checkoutSql = _readMigration('20260830008_sales_checkout_rpcs.sql');
    final finalize = _lastFunctionBlock(checkoutSql, 'sales.finalize_sales_order');
    expect(finalize, isNot(contains('converted_at')));
    expect(
      finalize,
      contains(
        "      set status = 'converted',\n"
        '          version = version + 1,\n'
        '          updated_by_user_id = p_actor_id,\n'
        '          updated_at = now()\n',
      ),
    );
  });
}

String _readMigration(String fileName) {
  final root = _findRepoRoot();
  return File('${root.path}/supabase/migrations/$fileName').readAsStringSync();
}

/// Last `create or replace function <qualifiedName>(` … `$$;` in [sql].
String _lastFunctionBlock(String sql, String qualifiedName) {
  final start = sql.lastIndexOf('create or replace function $qualifiedName(');
  if (start < 0) {
    throw StateError('$qualifiedName not found');
  }
  final end = sql.indexOf(r'$$;', start);
  return sql.substring(start, end + 3);
}

Directory _findRepoRoot() {
  var current = Directory.current.absolute;
  while (!Directory('${current.path}/supabase/migrations').existsSync()) {
    final parent = current.parent;
    if (parent.path == current.path) {
      throw StateError('Could not locate Vet45 workspace root');
    }
    current = parent;
  }
  return current;
}
