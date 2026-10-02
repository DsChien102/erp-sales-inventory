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
  late String draft008;
  late String draft009;
  late String draft014;
  late String issueInvoiceFn;
  late String startHelper;
  late String preparePublishFn;
  late String recordSuccessFn;
  late String recordUndeterminedFn;

  setUpAll(() {
    final draft = File(
      '${_repoRoot().path}/supabase/migrations/_drafts/'
      '007_einvoice_issuance_schema_and_publish_rpcs.sql',
    );
    expect(
      draft.existsSync(),
      isTrue,
      reason: 'S2b draft SQL must exist under supabase/migrations/_drafts/',
    );
    sql = draft.readAsStringSync();
    draft008 = File(
      '${_repoRoot().path}/supabase/migrations/_drafts/'
      '008_einvoice_auto_issuance_and_retry_rpcs.sql',
    ).readAsStringSync();
    draft009 = File(
      '${_repoRoot().path}/supabase/migrations/_drafts/'
      '009_einvoice_issuance_reconciliation_rpcs.sql',
    ).readAsStringSync();
    draft014 = File(
      '${_repoRoot().path}/supabase/migrations/_drafts/'
      '014_einvoice_delivery_results_and_projection_rpcs.sql',
    ).readAsStringSync();
    issueInvoiceFn = _extractFunction(
      draft008,
      'create or replace function einvoice.issue_invoice(',
    );
    startHelper = _extractFunction(
      draft008,
      'create or replace function einvoice._start_issuance_attempt(',
    );
    preparePublishFn = _extractFunction(
      sql,
      'create or replace function einvoice.prepare_issuance_publish(',
    );
    recordSuccessFn = _extractFunction(
      sql,
      'create or replace function einvoice.record_issuance_success(',
    );
    recordUndeterminedFn = _extractFunction(
      draft009,
      'create or replace function einvoice.record_issuance_undetermined(',
    );
  });

  group('S2b draft schema and RPC surface', () {
    test('declares canonical issuance tables without forbidden aliases', () {
      expect(
        sql,
        contains('create table if not exists einvoice.invoice_issuances'),
      );
      expect(
        sql,
        contains('create table if not exists einvoice.issuance_attempts'),
      );
      expect(
        sql,
        contains('create table if not exists einvoice.electronic_invoices'),
      );
      expect(
        sql,
        contains(
          'create table if not exists einvoice.invoice_reconciliation_cases',
        ),
      );
      expect(sql, isNot(contains('canonical_model_version')));
      expect(sql, contains('canonical_payload_hash varchar(128) not null'));
      expect(sql, contains('intent_hash varchar(128) not null'));
      expect(sql, contains('provider_connection_id uuid not null'));
      expect(sql, isNot(contains('issuance_profile_id')));
      expect(sql, contains('internal_finalization_state'));
      expect(sql, isNot(contains('canonical_payload jsonb not null')));
      expect(sql, isNot(contains('provider_correlation_key')));
      expect(sql, isNot(contains('safe_provider_evidence')));
      expect(sql, contains('created_at timestamptz not null default now()'));
      expect(sql, isNot(contains('updated_at')));
    });

    test('issue_invoice uses opaque sourceVersion and replay idempotency', () {
      expect(draft008, contains('p_source_version text'));
      expect(sql, isNot(contains('p_expected_order_version')));
      expect(issueInvoiceFn, contains("'operation', 'ISSUE_ORIGINAL'"));
      expect(issueInvoiceFn, contains("'source_version', p_source_version"));
      expect(issueInvoiceFn, contains('convert_to(v_intent::text'));
      expect(issueInvoiceFn, contains('for update'));
      expect(issueInvoiceFn, contains('intent_hash'));
      expect(issueInvoiceFn, contains('IDEMPOTENCY_CONFLICT'));
      expect(
        issueInvoiceFn,
        contains('einvoice.load_issuance_source_snapshot'),
      );
      expect(issueInvoiceFn, contains('einvoice._start_issuance_attempt'));
      expect(startHelper, contains("'einvoice.publish_invoice'"));
      expect(startHelper, contains("'einvoice.issuance.processing'"));
    });

    test('prepare_issuance_publish implements one-way dispatch barrier', () {
      expect(preparePublishFn, contains("'CALL_PROVIDER'"));
      expect(preparePublishFn, contains("'RECONCILE_ONLY'"));
      expect(preparePublishFn, contains("'SKIP'"));
      expect(
        preparePublishFn,
        contains('convert_to(p_canonical_payload::text'),
      );
      expect(preparePublishFn, contains('v_recomputed_hash'));
      expect(preparePublishFn, contains("status = 'PREPARING'"));
      expect(preparePublishFn, contains("status = 'SUBMITTED'"));
      expect(
        preparePublishFn,
        isNot(contains("submitted_at = coalesce(submitted_at, now())")),
      );
      expect(preparePublishFn, contains('STATE_CHANGED'));
    });

    test('result landing and reconciliation handoff contracts', () {
      expect(sql, contains('record_issuance_command_integrity_failure'));
      expect(sql, contains("'COMMAND_INTEGRITY'"));
      expect(recordSuccessFn, contains('exception when others then'));
      expect(recordSuccessFn, contains("'UNRESOLVED'"));
      expect(
        recordUndeterminedFn,
        contains("target_type = 'ISSUANCE_ATTEMPT'"),
      );
      expect(recordUndeterminedFn, isNot(contains('reconciliation_purpose')));
      expect(recordUndeterminedFn, contains('next_check_at'));
      expect(sql, isNot(contains("'einvoice.poll_issuance_status'")));
    });
  });

  group('hash contract', () {
    test('uses PostgreSQL jsonb text digest for canonical payload hash', () {
      expect(startHelper, contains('convert_to(v_canonical_jsonb::text'));
      expect(
        preparePublishFn,
        contains('convert_to(p_canonical_payload::text'),
      );
    });

    test('documents key-order independence and content sensitivity', () {
      expect(sql, contains('contract: hash-key-order-independence'));
      expect(sql, contains('contract: hash-content-sensitivity'));
      expect(preparePublishFn, contains('v_recomputed_hash'));
      expect(preparePublishFn, contains('canonical_payload_hash'));
    });
  });

  group('access boundaries', () {
    test('does not read private sales or partner tables', () {
      expect(
        RegExp(r'from\s+sales\.', caseSensitive: false).hasMatch(sql),
        isFalse,
      );
      expect(
        RegExp(r'from\s+partner\.', caseSensitive: false).hasMatch(sql),
        isFalse,
      );
      expect(
        RegExp(r'join\s+sales\.', caseSensitive: false).hasMatch(sql),
        isFalse,
      );
      expect(
        RegExp(r'join\s+partner\.', caseSensitive: false).hasMatch(sql),
        isFalse,
      );
    });

    test('blocker reasons only appear under ISSUANCE_NOT_READY details', () {
      for (final blocker in const [
        'SOURCE_SNAPSHOT_UNAVAILABLE',
        'BUYER_SOURCE_UNAVAILABLE',
      ]) {
        expect(sql, contains(blocker));
      }
      expect(issueInvoiceFn, contains('ISSUANCE_NOT_READY'));
      expect(issueInvoiceFn, contains("'details'"));
      expect(issueInvoiceFn, contains("'blockers'"));
      expect(
        issueInvoiceFn,
        isNot(contains("raise exception 'SOURCE_SNAPSHOT_UNAVAILABLE'")),
      );
      expect(
        issueInvoiceFn,
        isNot(contains("raise exception 'BUYER_SOURCE_UNAVAILABLE'")),
      );
    });

    test('idempotency conflict happens before upstream snapshot read', () {
      final conflictAt = issueInvoiceFn.indexOf('IDEMPOTENCY_CONFLICT');
      final snapshotAt = issueInvoiceFn.indexOf(
        'einvoice.load_issuance_source_snapshot',
      );
      expect(conflictAt, greaterThanOrEqualTo(0));
      expect(snapshotAt, greaterThan(conflictAt));
    });
  });

  group('task brief frozen contracts', () {
    test('matches plan Step 1 SQL surface assertions', () {
      expect(draft008, contains('p_source_version text'));
      expect(sql, isNot(contains('p_expected_order_version')));
      expect(sql, isNot(contains('canonical_payload jsonb not null')));
      expect(sql, isNot(contains('canonical_model_version')));
      expect(sql, contains('canonical_payload_hash varchar(128) not null'));
      expect(sql, contains('intent_hash varchar(128) not null'));
      expect(sql, contains('provider_connection_id uuid not null'));
      expect(sql, isNot(contains('issuance_profile_id')));
      expect(sql, contains('internal_finalization_state'));
      expect(sql, isNot(contains('provider_correlation_key')));
      expect(sql, isNot(contains('safe_provider_evidence')));
      expect(sql, contains("'CALL_PROVIDER'"));
      expect(sql, contains("'RECONCILE_ONLY'"));
      expect(sql, contains("'SKIP'"));
      expect(sql, contains("target_type = 'ISSUANCE_ATTEMPT'"));
      expect(sql, isNot(contains('reconciliation_purpose')));
      expect(sql, contains('next_check_at'));
      expect(sql, isNot(contains("'einvoice.poll_issuance_status'")));
      expect(sql, contains('exception when others then'));
      expect(sql, contains("'UNRESOLVED'"));
      expect(sql, contains('record_issuance_command_integrity_failure'));
      expect(sql, contains("'COMMAND_INTEGRITY'"));
      expect(sql, contains('created_at timestamptz not null default now()'));
      expect(sql, isNot(contains('updated_at')));
    });
  });

  group('projection', () {
    test('get_order_invoice_projection maps display states and actions', () {
      final projectionFn = _extractFunction(
        draft014,
        'create or replace function einvoice.get_order_invoice_projection(',
      );
      expect(projectionFn, contains("'notIssued'"));
      expect(projectionFn, contains("'processing'"));
      expect(projectionFn, contains("'issued'"));
      expect(projectionFn, contains("'failed'"));
      expect(projectionFn, contains("'issue'"));
      expect(projectionFn, contains("'view'"));
    });
  });
}
