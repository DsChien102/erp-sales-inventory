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
  late String pollCommandIdHelper;
  late String openReconciliationCaseFn;
  late String recordIssuanceUndeterminedFn;
  late String claimReconciliationCaseFn;
  late String recordReconciliationPendingFn;
  late String resolveReconciliationCaseFn;
  late String recoverInternalFinalizationFn;
  late String getIssuanceAttemptStatusFn;
  late String seedDueCommandsFn;
  late String claimInternalCommandsFn;

  setUpAll(() {
    draftPath =
        '${_repoRoot().path}/supabase/migrations/_drafts/009_einvoice_issuance_reconciliation_rpcs.sql';
    final draft = File(draftPath);
    expect(
      draft.existsSync(),
      isTrue,
      reason: 'Draft 009 must exist under supabase/migrations/_drafts/',
    );
    sql = draft.readAsStringSync();
    pollCommandIdHelper = _extractFunction(
      sql,
      'create or replace function einvoice._reconciliation_poll_command_id(',
    );
    openReconciliationCaseFn = _extractFunction(
      sql,
      'create or replace function einvoice.open_reconciliation_case(',
    );
    recordIssuanceUndeterminedFn = _extractFunction(
      sql,
      'create or replace function einvoice.record_issuance_undetermined(',
    );
    claimReconciliationCaseFn = _extractFunction(
      sql,
      'create or replace function einvoice.claim_issuance_reconciliation_case(',
    );
    recordReconciliationPendingFn = _extractFunction(
      sql,
      'create or replace function einvoice.record_reconciliation_pending(',
    );
    resolveReconciliationCaseFn = _extractFunction(
      sql,
      'create or replace function einvoice.resolve_reconciliation_case(',
    );
    recoverInternalFinalizationFn = _extractFunction(
      sql,
      'create or replace function einvoice.recover_internal_finalization(',
    );
    getIssuanceAttemptStatusFn = _extractFunction(
      sql,
      'create or replace function einvoice.get_issuance_attempt_status(',
    );
    seedDueCommandsFn = _extractFunction(
      sql,
      'create or replace function einvoice.seed_due_issuance_reconciliation_commands(',
    );
    claimInternalCommandsFn = _extractFunction(
      sql,
      'create or replace function einvoice.claim_internal_commands_batch(',
    );
  });

  group('Draft 009 metadata and touches header', () {
    test('declares exact Touches header matching touched objects', () {
      expect(
        sql,
        contains(
          '-- Touches: einvoice.open_reconciliation_case, einvoice.record_issuance_undetermined, einvoice.claim_issuance_reconciliation_case, einvoice.record_reconciliation_pending, einvoice.resolve_reconciliation_case, einvoice.recover_internal_finalization, einvoice.get_issuance_attempt_status, einvoice.claim_internal_commands_batch, einvoice._reconciliation_poll_command_id, einvoice.seed_due_issuance_reconciliation_commands',
        ),
      );
      expect(sql, contains('-- Kind: cohesive'));
      expect(sql, contains('-- Intent: einvoice_s3b_reconciliation'));
    });

    test(
      'does not add scheduled_command_id column to reconciliation cases table',
      () {
        expect(
          sql,
          isNot(
            contains(
              'alter table einvoice.invoice_reconciliation_cases add column scheduled_command_id',
            ),
          ),
        );
        expect(sql, isNot(contains('scheduled_command_id')));
      },
    );
  });

  group('Deterministic poll command ID helper', () {
    test('uses sha256 of caseId and ordinal formatted as UUID', () {
      expect(pollCommandIdHelper, contains('sha256'));
      expect(pollCommandIdHelper, contains('encode('));
      expect(pollCommandIdHelper, contains('substr('));
    });
  });

  group('claim_internal_commands_batch', () {
    test('enforces due time, for update skip locked, and claim token', () {
      expect(claimInternalCommandsFn, contains('enqueued_at <= now()'));
      expect(claimInternalCommandsFn, contains('for update skip locked'));
      expect(claimInternalCommandsFn, contains('claim_token'));
      expect(claimInternalCommandsFn, contains('order by m.enqueued_at'));
    });
  });

  group('open_reconciliation_case and record_issuance_undetermined', () {
    test(
      'enqueues deterministic poll command at next_check_at in same transaction',
      () {
        expect(
          openReconciliationCaseFn,
          contains('einvoice._reconciliation_poll_command_id('),
        );
        expect(
          openReconciliationCaseFn,
          contains('einvoice.poll_issuance_status'),
        );
        expect(
          openReconciliationCaseFn,
          contains('on conflict (id) do nothing'),
        );

        expect(
          recordIssuanceUndeterminedFn,
          contains('einvoice._reconciliation_poll_command_id('),
        );
        expect(
          recordIssuanceUndeterminedFn,
          contains('einvoice.poll_issuance_status'),
        );
        expect(
          recordIssuanceUndeterminedFn,
          contains('on conflict (id) do nothing'),
        );
      },
    );
  });

  group(
    'claim_issuance_reconciliation_case and record_reconciliation_pending',
    () {
      test('claim locks case with skip locked and returns poll context', () {
        expect(claimReconciliationCaseFn, contains('for update skip locked'));
        expect(claimReconciliationCaseFn, contains('claimed_at = now()'));
        expect(claimReconciliationCaseFn, contains('claim_token'));
      });

      test(
        'record_pending updates case and enqueues next check with delay',
        () {
          expect(
            recordReconciliationPendingFn,
            contains('attempt_count = p_check_sequence'),
          );
          expect(
            recordReconciliationPendingFn,
            contains('version = version + 1'),
          );
          expect(
            recordReconciliationPendingFn,
            contains('einvoice._reconciliation_poll_command_id('),
          );
          expect(
            recordReconciliationPendingFn,
            contains('on conflict (id) do nothing'),
          );
          expect(
            RegExp(
              r"'tenant_id', p_tenant_id",
            ).allMatches(recordReconciliationPendingFn).length,
            1,
            reason: 'requeued poll payload must contain each key exactly once',
          );
        },
      );
    },
  );

  group('resolve_reconciliation_case and recover_internal_finalization', () {
    test('get_issuance_attempt_status returns safe status fields', () {
      expect(
        getIssuanceAttemptStatusFn,
        contains('internal_finalization_status'),
      );
      expect(getIssuanceAttemptStatusFn, contains('has_electronic_invoice'));
      expect(getIssuanceAttemptStatusFn, contains('has_active_operation'));
      expect(getIssuanceAttemptStatusFn, contains('failure_code'));
    });

    test(
      'resolve handles SUCCESS, FAILURE, and UNRESOLVED, idempotent on terminal',
      () {
        expect(resolveReconciliationCaseFn, contains('for update'));
        expect(resolveReconciliationCaseFn, contains('RESOLVED'));
        expect(resolveReconciliationCaseFn, contains('UNRESOLVED'));
        expect(resolveReconciliationCaseFn, isNot(contains('publish_invoice')));
      },
    );

    test(
      'recover_internal_finalization completes local finalization without provider or publish',
      () {
        expect(
          recoverInternalFinalizationFn,
          contains('einvoice.electronic_invoices'),
        );
        expect(
          recoverInternalFinalizationFn,
          contains('einvoice.enqueue_outbox_message('),
        );
        expect(
          recoverInternalFinalizationFn,
          contains("'einvoice.electronic_invoice.registered'"),
        );
        expect(
          recoverInternalFinalizationFn,
          isNot(contains('publish_invoice')),
        );
        expect(recoverInternalFinalizationFn, isNot(contains('misa')));
        final returnSignature = recoverInternalFinalizationFn.substring(
          0,
          recoverInternalFinalizationFn.indexOf(') language plpgsql'),
        );
        expect(
          RegExp(
            r'invoice_series varchar\(100\)',
          ).allMatches(returnSignature).length,
          1,
          reason: 'RPC return signature must not declare invoice_series twice',
        );
      },
    );
  });

  group('seed_due_issuance_reconciliation_commands and backfill', () {
    test(
      'seeds pending cases due now and re-arms failed commands after cooldown',
      () {
        expect(seedDueCommandsFn, contains('next_check_at <= now()'));
        expect(
          seedDueCommandsFn,
          contains('einvoice._reconciliation_poll_command_id('),
        );
        expect(seedDueCommandsFn, contains('failed_at = null'));
      },
    );

    test('migration includes idempotent backfill block', () {
      expect(sql, contains('do \$\$'));
      expect(sql, contains('einvoice._reconciliation_poll_command_id('));
    });
  });
}
