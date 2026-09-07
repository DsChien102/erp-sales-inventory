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
  late String draftPath;
  late String prepareFn;
  late String recordFn;
  late String deadLetterFn;
  late String reconCmdHelper;
  late String grantsTail;

  setUpAll(() {
    draftPath =
        '${_repoRoot().path}/supabase/migrations/_drafts/'
        '014_einvoice_delivery_results_and_projection_rpcs.sql';
    final draft = File(draftPath);
    expect(
      draft.existsSync(),
      isTrue,
      reason: 'S5 draft SQL 014 must exist under supabase/migrations/_drafts/',
    );
    sql = draft.readAsStringSync();
    prepareFn = _extractFunction(
      sql,
      'create or replace function einvoice.prepare_delivery_provider_call(',
    );
    recordFn = _extractFunction(
      sql,
      'create or replace function einvoice.record_delivery_result(',
    );
    deadLetterFn = _extractFunction(
      sql,
      'create or replace function einvoice.record_delivery_command_dead_letter(',
    );
    reconCmdHelper = _extractFunction(
      sql,
      'create or replace function einvoice._delivery_reconciliation_command_id(',
    );
    final revokeStart = sql.indexOf(
      'revoke all on function einvoice._delivery_reconciliation_command_id(',
    );
    expect(
      revokeStart,
      greaterThanOrEqualTo(0),
      reason: 'missing grants/revokes section',
    );
    grantsTail = sql.substring(revokeStart);
  });

  group('Draft 014 metadata and touches', () {
    test('declares exact Touches header matching created RPCs', () {
      expect(sql, contains('-- Kind: cohesive'));
      expect(sql, contains('-- Intent: einvoice_s5_delivery_results'));
      expect(
        sql,
        contains(
          '-- Touches: einvoice._delivery_reconciliation_command_id, '
          'einvoice.prepare_delivery_provider_call, '
          'einvoice.record_delivery_result, '
          'einvoice.record_delivery_command_dead_letter, '
          'einvoice.get_order_invoice_projection',
        ),
      );
      expect(draftPath, isNot(contains(RegExp(r'/\d{10,}_'))));
    });
  });

  group('prepare_delivery_provider_call barrier', () {
    test('is service_role only and locks delivery/attempt rows', () {
      expect(prepareFn, contains("'service_role'"));
      expect(prepareFn, contains('for update'));
      expect(prepareFn, contains('p_expected_delivery_version'));
      expect(prepareFn, contains('p_expected_attempt_version'));
      expect(prepareFn, contains('p_request_reference'));
    });

    test('returns CALL_PROVIDER, SKIP, or RECORD_UNKNOWN', () {
      expect(prepareFn, contains("'CALL_PROVIDER'"));
      expect(prepareFn, contains("'SKIP'"));
      expect(prepareFn, contains("'RECORD_UNKNOWN'"));
    });

    test('QUEUED crosses barrier to SUBMITTED for CALL_PROVIDER', () {
      expect(prepareFn, contains("'QUEUED'"));
      expect(prepareFn, contains("'SUBMITTED'"));
      expect(prepareFn, contains('provider_request_reference'));
      expect(prepareFn, contains('submitted_at'));
    });

    test('replay SUBMITTED without terminal returns RECORD_UNKNOWN', () {
      expect(prepareFn, contains("'SUBMITTED'"));
      expect(prepareFn, contains("'RECORD_UNKNOWN'"));
      // Barrier may leave attempt SUBMITTED; must not roll it back to QUEUED.
      expect(
        prepareFn,
        isNot(contains(RegExp(r"set\s+status\s*=\s*'QUEUED'"))),
      );
    });

    test('prepare omits p_is_simulated and is_simulated provenance', () {
      expect(prepareFn, isNot(contains('p_is_simulated')));
      expect(prepareFn, isNot(contains('is_simulated')));
      expect(
        sql,
        contains(
          'drop function if exists einvoice.prepare_delivery_provider_call(uuid, uuid, uuid, bigint, bigint, text, boolean)',
        ),
      );
      expect(
        sql,
        contains(
          'grant execute on function einvoice.prepare_delivery_provider_call(\n  uuid, uuid, uuid, bigint, bigint, text\n) to service_role',
        ),
      );
    });
  });

  group('record_delivery_result state machine', () {
    test(
      'locks rows and enforces tenant/delivery/attempt relation + versions',
      () {
        expect(recordFn, contains('for update'));
        expect(recordFn, contains('p_expected_delivery_version'));
        expect(recordFn, contains('p_expected_attempt_version'));
        expect(recordFn, contains('STATE_CHANGED'));
        expect(recordFn, contains('invoice_delivery_id = p_delivery_id'));
        expect(recordFn, contains("'service_role'"));
      },
    );

    test('handles all four outcomes', () {
      expect(recordFn, contains("'SUCCESS'"));
      expect(recordFn, contains("'DEFINITE_FAILURE'"));
      expect(recordFn, contains("'RETRYABLE_FAILURE'"));
      expect(recordFn, contains("'UNDETERMINED'"));
      expect(recordFn, contains("'SUCCEEDED'"));
      expect(recordFn, contains("'FAILED'"));
      expect(recordFn, contains("'UNKNOWN'"));
      expect(recordFn, contains("'PROCESSING'"));
    });

    test('retryable failure caps at three attempts and enqueues next send', () {
      expect(recordFn, contains('attempt_no'));
      expect(recordFn, contains('< 3'));
      expect(recordFn, contains('einvoice.send_invoice_email'));
      expect(recordFn, contains('_delivery_send_command_id'));
      expect(recordFn, contains("'QUEUED'"));
    });

    test('retry insert and result paths omit is_simulated', () {
      expect(recordFn, isNot(contains('is_simulated')));
      expect(deadLetterFn, isNot(contains('is_simulated')));
    });

    test(
      'duplicate/reordered results are idempotent and never reverse success',
      () {
        expect(recordFn, contains("'SUCCEEDED'"));
        expect(recordFn, contains("v_delivery.status = 'SUCCEEDED'"));
        // Success path must never demote a SUCCEEDED delivery.
        expect(
          recordFn,
          isNot(
            contains(
              RegExp(
                r"v_delivery\.status\s*=\s*'SUCCEEDED'[\s\S]{0,200}status\s*=\s*'FAILED'",
              ),
            ),
          ),
        );
      },
    );

    test('does not mutate legal issuance / electronic invoice facts', () {
      expect(recordFn, isNot(contains('update einvoice.electronic_invoices')));
      expect(recordFn, isNot(contains('update einvoice.issuance_attempts')));
      expect(recordFn, isNot(contains('update einvoice.invoice_issuances')));
      expect(recordFn, isNot(contains('invoice_number')));
      expect(recordFn, isNot(contains('lookup_code')));
    });

    test('persists only allow-listed safe messages', () {
      expect(recordFn, isNot(contains('misa')));
      expect(recordFn, isNot(contains('MeInvoice')));
      expect(recordFn, isNot(contains('http_body')));
      expect(recordFn, isNot(contains('stack_trace')));
      expect(recordFn, isNot(contains('raw_response')));
      expect(recordFn, isNot(contains('raw_exception')));
      expect(recordFn, contains('allow-listed'));
      expect(recordFn, contains('Provider response timed out'));
    });
  });

  group('UNKNOWN reconciliation handoff', () {
    test(
      'opens one PENDING VERIFY_DELIVERY case with first check schedule',
      () {
        expect(recordFn, contains("'DELIVERY_ATTEMPT'"));
        expect(recordFn, contains("'VERIFY_DELIVERY'"));
        expect(recordFn, contains("'PENDING'"));
        expect(recordFn, contains('attempt_count'));
        expect(recordFn, contains('0'));
        expect(recordFn, contains("interval '30 seconds'"));
        expect(recordFn, isNot(contains("'UNRESOLVED'")));
      },
    );

    test(
      'enqueues exactly one deterministic reconcile command, no send_invoice_email',
      () {
        expect(reconCmdHelper, contains('sha256'));
        expect(
          recordFn,
          contains('einvoice._delivery_reconciliation_command_id('),
        );
        expect(recordFn, contains("'einvoice.reconcile_invoice_delivery'"));
        expect(recordFn, contains('on conflict'));

        final undeterminedStart = recordFn.indexOf(
          "p_outcome_kind = 'UNDETERMINED'",
        );
        expect(undeterminedStart, greaterThanOrEqualTo(0));
        final undeterminedSlice = recordFn.substring(undeterminedStart);
        expect(
          undeterminedSlice.contains('einvoice._delivery_send_command_id'),
          isFalse,
        );
        expect(
          undeterminedSlice.contains("'einvoice.send_invoice_email'"),
          isFalse,
        );
        expect(
          undeterminedSlice.contains("'einvoice.reconcile_invoice_delivery'"),
          isTrue,
        );
      },
    );

    test('emits result event but no attention event on initial UNKNOWN', () {
      expect(recordFn, contains("'einvoice.delivery.result_recorded'"));
      expect(
        recordFn,
        isNot(contains("'einvoice.delivery.attention_required'")),
      );
      expect(recordFn, contains('has_secondary_attention'));
      expect(recordFn, contains('delivery_display_state'));
      expect(recordFn, contains('delivery_version'));
    });

    test('UNKNOWN keeps active business lock (status UNKNOWN)', () {
      expect(recordFn, contains("status = 'UNKNOWN'"));
      // No path from UNKNOWN back to queued/processing for the delivery.
      expect(
        recordFn,
        isNot(
          contains(
            RegExp(
              r"status\s*=\s*'UNKNOWN'[\s\S]{0,200}status\s*=\s*'PROCESSING'",
            ),
          ),
        ),
      );
      expect(
        recordFn,
        isNot(contains(RegExp(r"'UNKNOWN'[\s\S]{0,120}status\s*=\s*'QUEUED'"))),
      );
    });
  });

  group('record_delivery_command_dead_letter', () {
    test(
      'QUEUED exhausted becomes WORKER_EXHAUSTED_BEFORE_DISPATCH / FAILED',
      () {
        expect(deadLetterFn, contains("'QUEUED'"));
        expect(deadLetterFn, contains("'WORKER_EXHAUSTED_BEFORE_DISPATCH'"));
        expect(deadLetterFn, contains("'FAILED'"));
        expect(deadLetterFn, contains("'service_role'"));
      },
    );

    test(
      'SUBMITTED dead-letter becomes UNKNOWN with PENDING case and no attention',
      () {
        expect(deadLetterFn, contains("'SUBMITTED'"));
        expect(deadLetterFn, contains("'UNKNOWN'"));
        expect(deadLetterFn, contains("'VERIFY_DELIVERY'"));
        expect(deadLetterFn, contains("'PENDING'"));
        expect(
          deadLetterFn,
          contains('einvoice._delivery_reconciliation_command_id('),
        );
        expect(deadLetterFn, contains("'einvoice.reconcile_invoice_delivery'"));
        expect(
          deadLetterFn,
          isNot(contains("'einvoice.delivery.attention_required'")),
        );
        expect(deadLetterFn, isNot(contains("'UNRESOLVED'")));
      },
    );
  });

  group('Grants', () {
    test('worker RPCs granted to service_role; helper revoked', () {
      expect(
        grantsTail,
        contains(
          'revoke all on function einvoice._delivery_reconciliation_command_id(',
        ),
      );
      expect(
        grantsTail,
        contains(
          'grant execute on function einvoice.prepare_delivery_provider_call(',
        ),
      );
      expect(
        grantsTail,
        contains('grant execute on function einvoice.record_delivery_result('),
      );
      expect(
        grantsTail,
        contains(
          'grant execute on function einvoice.record_delivery_command_dead_letter(',
        ),
      );
      expect(grantsTail, contains('to service_role'));
    });
  });
}
