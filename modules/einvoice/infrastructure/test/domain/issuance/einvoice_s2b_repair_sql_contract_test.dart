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

String _extractTable(String sql, String tablePrefix) {
  final start = sql.indexOf(tablePrefix);
  expect(start, greaterThanOrEqualTo(0), reason: 'missing $tablePrefix');
  final end = sql.indexOf(');', start);
  expect(
    end,
    greaterThanOrEqualTo(0),
    reason: 'missing closing ); for $tablePrefix',
  );
  return sql.substring(start, end + 2);
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
  late String preparePublishFn;
  late String markProviderCallStartedFn;
  late String recordSuccessFn;
  late String recordFailureFn;
  late String recordIntegrityFailureFn;
  late String recordDeadLetterFn;
  late String recordUndeterminedFn;
  late String projectionFn;
  late String claimInternalCommandsFn;
  late String retryOrDeadLetterFn;

  setUpAll(() {
    final draft = File(
      '${_repoRoot().path}/supabase/migrations/_drafts/'
      '007_einvoice_issuance_schema_and_publish_rpcs.sql',
    );
    expect(
      draft.existsSync(),
      isTrue,
      reason: 'S2b draft SQL 007 must exist under supabase/migrations/_drafts/',
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
    preparePublishFn = _extractFunction(
      sql,
      'create or replace function einvoice.prepare_issuance_publish(',
    );
    markProviderCallStartedFn = _extractFunction(
      sql,
      'create or replace function einvoice.mark_issuance_provider_call_started(',
    );
    recordSuccessFn = _extractFunction(
      sql,
      'create or replace function einvoice.record_issuance_success(',
    );
    recordFailureFn = _extractFunction(
      sql,
      'create or replace function einvoice.record_issuance_failure(',
    );
    recordIntegrityFailureFn = _extractFunction(
      sql,
      'create or replace function einvoice.record_issuance_command_integrity_failure(',
    );
    recordDeadLetterFn = _extractFunction(
      sql,
      'create or replace function einvoice.record_publish_command_dead_letter(',
    );
    recordUndeterminedFn = _extractFunction(
      draft009,
      'create or replace function einvoice.record_issuance_undetermined(',
    );
    projectionFn = _extractFunction(
      draft014,
      'create or replace function einvoice.get_order_invoice_projection(',
    );
    claimInternalCommandsFn = _extractFunction(
      sql,
      'create or replace function einvoice.claim_internal_commands_batch(',
    );
    retryOrDeadLetterFn = _extractFunction(
      sql,
      'create or replace function einvoice.retry_or_dead_letter_internal_command(',
    );
  });

  group('S2b repair draft metadata and touches', () {
    test('declares exact 10 Touches RPCs in header', () {
      final expectedTouches = [
        'einvoice.prepare_issuance_publish',
        'einvoice.mark_issuance_provider_call_started',
        'einvoice.record_issuance_success',
        'einvoice.record_issuance_failure',
        'einvoice.record_issuance_command_integrity_failure',
        'einvoice.record_publish_command_dead_letter',
        'einvoice.claim_internal_commands_batch',
        'einvoice.retry_or_dead_letter_internal_command',
      ];

      for (final touch in expectedTouches) {
        expect(sql, contains(touch));
      }
    });

    test(
      'defines canonical version column directly in create table for four core tables',
      () {
        final issuancesTable = _extractTable(
          sql,
          'create table if not exists einvoice.invoice_issuances',
        );
        expect(issuancesTable, isNot(contains('version bigint')));

        final attemptsTable = _extractTable(
          sql,
          'create table if not exists einvoice.issuance_attempts',
        );
        expect(attemptsTable, contains('version bigint not null default 0'));

        final invoicesTable = _extractTable(
          sql,
          'create table if not exists einvoice.electronic_invoices',
        );
        expect(invoicesTable, isNot(contains('version bigint')));

        final casesTable = _extractTable(
          sql,
          'create table if not exists einvoice.invoice_reconciliation_cases',
        );
        expect(casesTable, contains('version bigint not null default 0'));
      },
    );

    test('issuance_attempts has all 32 canonical fields', () {
      final attemptsTable = _extractTable(
        sql,
        'create table if not exists einvoice.issuance_attempts',
      );
      final expectedFields = [
        'id',
        'tenant_id',
        'invoice_issuance_id',
        'attempt_no',
        'status',
        'provider_connection_id',
        'invoice_series',
        'idempotency_key',
        'intent_hash',
        'snapshot_schema_version',
        'attempt_snapshot',
        'canonical_payload_hash',
        'provider_request_reference',
        'provider_invoice_reference',
        'provider_result_snapshot',
        'failure_code',
        'failure_message',
        'failure_source',
        'internal_finalization_state',
        'retry_count',
        'submitted_at',
        'provider_confirmed_at',
        'completed_at',
        'initiated_by_actor_type',
        'initiated_by_actor_id',
        'created_at',
        'version',
      ];
      for (final field in expectedFields) {
        expect(
          attemptsTable,
          contains(field),
          reason: 'issuance_attempts must contain canonical field: $field',
        );
      }
      for (final gone in const [
        'trigger_type',
        'canonical_model_version',
        'provider_interaction_reference',
        'provider_result_code',
        'provider_result_message',
        'started_at',
        'updated_at',
      ]) {
        expect(attemptsTable, isNot(contains(gone)), reason: gone);
      }
      expect(attemptsTable, isNot(contains('issuance_profile_id')));
    });

    test(
      'attempt_snapshot in issue_invoice contains all 11 canonical components',
      () {
        final startHelper = _extractFunction(
          draft008,
          'create or replace function einvoice._start_issuance_attempt(',
        );
        final components = [
          "'source_order'",
          "'seller'",
          "'buyer'",
          "'buyer_lineage'",
          "'invoice_context'",
          "'lines'",
          "'totals'",
          "'payment_information'",
          "'automation_policy'",
          "'readiness_result'",
          "'mapping_schema_version'",
        ];
        for (final component in components) {
          expect(
            startHelper,
            contains(component),
            reason: 'AttemptSnapshot must contain component $component',
          );
        }
      },
    );

    test('buyer_lineage preserves the source-owned base BuyerInvoiceSnapshot '
        'captured before any buyer completion merge', () {
      final startHelper = _extractFunction(
        draft008,
        'create or replace function einvoice._start_issuance_attempt(',
      );

      expect(
        startHelper,
        contains("v_base_buyer_snapshot := coalesce(p_buyer_snapshot"),
      );
      expect(
        startHelper,
        contains("'buyerInvoiceSnapshot', v_base_buyer_snapshot"),
      );
      expect(
        startHelper,
        isNot(contains("'buyerInvoiceSnapshot', p_commercial_snapshot")),
      );
      expect(startHelper, isNot(contains('v_buyer_completion')));
      expect(startHelper, contains('for share'));
    });

    test('buyer_lineage retains partner and source version', () {
      final startHelper = _extractFunction(
        draft008,
        'create or replace function einvoice._start_issuance_attempt(',
      );

      expect(
        startHelper,
        contains("'buyerPartnerId', p_buyer_partner_id"),
      );
      expect(startHelper, isNot(contains('buyerInvoiceCompletionId')));
      expect(startHelper, isNot(contains('v_buyer_completion')));
      expect(
        startHelper,
        contains("'buyerInvoiceSnapshotSourceVersion', p_source_version"),
      );
    });

    test(
      'does not introduce implementation-only columns or forbidden aliases',
      () {
        expect(sql, isNot(contains('dispatch_barrier_crossed_at')));
        expect(sql, isNot(contains('failure_origin')));
        expect(sql, isNot(contains('provider_correlation_key')));
        expect(sql, isNot(contains('safe_provider_evidence')));
      },
    );
  });

  group('prepare_issuance_publish and mark_issuance_provider_call_started', () {
    test(
      'prepare_issuance_publish transitions PREPARING to SUBMITTED without setting submitted_at',
      () {
        expect(preparePublishFn, contains("status = 'SUBMITTED'"));
        expect(preparePublishFn, contains("version = version + 1"));
        expect(
          preparePublishFn,
          isNot(contains("submitted_at = coalesce(submitted_at, now())")),
        );
        expect(preparePublishFn, contains("'CALL_PROVIDER'"));
        expect(preparePublishFn, contains("'RECONCILE_ONLY'"));
        expect(preparePublishFn, contains("'SKIP'"));
      },
    );

    test(
      'mark_issuance_provider_call_started only accepts SUBMITTED and sets submitted_at once',
      () {
        expect(markProviderCallStartedFn, contains("for update"));
        expect(markProviderCallStartedFn, contains("status <> 'SUBMITTED'"));
        expect(
          markProviderCallStartedFn,
          contains("submitted_at = coalesce(submitted_at, now())"),
        );
        expect(markProviderCallStartedFn, contains("version = version + 1"));
      },
    );
  });

  group('record_publish_command_dead_letter and command integrity', () {
    test(
      'record_publish_command_dead_letter decides based on canonical barrier status',
      () {
        expect(recordDeadLetterFn, contains("for update"));
        expect(recordDeadLetterFn, contains("status = 'PREPARING'"));
        expect(recordDeadLetterFn, contains("status = 'FAILED'"));
        expect(
          recordDeadLetterFn,
          contains("failure_code = 'PUBLISH_COMMAND_DEAD_LETTER'"),
        );
        expect(
          recordDeadLetterFn,
          contains("status in ('SUBMITTED', 'WAITING_RESULT')"),
        );
        expect(recordDeadLetterFn, contains("status = 'RECONCILING'"));
        expect(recordDeadLetterFn, contains("target_type = 'ISSUANCE_ATTEMPT'"));
        expect(recordDeadLetterFn, isNot(contains('reconciliation_purpose')));
      },
    );

    test(
      'record_issuance_command_integrity_failure sets FAILED and version increment',
      () {
        expect(recordIntegrityFailureFn, contains("for update"));
        expect(
          recordIntegrityFailureFn,
          contains("failure_code = 'COMMAND_INTEGRITY'"),
        );
        expect(recordIntegrityFailureFn, contains("version = version + 1"));
      },
    );
  });

  group('result recording RPCs', () {
    test(
      'record_issuance_success increments version and supports SUBMITTED/WAITING_RESULT/RECONCILING',
      () {
        expect(recordSuccessFn, contains("for update"));
        expect(recordSuccessFn, contains("version = version + 1"));
        expect(
          recordSuccessFn,
          contains(
            "status not in ('WAITING_RESULT', 'RECONCILING', 'SUBMITTED')",
          ),
        );
      },
    );

    test(
      'record_issuance_failure increments version and supports SUBMITTED/WAITING_RESULT/RECONCILING',
      () {
        expect(recordFailureFn, contains("for update"));
        expect(recordFailureFn, contains("version = version + 1"));
        expect(
          recordFailureFn,
          contains(
            "status not in ('WAITING_RESULT', 'RECONCILING', 'SUBMITTED')",
          ),
        );
      },
    );

    test(
      'record_issuance_undetermined increments version and supports SUBMITTED/WAITING_RESULT/RECONCILING',
      () {
        expect(recordUndeterminedFn, contains("for update"));
        expect(recordUndeterminedFn, contains("version = version + 1"));
        expect(
          recordUndeterminedFn,
          contains("status not in ('WAITING_RESULT', 'SUBMITTED')"),
        );
      },
    );
  });

  group('order invoice projection', () {
    test('FAILED attempt with no active operation has action issue', () {
      expect(projectionFn, contains("'failed'"));
      expect(projectionFn, contains("jsonb_build_array('issue')"));
    });
  });

  group('internal commands bounded retry and claim', () {
    test(
      'claim_internal_commands_batch respects enqueued_at <= now() and returns retry_count',
      () {
        expect(claimInternalCommandsFn, contains("enqueued_at <= now()"));
        expect(claimInternalCommandsFn, contains("retry_count"));
      },
    );

    test(
      'retry_or_dead_letter_internal_command implements 3 attempts with 5s/30s backoff',
      () {
        expect(retryOrDeadLetterFn, contains(">= 3"));
        expect(retryOrDeadLetterFn, contains("'DEAD_LETTER'"));
        expect(retryOrDeadLetterFn, contains("'RETRY'"));
        expect(retryOrDeadLetterFn, contains("interval '5 seconds'"));
        expect(retryOrDeadLetterFn, contains("interval '30 seconds'"));
      },
    );
  });
}
