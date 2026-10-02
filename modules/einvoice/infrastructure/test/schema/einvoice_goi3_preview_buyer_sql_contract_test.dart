import 'dart:io';

import 'package:test/test.dart';

/// SQL contract tests — Einvoice refactor gói 3 (xem trước + dữ liệu người mua).
void main() {
  final schemaSql = _readDraft(
    '005_einvoice_buyer_completion_and_preview_schema.sql',
  );
  final rpcSql = _readDraft(
    '006_einvoice_buyer_completion_and_preview_rpcs.sql',
  );
  final issuanceSql = _readDraft(
    '008_einvoice_auto_issuance_and_retry_rpcs.sql',
  );

  group('Task 1 — buyer_invoice_completions', () {
    test('completion is typed buyer data for one order, no lifecycle', () {
      final table = _createTable(
        schemaSql,
        'einvoice.buyer_invoice_completions',
      );
      expect(table, contains('primary key (tenant_id, sales_order_id)'));
      for (final column in const [
        'sales_order_version text',
        'buyer_name text',
        'buyer_tax_code text',
        'buyer_email text',
        'buyer_address text',
        'completed_by_user_id uuid not null',
        'completed_at timestamptz not null',
      ]) {
        expect(table, contains(column), reason: column);
      }
      for (final gone in const [
        '  id uuid',
        'status',
        'locked_at',
        'eligible_fields',
        'resolved_values',
        'buyer_partner_id',
        'source_partner_revision',
        'source_partner_updated_at',
        'last_resolved_at',
        'version bigint',
        'updated_at',
      ]) {
        expect(table, isNot(contains(gone)), reason: gone);
      }
      expect(
        schemaSql,
        contains(
          'revoke all on einvoice.buyer_invoice_completions '
          'from anon, authenticated;',
        ),
      );
    });

    test('no draft keeps the dead open-completion branch or row id', () {
      for (final draft in _allDrafts()) {
        final sql = draft.readAsStringSync();
        expect(
          sql,
          isNot(contains("v_buyer_completion.status = 'open'")),
          reason: draft.path,
        );
        expect(sql, isNot(contains('v_buyer_completion')), reason: draft.path);
        expect(
          sql,
          isNot(contains('buyer_invoice_completion_id')),
          reason: draft.path,
        );
        expect(sql, isNot(contains('p_buyer_completion_id')), reason: draft.path);
      }
    });

    test('effective buyer is merged in one helper from the typed columns', () {
      final helper = _lastFunctionBlock(
        rpcSql,
        'einvoice._effective_buyer_snapshot',
      );
      expect(helper, contains('bc.buyer_tax_code'));
      expect(helper, contains("'buyerTaxCode'"));
      expect(helper, contains('bc.sales_order_id = p_sales_order_id'));

      final start = _lastFunctionBlock(
        issuanceSql,
        'einvoice._start_issuance_attempt',
      );
      expect(start, contains('einvoice._effective_buyer_snapshot('));
      expect(start, contains('for share'));
      expect(start, contains("'buyerCompletedAt'"));
      expect(start, isNot(contains('resolved_values')));
    });

    test('readiness reads typed columns and keeps its return shape', () {
      final body = _lastFunctionBlock(
        rpcSql,
        'einvoice.get_issuance_readiness',
      );
      expect(body, contains('bc.buyer_tax_code'));
      expect(body, isNot(contains('bc.resolved_values')));
      expect(body, isNot(contains('bc.status')));
      expect(body, contains('buyer_completion_state text'));
    });

    test('open auto-issuance listing no longer joins completions', () {
      final body = _lastFunctionBlock(
        issuanceSql,
        'einvoice.list_open_auto_issuance_processes',
      );
      expect(body, isNot(contains('buyer_invoice_completions')));
      expect(body, contains("pr.status = 'PENDING_REEVALUATION'"));
    });
  });

  group('Task 2 — quyền và chặn ghi đè', () {
    test('completion write checks the caller like issue_invoice', () {
      final body = _lastFunctionBlock(
        rpcSql,
        'einvoice.complete_buyer_invoice_data',
      );
      expect(body, contains('set search_path = einvoice, iam, sales, public'));
      expect(body, contains('auth.uid() is null'));
      expect(body, contains('p_actor_id <> auth.uid()'));
      expect(body, contains("iam.has_permission(p_tenant_id, 'einvoice.issue')"));
      expect(
        body,
        contains("iam.has_permission(p_tenant_id, 'einvoice.manage_issuance')"),
      );
      expect(body, contains('sales.can_access_sales_order('));
    });

    test('completion write refuses after the write once issuance began', () {
      final body = _lastFunctionBlock(
        rpcSql,
        'einvoice.complete_buyer_invoice_data',
      );
      final write = body.indexOf('insert into einvoice.buyer_invoice_completions');
      final issued = body.indexOf("raise exception 'ALREADY_ISSUED");
      final running = body.indexOf("raise exception 'OPERATION_IN_PROGRESS");
      expect(write, greaterThan(0));
      expect(issued, greaterThan(write));
      expect(running, greaterThan(write));
    });
  });

  group('Task 3 — invoice_previews', () {
    test('one current preview per order with recorded failures', () {
      final table = _createTable(schemaSql, 'einvoice.invoice_previews');
      expect(table, contains('primary key (tenant_id, sales_order_id)'));
      expect(table, contains('request_id uuid not null'));
      expect(table, contains("check (status in ('PENDING', 'READY', 'FAILED'))"));
      expect(table, contains("check (status <> 'READY' or viewer_ref is not null)"));
      expect(table, contains("check (status <> 'FAILED' or failure_code is not null)"));
      expect(table, contains('failure_source text'));
      for (final gone in const [
        '  id uuid',
        'preview_payload',
        'version bigint',
        'provider_connection_id',
        'correlation_id',
        'order_version varchar',
        'updated_at',
        'SUPERSEDED',
      ]) {
        expect(table, isNot(contains(gone)), reason: gone);
      }
    });

    test('old preview operations table is gone', () {
      for (final draft in _allDrafts()) {
        expect(
          draft.readAsStringSync(),
          isNot(contains('invoice_preview_operations')),
          reason: draft.path,
        );
      }
    });

    test('request overwrites the row and previews the effective buyer', () {
      final body = _lastFunctionBlock(
        rpcSql,
        'einvoice.request_invoice_preview',
      );
      expect(body, contains('on conflict (tenant_id, sales_order_id) do update'));
      expect(body, contains('request_id = excluded.request_id'));
      expect(body, contains('einvoice._effective_buyer_snapshot('));
      expect(body, contains("'preview_request_id', v_request_id"));
    });

    test('worker writeback is guarded by request id and pending status', () {
      final body = _lastFunctionBlock(rpcSql, 'einvoice.store_preview_result');
      expect(body, contains('p_request_id uuid'));
      expect(body, contains('p_failure_source text'));
      expect(body, contains('and p.request_id = p_request_id'));
      expect(body, contains("and p.status = 'PENDING'"));
      expect(body, isNot(contains('p_preview_payload')));
      expect(
        rpcSql,
        contains(
          'drop function if exists einvoice.store_preview_result'
          '(uuid, uuid, text, jsonb, text);',
        ),
      );
    });

    test('read returns the failure code and hides expired rows', () {
      final body = _lastFunctionBlock(rpcSql, 'einvoice.get_invoice_preview');
      expect(body, contains('failure_code text'));
      expect(body, contains('p.expires_at > now()'));
      expect(body, isNot(contains('preview_payload')));
      expect(
        rpcSql,
        contains(
          'drop function if exists einvoice.get_invoice_preview(uuid, uuid, uuid);',
        ),
      );
    });
  });
}

Iterable<File> _allDrafts() => Directory(
  '${_findRepoRoot().path}/supabase/migrations/_drafts',
).listSync().whereType<File>().where((f) => f.path.endsWith('.sql'));

String _readDraft(String fileName) => File(
  '${_findRepoRoot().path}/supabase/migrations/_drafts/$fileName',
).readAsStringSync();

/// Thân `create table if not exists <qualifiedName> (` … `\n);` trong [sql].
String _createTable(String sql, String qualifiedName) {
  final start = sql.indexOf('create table if not exists $qualifiedName (');
  if (start < 0) {
    throw StateError('$qualifiedName not found');
  }
  return sql.substring(start, sql.indexOf('\n);', start));
}

/// `create or replace function <qualifiedName>(` … `$$;` cuối cùng trong [sql].
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
