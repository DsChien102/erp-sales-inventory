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
  late String draftPath;
  late String processTable;
  late String startAttemptHelper;
  late String issueInvoiceFn;
  late String startAutoIssuanceFn;
  late String listOpenProcessesFn;
  late String reevaluateAutoIssuanceFn;
  late String retryIssuanceFn;

  setUpAll(() {
    draftPath =
        '${_repoRoot().path}/supabase/migrations/_drafts/008_einvoice_auto_issuance_and_retry_rpcs.sql';
    final draft = File(draftPath);
    expect(
      draft.existsSync(),
      isTrue,
      reason: 'Draft 008 must exist under supabase/migrations/_drafts/',
    );
    sql = draft.readAsStringSync();
    processTable = _extractTable(
      sql,
      'create table if not exists einvoice.automatic_trigger_process_records',
    );
    startAttemptHelper = _extractFunction(
      sql,
      'create or replace function einvoice._start_issuance_attempt(',
    );
    issueInvoiceFn = _extractFunction(
      sql,
      'create or replace function einvoice.issue_invoice(',
    );
    startAutoIssuanceFn = _extractFunction(
      sql,
      'create or replace function einvoice.start_auto_issuance(',
    );
    listOpenProcessesFn = _extractFunction(
      sql,
      'create or replace function einvoice.list_open_auto_issuance_processes(',
    );
    reevaluateAutoIssuanceFn = _extractFunction(
      sql,
      'create or replace function einvoice.reevaluate_auto_issuance(',
    );
    retryIssuanceFn = _extractFunction(
      sql,
      'create or replace function einvoice.retry_issuance(',
    );
  });

  group('Draft metadata and touches header', () {
    test('declares exact Touches header matching replaced objects', () {
      expect(
        sql,
        contains(
          '-- Touches: einvoice.issuance_attempts, einvoice.automatic_trigger_process_records, einvoice._start_issuance_attempt, einvoice.issue_invoice, einvoice.start_auto_issuance, einvoice.list_open_auto_issuance_processes, einvoice.reevaluate_auto_issuance, einvoice.retry_issuance',
        ),
      );
      expect(sql, contains('-- Kind: cohesive'));
      expect(sql, contains('-- Intent: einvoice_s3_start_and_retry'));
      expect(sql, contains("'einvoice.publish_invoice'"));
      expect(sql, isNot(contains('create table sales.')));
      expect(sql, isNot(contains('create table partner.')));
    });
  });

  group('automatic_trigger_process_records table contract', () {
    test(
      'repairs the issuance attempt result snapshot column idempotently',
      () {
        expect(
          sql,
          contains(
            'alter table einvoice.issuance_attempts\n'
            '  add column if not exists provider_result_snapshot jsonb null;',
          ),
        );
      },
    );

    test('persists the canonical preparation contract', () {
      for (final field in <String>[
        'id uuid primary key default gen_random_uuid()',
        'tenant_id uuid not null',
        'process_type text not null',
        'sales_order_id uuid not null',
        'sales_order_version text not null',
        'trigger_key varchar(255) not null',
        'provider_idempotency_key varchar(150) not null',
        'process_status text not null',
        'retry_count integer not null default 0',
        'next_retry_at timestamptz null',
        'blocker_code varchar(100) null',
        'buyer_invoice_completion_id uuid null',
        'claimed_at timestamptz null',
        'claim_token varchar(100) null',
        'created_at timestamptz not null default now()',
        'updated_at timestamptz not null default now()',
        'version bigint not null default 0',
      ]) {
        expect(
          processTable,
          contains(field),
          reason: 'missing $field in table',
        );
      }
      expect(processTable, contains("'PENDING_REEVALUATION'"));
      expect(processTable, contains("'ATTEMPT_STARTED'"));
      expect(processTable, contains("'SKIPPED'"));
    });
  });

  group('_start_issuance_attempt helper contract', () {
    test('builds the complete canonical invoice through the shared helper', () {
      expect(
        startAttemptHelper,
        contains('v_canonical_jsonb := einvoice.build_canonical_invoice('),
      );
      expect(startAttemptHelper, contains('v_effective_buyer'));
      expect(startAttemptHelper, contains('p_commercial_snapshot'));
      expect(
        startAttemptHelper,
        isNot(contains("'modelVersion', '1.0.0'")),
        reason:
            'the start helper must not construct a partial canonical payload',
      );
    });

    test(
      'persists canonical preparation fields and 11 snapshot components',
      () {
        for (final field in <String>[
          'invoice_issuance_id',
          'attempt_no',
          'trigger_type',
          'status',
          'provider_connection_id',
          'issuance_profile_id',
          'idempotency_key',
          'intent_hash',
          'snapshot_schema_version',
          'attempt_snapshot',
          'canonical_model_version',
          'canonical_payload_hash',
          'internal_finalization_state',
          'initiated_by_actor_type',
          'initiated_by_actor_id',
        ]) {
          expect(
            startAttemptHelper,
            contains(field),
            reason: 'missing attempt field $field',
          );
        }

        for (final snapshotKey in <String>[
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
        ]) {
          expect(
            startAttemptHelper,
            contains(snapshotKey),
            reason: 'missing snapshot key $snapshotKey',
          );
        }

        expect(
          startAttemptHelper,
          contains('einvoice.enqueue_internal_command'),
        );
        expect(startAttemptHelper, contains('einvoice.enqueue_outbox_message'));
      },
    );

    test(
      'buyer_lineage keeps the source-owned base BuyerInvoiceSnapshot separate '
      'from the effective buyer',
      () {
        expect(
          startAttemptHelper,
          contains("v_base_buyer_snapshot := coalesce(p_buyer_snapshot"),
        );
        expect(
          startAttemptHelper,
          contains("'buyerInvoiceSnapshot', v_base_buyer_snapshot"),
        );
        expect(startAttemptHelper, contains("'buyer', v_effective_buyer"));

        final baseCapture = startAttemptHelper.indexOf(
          'v_base_buyer_snapshot := ',
        );
        final effectiveCapture = startAttemptHelper.indexOf(
          'v_effective_buyer := ',
        );
        expect(
          baseCapture,
          lessThan(effectiveCapture),
          reason:
              'base snapshot must be captured before any completion merge '
              'produces the effective buyer',
        );
      },
    );

    test('buyer_lineage retains partner, completion and source version', () {
      expect(
        startAttemptHelper,
        contains("'buyerPartnerId', p_buyer_partner_id"),
      );
      expect(
        startAttemptHelper,
        contains("'buyerInvoiceCompletionId', p_buyer_completion_id"),
      );
      expect(
        startAttemptHelper,
        contains("'buyerInvoiceSnapshotSourceVersion', p_source_version"),
      );
    });

    test(
      'base BuyerInvoiceSnapshot is never derived from effective or partner data',
      () {
        expect(
          startAttemptHelper,
          isNot(contains("'buyerInvoiceSnapshot', v_effective_buyer")),
        );
        expect(
          startAttemptHelper,
          isNot(contains("'buyerInvoiceSnapshot', p_commercial_snapshot")),
        );
        expect(startAttemptHelper, isNot(contains('partner.partners')));
      },
    );
  });

  group('start_auto_issuance RPC contract', () {
    test('is the sole insertion path and handles skip, block and start', () {
      expect(
        startAutoIssuanceFn,
        contains('insert into einvoice.automatic_trigger_process_records'),
      );
      expect(startAutoIssuanceFn, contains("'AUTOMATIC'"));
      expect(startAutoIssuanceFn, contains("'PENDING_REEVALUATION'"));
      expect(startAutoIssuanceFn, contains("'ATTEMPT_STARTED'"));
      expect(startAutoIssuanceFn, contains("'SKIPPED'"));
      expect(startAutoIssuanceFn, contains('einvoice._start_issuance_attempt'));
    });
  });

  group('list_open_auto_issuance_processes RPC contract', () {
    test(
      'queries einvoice-owned process records with join for buyer_partner_id without reading partner table',
      () {
        expect(
          listOpenProcessesFn,
          contains('einvoice.automatic_trigger_process_records'),
        );
        expect(listOpenProcessesFn, contains("'PENDING_REEVALUATION'"));
        expect(listOpenProcessesFn, isNot(contains('partner.partners')));
      },
    );
  });

  group('reevaluate_auto_issuance RPC contract', () {
    test(
      'requires existing PENDING_REEVALUATION process, never inserts process row, and transitions to ATTEMPT_STARTED',
      () {
        expect(
          reevaluateAutoIssuanceFn,
          isNot(
            contains('insert into einvoice.automatic_trigger_process_records'),
          ),
        );
        expect(reevaluateAutoIssuanceFn, contains("'PENDING_REEVALUATION'"));
        expect(reevaluateAutoIssuanceFn, contains("'ATTEMPT_STARTED'"));
        expect(
          reevaluateAutoIssuanceFn,
          contains('einvoice._start_issuance_attempt'),
        );
      },
    );
  });

  group('retry_issuance RPC contract', () {
    test(
      'supports same-version locked completion reuse (scn_e02_u05_sc11_01) and handles version mismatch (scn_e02_u05_sc12_01)',
      () {
        expect(retryIssuanceFn, contains('p_expected_order_version'));
        expect(retryIssuanceFn, contains('VERSION_MISMATCH'));
        expect(retryIssuanceFn, contains('einvoice._start_issuance_attempt'));
        expect(retryIssuanceFn, contains("'FAILED'"));
        expect(retryIssuanceFn, contains('OPERATION_IN_PROGRESS'));
        expect(retryIssuanceFn, contains('ALREADY_ISSUED'));
        expect(retryIssuanceFn, contains('NOT_FOUND'));
      },
    );

    test(
      'scn_e02_u05_sc11_01: selects version-bound completion and reuses locked lineage without Theme 03 call',
      () {
        expect(
          retryIssuanceFn,
          contains('from einvoice.buyer_invoice_completions bc'),
        );
        expect(
          retryIssuanceFn,
          contains('bc.sales_order_version = v_source.source_version'),
        );
        expect(retryIssuanceFn, isNot(contains('partner.partners')));
        expect(retryIssuanceFn, isNot(contains('partner.')));
        expect(
          retryIssuanceFn,
          contains(
            'p_buyer_completion_id => case when found then v_buyer_completion.id else null end',
          ),
        );
      },
    );

    test(
      'scn_e02_u05_sc12_01: rejects stale expectedOrderVersion with STATE_CHANGED and VERSION_MISMATCH',
      () {
        expect(
          retryIssuanceFn,
          contains(
            'if v_source.source_version <> p_expected_order_version then',
          ),
        );
        expect(retryIssuanceFn, contains('STATE_CHANGED'));
        expect(retryIssuanceFn, contains('VERSION_MISMATCH'));
      },
    );

    test(
      'preserves immutable prior attempt history and generates a new attempt',
      () {
        expect(
          retryIssuanceFn,
          isNot(contains('delete from einvoice.issuance_attempts')),
        );
        expect(
          retryIssuanceFn,
          isNot(contains('update einvoice.issuance_attempts set status =')),
        );
        expect(retryIssuanceFn, contains('select ia.*'));
        expect(retryIssuanceFn, contains('order by ia.attempt_no desc'));
        expect(retryIssuanceFn, contains('einvoice._start_issuance_attempt'));
      },
    );
  });

  group('issue_invoice RPC contract delegating to helper', () {
    test('issuance entry points select only configured profiles', () {
      for (final entryPoint in <String, String>{
        'issue_invoice': issueInvoiceFn,
        'start_auto_issuance': startAutoIssuanceFn,
        'reevaluate_auto_issuance': reevaluateAutoIssuanceFn,
        'retry_issuance': retryIssuanceFn,
      }.entries) {
        expect(
          entryPoint.value,
          contains('and ip.default_template is not null'),
          reason: '${entryPoint.key} must require a configured template',
        );
        expect(
          entryPoint.value,
          contains('and ip.default_signing is not null'),
          reason: '${entryPoint.key} must require configured signing',
        );
        expect(
          entryPoint.value,
          isNot(contains('ip.is_active')),
          reason: '${entryPoint.key} must not reference a missing column',
        );
        expect(
          entryPoint.value,
          isNot(contains('ip.created_at')),
          reason: '${entryPoint.key} must not reference a missing column',
        );
      }
    });

    test('delegates to _start_issuance_attempt cleanly', () {
      expect(issueInvoiceFn, contains('einvoice._start_issuance_attempt'));
    });
  });
}
