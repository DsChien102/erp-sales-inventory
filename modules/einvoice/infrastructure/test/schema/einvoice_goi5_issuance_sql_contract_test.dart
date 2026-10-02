import 'dart:io';

import 'package:test/test.dart';

/// SQL contract tests — Einvoice refactor gói 5 (phát hành).
void main() {
  final issuanceSql = _readDraft(
    '007_einvoice_issuance_schema_and_publish_rpcs.sql',
  );
  final autoSql = _readDraft(
    '008_einvoice_auto_issuance_and_retry_rpcs.sql',
  );
  final reconSql = _readDraft(
    '009_einvoice_issuance_reconciliation_rpcs.sql',
  );
  final leaseSql = _readDraft('019_einvoice_misa_publish_series_lease.sql');

  group('Task 1 — publish_series_leases', () {
    test('lease is keyed by tenant and series only', () {
      final table = _createTable(leaseSql, 'einvoice.publish_series_leases');
      expect(table, contains('primary key (tenant_id, invoice_series)'));
      expect(table, contains('lease_version bigint not null default 1'));
      expect(table, contains('created_at timestamptz not null default now()'));
      expect(table, isNot(contains('provider_connection_id')));
      expect(table, isNot(contains('updated_at')));
    });

    test('old lease table name is gone', () {
      for (final draft in _allDrafts()) {
        expect(
          draft.readAsStringSync(),
          isNot(contains('provider_series_dispatch_leases')),
          reason: draft.path,
        );
      }
    });

    test('lease functions no longer filter by connection', () {
      for (final name in const [
        'einvoice.acquire_publish_series_lease',
        'einvoice.renew_publish_series_lease',
        'einvoice.release_publish_series_lease',
      ]) {
        final body = _lastFunctionBlock(leaseSql, name);
        expect(
          body,
          isNot(contains('psdl.provider_connection_id =')),
          reason: name,
        );
        expect(
          body,
          isNot(contains('and provider_connection_id =')),
          reason: name,
        );
      }
      final acquire = _lastFunctionBlock(
        leaseSql,
        'einvoice.acquire_publish_series_lease',
      );
      expect(
        acquire,
        contains('on conflict (tenant_id, invoice_series) do nothing'),
      );
      expect(acquire, contains('v_attempt.provider_connection_id'));
    });
  });

  group('Task 2 — auto_issuance_processes', () {
    test('one process row per order, with the buyer for re-evaluation', () {
      final table = _createTable(autoSql, 'einvoice.auto_issuance_processes');
      expect(table, contains('unique (tenant_id, sales_order_id)'));
      expect(table, contains('unique (tenant_id, trigger_key)'));
      expect(table, contains('buyer_partner_id uuid'));
      expect(table, contains('sales_order_version text,'));
      expect(table, contains('last_evaluated_at timestamptz'));
      for (final gone in const [
        'process_type',
        'process_status',
        'retry_count',
        'next_retry_at',
        'claimed_at',
        'claim_token',
        'version bigint',
        'updated_at',
      ]) {
        expect(table, isNot(contains(gone)), reason: gone);
      }
    });

    test('old table name, columns and placeholder version are gone', () {
      expect(autoSql, isNot(contains('automatic_trigger_process_records')));
      expect(autoSql, isNot(contains('process_status')));
      expect(autoSql, isNot(contains("'SALES_ORDER_COMPLETED'")));
      expect(autoSql, isNot(contains("'unknown'")));
    });

    test('a second event for the same order reuses the row', () {
      final body = _lastFunctionBlock(autoSql, 'einvoice.start_auto_issuance');
      expect(body, contains('and pr.sales_order_id = p_sales_order_id'));
      expect(body, contains('einvoice.reevaluate_auto_issuance('));
    });

    test('pending processes are filtered by the updated buyer', () {
      final body = _lastFunctionBlock(
        autoSql,
        'einvoice.list_open_auto_issuance_processes',
      );
      expect(body, contains('pr.buyer_partner_id = p_partner_id'));
    });
  });

  group('Task 3 — neo và lần phát hành', () {
    test('issuance root is a 5-column anchor', () {
      final table = _createTable(issuanceSql, 'einvoice.invoice_issuances');
      expect(table, contains('unique (tenant_id, id)'));
      for (final gone in const [
        'settled_result',
        'successful_attempt_id',
        'electronic_invoice_id',
        'last_attempt_id',
        'initiated_at',
        'created_by_actor',
        'version bigint',
        'updated_at',
      ]) {
        expect(table, isNot(contains(gone)), reason: gone);
      }
    });

    test('nothing updates the anchor, but creating an attempt still locks it', () {
      for (final draft in _allDrafts()) {
        expect(
          draft.readAsStringSync(),
          isNot(contains('update einvoice.invoice_issuances')),
          reason: draft.path,
        );
      }
      final start = _lastFunctionBlock(
        autoSql,
        'einvoice._start_issuance_attempt',
      );
      expect(
        start,
        contains('do update set issuance_type = excluded.issuance_type'),
      );
      expect(start, isNot(contains('p_trigger_type')));
    });

    test('attempt keeps 27 columns with an explicit failure source', () {
      final table = _createTable(issuanceSql, 'einvoice.issuance_attempts');
      for (final kept in const [
        'failure_source text',
        'retry_count int not null default 0',
        'unique (tenant_id, id)',
        'references einvoice.invoice_issuances (tenant_id, id)',
        'references einvoice.provider_connections (tenant_id, id)',
      ]) {
        expect(table, contains(kept), reason: kept);
      }
      for (final gone in const [
        'trigger_type',
        'invoice_with_code',
        'is_invoice_summary',
        'sign_type',
        'canonical_model_version',
        'provider_interaction_reference',
        'provider_result_code',
        'provider_result_message',
        'provider_publish_retry_count',
        'next_provider_publish_retry_at',
        'last_provider_publish_code',
        'started_at',
        'updated_at',
      ]) {
        expect(table, isNot(contains(gone)), reason: gone);
      }
    });

    test('dropped attempt columns are not written anywhere', () {
      for (final draft in _allDrafts()) {
        final sql = draft.readAsStringSync();
        // provider_interaction_reference không nằm ở đây: cột
        // latest_provider_interaction_reference của hồ sơ đối soát chứa
        // chuỗi này tới Task 5 (test Task 5 kiểm tra nó).
        for (final gone in const [
          'provider_result_code',
          'provider_result_message',
          'next_provider_publish_retry_at',
          'last_provider_publish_code',
          'canonical_model_version',
          'settled_result',
        ]) {
          expect(sql, isNot(contains(gone)), reason: '${draft.path}: $gone');
        }
      }
    });

    test('every failed attempt records where the failure came from', () {
      final issuance007 = issuanceSql;
      for (final (name, source) in const [
        ('einvoice.record_issuance_failure', "'PROVIDER'"),
        ('einvoice.record_issuance_command_integrity_failure', "'INTERNAL'"),
        ('einvoice.record_publish_command_dead_letter', "'INTERNAL'"),
      ]) {
        expect(
          _lastFunctionBlock(issuance007, name),
          contains('failure_source = $source'),
          reason: name,
        );
      }
      expect(
        _lastFunctionBlock(reconSql, 'einvoice.resolve_reconciliation_case'),
        contains("failure_source = 'PROVIDER'"),
      );
    });

    test('dead duplicate bodies are gone', () {
      int count(String sql, String fn) =>
          'create or replace function einvoice.$fn('.allMatches(sql).length;
      expect(count(issuanceSql, 'issue_invoice'), 0);
      expect(count(issuanceSql, 'record_issuance_undetermined'), 0);
      expect(count(issuanceSql, 'get_order_invoice_projection'), 0);
      expect(count(reconSql, 'claim_issuance_reconciliation_case'), 0);
      expect(count(reconSql, 'get_issuance_attempt_status'), 0);
    });

    test('attempt status query keys off the failure source', () {
      final statusSql = _readDraft(
        '022_einvoice_attempt_status_provider_failure_message.sql',
      );
      expect(statusSql, contains("v_attempt.failure_source = 'PROVIDER'"));
    });
  });

  group('Task 4 — electronic_invoices', () {
    test('invoice row keeps only immutable facts', () {
      final table = _createTable(issuanceSql, 'einvoice.electronic_invoices');
      for (final kept in const [
        'invoice_series varchar(100) not null',
        'unique (tenant_id, id)',
        'references einvoice.issuance_attempts (tenant_id, id)',
      ]) {
        expect(table, contains(kept), reason: kept);
      }
      for (final gone in const [
        'invoice_snapshot',
        'snapshot_schema_version',
        'template_code',
        'lookup_code',
        'tax_authority',
        'latest_provider_state_code',
        'last_provider_observed_at',
        'version bigint',
        'updated_at',
        ' series varchar',
      ]) {
        expect(table, isNot(contains(gone)), reason: gone);
      }
    });

    test('no draft updates an issued invoice or keeps the duplicate index', () {
      for (final draft in _allDrafts()) {
        final sql = draft.readAsStringSync();
        expect(
          sql,
          isNot(contains('update einvoice.electronic_invoices')),
          reason: draft.path,
        );
        expect(
          sql,
          isNot(contains('electronic_invoices_tenant_id_id_idx')),
          reason: draft.path,
        );
        // \b: không khớp `buyer_invoice_snapshot` của Sales (017, 018).
        expect(
          RegExp(r'\binvoice_snapshot\b').hasMatch(sql),
          isFalse,
          reason: draft.path,
        );
      }
    });

    test('delivery reads the original buyer snapshot from the attempt', () {
      final deliverySql = _readDraft(
        '013_einvoice_delivery_schema_and_start_rpcs.sql',
      );
      expect(deliverySql, contains('ia.attempt_snapshot'));
      expect(
        deliverySql,
        contains('{buyer_lineage,buyerInvoiceSnapshot,buyerEmail}'),
      );
      expect(
        deliverySql,
        contains('{buyer_lineage,buyerInvoiceSnapshot,buyerLegalName}'),
      );
    });
  });

  group('Task 5 — invoice_reconciliation_cases', () {
    test('case table keeps 20 columns without the purpose', () {
      final table = _createTable(
        issuanceSql,
        'einvoice.invoice_reconciliation_cases',
      );
      for (final kept in const [
        'check_count int not null default 0',
        'claimed_at timestamptz',
        'claim_token text',
        'terminal_evidence jsonb',
        'resolution_snapshot jsonb',
        'references einvoice.provider_connections (tenant_id, id)',
      ]) {
        expect(table, contains(kept), reason: kept);
      }
      for (final gone in const [
        'reconciliation_purpose',
        'provider_reference',
        'idempotency_key',
        'latest_provider_interaction_reference',
        'opened_by_actor',
        'last_error_message',
        'attempt_count',
        'updated_at',
        "'ELECTRONIC_INVOICE'",
      ]) {
        expect(table, isNot(contains(gone)), reason: gone);
      }
    });

    test('columns live in the create table, not in later alters', () {
      expect(
        reconSql,
        isNot(contains('alter table einvoice.invoice_reconciliation_cases')),
      );
      expect(
        issuanceSql,
        contains(
          'on einvoice.invoice_reconciliation_cases (tenant_id, target_type, target_id)',
        ),
      );
    });

    test('no draft mentions the purpose or the old counter any more', () {
      for (final draft in _allDrafts()) {
        final sql = draft.readAsStringSync();
        expect(sql, isNot(contains('reconciliation_purpose')), reason: draft.path);
        expect(
          sql,
          isNot(contains('latest_provider_interaction_reference')),
          reason: draft.path,
        );
        expect(sql, isNot(contains('opened_by_actor')), reason: draft.path);
      }
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
