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

String _extractFunction(String sql, String signaturePrefix) {
  final start = sql.indexOf(signaturePrefix);
  expect(start, greaterThanOrEqualTo(0), reason: 'missing $signaturePrefix');
  final revoke = sql.indexOf('revoke all on function', start);
  final nextCreate = sql.indexOf(
    '\ncreate or replace function',
    start + signaturePrefix.length,
  );
  final endCandidates = [
    if (revoke > start) revoke,
    if (nextCreate > start) nextCreate,
    sql.length,
  ]..sort();
  return sql.substring(start, endCandidates.first);
}

void main() {
  late String sql;
  late String requestFn;
  late String listFn;
  late String loadContextFn;
  late String recordResultFn;

  setUpAll(() {
    final draft = File(
      '${_repoRoot().path}/supabase/migrations/_drafts/'
      '011_einvoice_document_operations_rpcs.sql',
    );
    expect(
      draft.existsSync(),
      isTrue,
      reason: 'S4b draft SQL must exist under supabase/migrations/_drafts/',
    );
    sql = draft.readAsStringSync();
    requestFn = _extractFunction(
      sql,
      'create or replace function einvoice.request_invoice_document(',
    );
    listFn = _extractFunction(
      sql,
      'create or replace function einvoice.get_invoice_documents(',
    );
    loadContextFn = _extractFunction(
      sql,
      'create or replace function einvoice.load_invoice_document_operation_context(',
    );
    recordResultFn = _extractFunction(
      sql,
      'create or replace function einvoice.record_invoice_document_result(',
    );
  });

  group('S4b draft header and schema', () {
    test('declares frozen Touches set and canonical tables', () {
      expect(sql, contains('-- Intent: einvoice_s4b_documents'));
      expect(
        sql,
        contains(
          '-- Touches: _invoice_document_command_id, get_invoice_documents, load_invoice_document_operation_context, record_invoice_document_result, request_invoice_document',
        ),
      );
      expect(
        sql,
        contains('create table if not exists einvoice.invoice_documents'),
      );
      expect(sql, contains('request_id uuid not null'));
      expect(
        sql,
        contains(
          'primary key (tenant_id, electronic_invoice_id, document_type)',
        ),
      );
      expect(sql, isNot(contains('invoice_document_operations')));
      expect(sql, isNot(contains('intent_hash')));
      expect(sql, isNot(contains('idempotency_key')));
      expect(sql, isNot(contains('download_url')));
    });

    test('lists required RPC symbols', () {
      expect(sql, contains('request_invoice_document'));
      expect(sql, contains('get_invoice_documents'));
      expect(sql, contains('_invoice_document_command_id'));
      expect(sql, contains('load_invoice_document_operation_context'));
      expect(sql, contains('record_invoice_document_result'));
    });
  });

  group('S4b capability and access semantics', () {
    test(
      'request_invoice_document checks sales scope and capability before insert',
      () {
        expect(requestFn, contains('sales.can_access_sales_order'));
        expect(sql, contains('supported_document_types'));
        expect(requestFn, contains('_document_type_supported'));
        expect(requestFn, contains('DOCUMENT_UNAVAILABLE'));
        expect(requestFn, isNot(contains('IDEMPOTENCY_CONFLICT')));
        expect(requestFn, isNot(contains('intent_hash')));
      },
    );

    test('request_invoice_document hashes the request id without pgcrypto search_path', () {
      expect(
        requestFn,
        contains('set search_path = einvoice, iam, sales, public'),
      );
      expect(requestFn, isNot(contains('extensions.digest(')));
    });

    test('request reuses pending or available and otherwise upserts one command', () {
      expect(requestFn, contains("'PENDING'"));
      expect(requestFn, contains("'AVAILABLE'"));
      expect(requestFn, contains("'einvoice.download_invoice_document'"));
      expect(requestFn, contains('on conflict (id) do nothing'));
      expect(
        requestFn,
        contains('on conflict (tenant_id, electronic_invoice_id, document_type)'),
      );
    });

    test('list read uses public access guard', () {
      expect(listFn, contains('p_actor_id <> auth.uid()'));
      expect(
        listFn,
        contains("iam.has_permission(p_tenant_id, 'einvoice.view')"),
      );
      expect(listFn, contains('sales.can_access_sales_order'));
    });

    test('worker RPCs require service role', () {
      expect(
        loadContextFn,
        contains("current_setting('request.jwt.claim.role', true)"),
      );
      expect(
        recordResultFn,
        contains("current_setting('request.jwt.claim.role', true)"),
      );
    });

    test('load_invoice_document_operation_context returns text casts', () {
      expect(loadContextFn, isNot(contains('d.version::integer')));
      expect(loadContextFn, contains('ei.provider_invoice_reference::text'));
      expect(loadContextFn, contains('ei.invoice_series::text'));
    });

    test('request_invoice_document enqueues request id and document type', () {
      expect(requestFn, contains("'document_type', v_doc_type"));
      expect(requestFn, contains("'request_id', v_request_id"));
      expect(requestFn, contains("'correlation_id', v_request_id"));
      expect(requestFn, isNot(contains('operation_generation')));
      expect(requestFn, isNot(contains('attempt_ordinal')));
    });
  });

  group('S4b private storage bucket policy', () {
    test('keeps bucket private with tenant-scoped select only', () {
      expect(sql, contains("'einvoice-documents'"));
      expect(sql, contains('20971520'));
      expect(sql, contains('einvoice_documents_select'));
      expect(sql, contains("'einvoice.download_document'"));
      expect(sql, contains('for select to authenticated'));
      expect(sql, isNot(contains('for insert to authenticated')));
      expect(sql, isNot(contains('for update to authenticated')));
      expect(sql, isNot(contains('for delete to authenticated')));
    });
  });
}
