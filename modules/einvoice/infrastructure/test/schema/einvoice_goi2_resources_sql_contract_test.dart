import 'dart:io';

import 'package:test/test.dart';

/// SQL contract tests — Einvoice refactor gói 2 (tài nguyên sau phát hành).
void main() {
  final viewSql = _readDraft('010_einvoice_official_view_rpcs.sql');

  group('Task 2 — official_invoice_views', () {
    test('one current row per invoice, keyed by tenant and invoice', () {
      final table = _createTable(viewSql, 'einvoice.official_invoice_views');
      expect(table, contains('primary key (tenant_id, electronic_invoice_id)'));
      expect(table, contains('request_id uuid not null'));
      expect(table, contains('failure_source text'));
      for (final gone in const [
        'generation',
        'attempt_ordinal',
        'version bigint',
        'provider_interaction_reference',
        'updated_at',
      ]) {
        expect(table, isNot(contains(gone)), reason: gone);
      }
    });

    test('old operations table is gone from every draft', () {
      for (final draft in _allDrafts()) {
        expect(
          draft.readAsStringSync(),
          isNot(contains('official_invoice_view_operations')),
          reason: draft.path,
        );
      }
    });

    test('a pending request returns its request id, never an unset command id', () {
      final body = _lastFunctionBlock(
        viewSql,
        'einvoice.request_official_invoice_view',
      );
      expect(body, isNot(contains('select\n        v_cmd_id,')));
      expect(body, contains('v_operation.request_id'));
      expect(
        body,
        contains(
          'on conflict (tenant_id, electronic_invoice_id) do update set',
        ),
      );
    });

    test('result recording is guarded by request id and pending status', () {
      final body = _lastFunctionBlock(
        viewSql,
        'einvoice.record_official_invoice_view_result',
      );
      expect(body, contains('p_request_id uuid'));
      expect(body, contains('p_failure_source text'));
      expect(body, isNot(contains('p_expected_version')));
      expect(body, isNot(contains('p_provider_interaction_reference')));
      expect(body, contains('and o.request_id = p_request_id'));
      expect(body, contains("and o.status = 'PENDING'"));
    });

    test('old signatures are dropped before being replaced', () {
      expect(
        viewSql,
        contains(
          'drop function if exists einvoice._official_view_command_id(uuid, integer);',
        ),
      );
      expect(
        viewSql,
        contains(
          'drop function if exists einvoice.load_official_view_operation_context(uuid, uuid);',
        ),
      );
      expect(
        viewSql,
        contains(
          'drop function if exists einvoice.record_official_invoice_view_result(\n'
          '  uuid, uuid, text, bigint, uuid, text, text, timestamptz, text, text\n'
          ');',
        ),
      );
      expect(
        viewSql,
        contains(
          'drop function if exists einvoice.get_electronic_invoice_detail(uuid, uuid, uuid);',
        ),
      );
    });

    test('detail projection exposes the failure code', () {
      final body = _lastFunctionBlock(
        viewSql,
        'einvoice.get_electronic_invoice_detail',
      );
      expect(body, contains('official_view_failure_code text'));
    });
  });

  group('Task 3 — invoice_documents', () {
    final documentSql = _readDraft('011_einvoice_document_operations_rpcs.sql');

    test('one row per invoice and document type', () {
      final table = _createTable(documentSql, 'einvoice.invoice_documents');
      expect(
        table,
        contains(
          'primary key (tenant_id, electronic_invoice_id, document_type)',
        ),
      );
      expect(table, contains('request_id uuid not null'));
      expect(table, contains('failure_source text'));
      for (final gone in const [
        'document_version',
        'generation',
        'attempt_ordinal',
        'idempotency_key',
        'intent_hash',
        'access_expires_at',
        'provider_document_reference',
        'content_type',
        'file_name',
        'file_size',
        'provider_interaction_reference',
        'version bigint',
        'updated_at',
      ]) {
        expect(table, isNot(contains(gone)), reason: gone);
      }
    });

    test('operations table and its circular foreign key are gone', () {
      for (final draft in _allDrafts()) {
        expect(
          draft.readAsStringSync(),
          isNot(contains('invoice_document_operations')),
          reason: draft.path,
        );
      }
    });

    test('request no longer takes an idempotency key or returns access expiry', () {
      final body = _lastFunctionBlock(
        documentSql,
        'einvoice.request_invoice_document',
      );
      expect(body, isNot(contains('p_idempotency_key')));
      expect(body, isNot(contains('access_expires_at')));
      expect(body, contains('request_id uuid'));
    });

    test('result recording writes one row, guarded by request id', () {
      final body = _lastFunctionBlock(
        documentSql,
        'einvoice.record_invoice_document_result',
      );
      expect(body, contains('and d.request_id = p_request_id'));
      expect(body, contains("and d.status = 'PENDING'"));
      expect('update einvoice.'.allMatches(body).length, 1);
    });

    test('read projection swaps access expiry for failure codes', () {
      final body = _lastFunctionBlock(
        documentSql,
        'einvoice.get_invoice_documents',
      );
      expect(body, contains('pdf_failure_code text'));
      expect(body, contains('xml_failure_code text'));
      expect(body, isNot(contains('access_expires_at')));
    });

    test('old document signatures are dropped', () {
      for (final signature in const [
        'einvoice._invoice_document_command_id(uuid, integer)',
        'einvoice.request_invoice_document(uuid, uuid, uuid, text, varchar)',
        'einvoice.get_invoice_documents(uuid, uuid, uuid)',
        'einvoice.load_invoice_document_operation_context(uuid, uuid)',
      ]) {
        expect(
          documentSql,
          contains('drop function if exists $signature;'),
          reason: signature,
        );
      }
      expect(
        documentSql,
        contains(
          'drop function if exists einvoice.record_invoice_document_result(\n'
          '  uuid, uuid, text, bigint, uuid, bigint, text, text, text, text, bigint, text, text\n'
          ');',
        ),
      );
    });
  });

  group('Task 4 — invoice_provider_observations', () {
    final observationSql = _readDraft(
      '012_einvoice_provider_observations_rpcs.sql',
    );

    test('observation carries its own uuid correlation id', () {
      final table = _createTable(
        observationSql,
        'einvoice.invoice_provider_observations',
      );
      expect(table, contains('correlation_id uuid not null'));
      expect(table, contains('unique (tenant_id, deduplication_key)'));
      expect(table, isNot(contains('provider_interaction_reference')));
    });

    test('recording an observation no longer writes to the invoice or the log', () {
      final body = _lastFunctionBlock(
        observationSql,
        'einvoice.record_provider_observation',
      );
      expect(body, contains('p_correlation_id uuid'));
      expect(body, isNot(contains('update einvoice.electronic_invoices')));
      expect(body, isNot(contains('provider_interaction')));
      expect(body, contains("'correlation_id', p_correlation_id"));
    });

    test('old observation signature is dropped before the rename', () {
      expect(
        observationSql,
        contains(
          'drop function if exists einvoice.record_provider_observation(\n'
          '  uuid, uuid, text, text, text, timestamptz, text, jsonb, uuid\n'
          ');',
        ),
      );
    });

    test('latest observation reads correlation straight from the row', () {
      final body = _lastFunctionBlock(
        observationSql,
        'einvoice.get_latest_provider_observation',
      );
      expect(body, contains('ipo.correlation_id'));
      expect(body, isNot(contains('provider_interaction_records')));
    });
  });
}

Iterable<File> _allDrafts() => Directory(
  '${_findRepoRoot().path}/supabase/migrations/_drafts',
).listSync().whereType<File>().where((f) => f.path.endsWith('.sql'));

String _readDraft(String fileName) => File(
  '${_findRepoRoot().path}/supabase/migrations/_drafts/$fileName',
).readAsStringSync();

/// Thân `create table <qualifiedName> (` … `\n);` trong [sql].
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
