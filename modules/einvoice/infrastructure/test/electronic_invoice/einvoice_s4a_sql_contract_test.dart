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
  late String detailFn;
  late String loadContextFn;
  late String recordResultFn;

  setUpAll(() {
    final draft = File(
      '${_repoRoot().path}/supabase/migrations/_drafts/'
      '010_einvoice_official_view_rpcs.sql',
    );
    expect(
      draft.existsSync(),
      isTrue,
      reason: 'S4a draft SQL must exist under supabase/migrations/_drafts/',
    );
    sql = draft.readAsStringSync();
    requestFn = _extractFunction(
      sql,
      'create or replace function einvoice.request_official_invoice_view(',
    );
    detailFn = _extractFunction(
      sql,
      'create or replace function einvoice.get_electronic_invoice_detail(',
    );
    loadContextFn = _extractFunction(
      sql,
      'create or replace function einvoice.load_official_view_operation_context(',
    );
    recordResultFn = _extractFunction(
      sql,
      'create or replace function einvoice.record_official_invoice_view_result(',
    );
  });

  group('S4a draft header and RPC surface', () {
    test('declares frozen Touches set and operation table', () {
      expect(sql, contains('-- Intent: einvoice_s4a_official_view'));
      expect(
        sql,
        contains(
          '-- Touches: _official_view_command_id, get_electronic_invoice_detail, load_official_view_operation_context, record_official_invoice_view_result, request_official_invoice_view',
        ),
      );
      expect(
        sql,
        contains('create table if not exists einvoice.official_invoice_views'),
      );
      expect(sql, contains('request_id uuid not null'));
      expect(sql, contains('failure_source text'));
      expect(
        sql,
        contains(
          "status in ('PENDING', 'AVAILABLE', 'FAILED', 'CHECK_REQUIRED')",
        ),
      );
      expect(sql, isNot(contains('provider_interaction_reference')));
      final tableStart = sql.indexOf(
        'create table if not exists einvoice.official_invoice_views',
      );
      final tableEnd = sql.indexOf(');', tableStart);
      final tableSql = sql.substring(tableStart, tableEnd);
      expect(tableSql, isNot(contains('correlation_id')));
    });

    test('lists required RPC symbols', () {
      expect(sql, contains('request_official_invoice_view'));
      expect(sql, contains('get_electronic_invoice_detail'));
      expect(sql, contains('_official_view_command_id'));
      expect(sql, contains('load_official_view_operation_context'));
      expect(sql, contains('record_official_invoice_view_result'));
    });
  });

  group('S4a access guard and enqueue semantics', () {
    test(
      'request_official_invoice_view enforces actor, permission and sales scope',
      () {
        expect(requestFn, contains('p_actor_id <> auth.uid()'));
        expect(
          requestFn,
          contains("iam.has_permission(p_tenant_id, 'einvoice.view')"),
        );
        expect(requestFn, contains('sales.can_access_sales_order'));
        expect(requestFn, contains('for update'));
      },
    );

    test('detail read uses the same public access guard', () {
      expect(detailFn, contains('p_actor_id <> auth.uid()'));
      expect(
        detailFn,
        contains("iam.has_permission(p_tenant_id, 'einvoice.view')"),
      );
      expect(detailFn, contains('sales.can_access_sales_order'));
    });

    test('detail read casts varchar invoice identity fields to text', () {
      expect(detailFn, contains('v_invoice.invoice_number::text'));
      expect(
        detailFn,
        contains('v_invoice.provider_invoice_reference::text'),
      );
    });

    test(
      'request enqueues fetch_official_view with deterministic command id',
      () {
        expect(requestFn, contains("'einvoice.fetch_official_view'"));
        expect(requestFn, contains('on conflict (id) do nothing'));
        expect(sql, contains('einvoice._official_view_command_id'));
        expect(
          requestFn,
          contains('on conflict (tenant_id, electronic_invoice_id) do update set'),
        );
        expect(requestFn, contains('v_operation.request_id'));
      },
    );

    test('each official-view attempt has an independent source dedupe id', () {
      final commandEnqueues = RegExp(
        r'insert into einvoice\.internal_commands\s*\([\s\S]*?source_event_id[\s\S]*?\)\s*values\s*\(([\s\S]*?)\)\s*on conflict',
        caseSensitive: false,
      ).allMatches(requestFn).toList();

      expect(commandEnqueues, hasLength(1));
      for (final enqueue in commandEnqueues) {
        expect(
          RegExp(r'\bv_cmd_id\b').allMatches(enqueue.group(1)!).length,
          2,
          reason: 'command id and source dedupe id must both be attempt-scoped',
        );
      }
    });

    test('fetch command payload carries the request id', () {
      final payloads = RegExp(
        r"jsonb_build_object\(([\s\S]*?)\)\s*,\s*v_cmd_id",
        caseSensitive: false,
      ).allMatches(requestFn).toList();

      expect(payloads, hasLength(1));
      for (final payload in payloads) {
        expect(payload.group(1), contains("'request_id', v_request_id"));
        expect(payload.group(1), contains("'correlation_id', v_request_id"));
        expect(payload.group(1), isNot(contains('attempt_ordinal')));
      }
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
      expect(loadContextFn, contains("'service_role'"));
      expect(recordResultFn, contains("'service_role'"));
    });

    test('worker context casts varchar invoice identity fields to text', () {
      expect(loadContextFn, contains('ei.provider_invoice_reference::text'));
      expect(loadContextFn, contains('ei.invoice_series::text'));
    });

    test(
      'record_official_invoice_view_result caps AVAILABLE TTL at five minutes',
      () {
        expect(recordResultFn, contains("interval '5 minutes'"));
        expect(recordResultFn, contains('least('));
        expect(recordResultFn, contains('p_request_id'));
        expect(recordResultFn, contains('p_failure_source'));
        expect(recordResultFn, isNot(contains('p_expected_version')));
        expect(recordResultFn, isNot(contains('provider_interaction_reference')));
      },
    );
  });
}
