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
  late String loadFn;
  late String recordFn;
  late String grantsTail;

  setUpAll(() {
    draftPath =
        '${_repoRoot().path}/supabase/migrations/_drafts/'
        '015_einvoice_delivery_reconciliation_rpcs.sql';
    final draft = File(draftPath);
    expect(
      draft.existsSync(),
      isTrue,
      reason: 'S5 draft SQL 015 must exist under supabase/migrations/_drafts/',
    );
    sql = draft.readAsStringSync();
    loadFn = _extractFunction(
      sql,
      'create or replace function einvoice.load_delivery_reconciliation_context(',
    );
    recordFn = _extractFunction(
      sql,
      'create or replace function einvoice.record_delivery_reconciliation_check(',
    );
    final revokeStart = sql.indexOf(
      'revoke all on function einvoice.load_delivery_reconciliation_context(',
    );
    expect(
      revokeStart,
      greaterThanOrEqualTo(0),
      reason: 'missing grants/revokes section',
    );
    grantsTail = sql.substring(revokeStart);
  });

  group('Draft 015 metadata and touches', () {
    test('declares exact Touches header matching created RPCs', () {
      expect(sql, contains('-- Kind: cohesive'));
      expect(sql, contains('-- Intent: einvoice_s5_delivery_reconciliation'));
      expect(
        sql,
        contains(
          '-- Touches: einvoice.load_delivery_reconciliation_context, '
          'einvoice.record_delivery_reconciliation_check',
        ),
      );
      expect(draftPath, isNot(contains(RegExp(r'/\d{10,}_'))));
      expect(
        sql,
        isNot(
          contains(
            'create or replace function einvoice._delivery_reconciliation_command_id(',
          ),
        ),
      );
    });
  });

  group('load_delivery_reconciliation_context', () {
    test('is service_role only and locks case/delivery/attempt rows', () {
      expect(loadFn, contains("'service_role'"));
      expect(loadFn, contains('for update'));
      expect(loadFn, contains('p_tenant_id'));
      expect(loadFn, contains('p_reconciliation_case_id'));
      expect(loadFn, contains('p_check_sequence'));
    });

    test('validates INVOICE_DELIVERY target', () {
      expect(loadFn, contains("v_case.target_type is distinct from 'INVOICE_DELIVERY'"));
      expect(loadFn, isNot(contains('delivery_attempts')));
      expect(recordFn, contains("failure_source = 'PROVIDER'"));
      expect(recordFn, isNot(contains('p_interaction_reference')));
    });

    test('exposes capability flag fail-closed from capabilities_snapshot', () {
      expect(loadFn, contains('supports_delivery_result_observation'));
      expect(loadFn, contains('capabilities_snapshot'));
      expect(loadFn, contains('false'));
    });
  });

  group('record_delivery_reconciliation_check schedules', () {
    test('locks rows and enforces expected case version', () {
      expect(recordFn, contains('for update'));
      expect(recordFn, contains('p_expected_case_version'));
      expect(recordFn, contains('STATE_CHANGED'));
      expect(recordFn, contains("'service_role'"));
    });

    test('uses deterministic _delivery_reconciliation_command_id helper', () {
      expect(
        recordFn,
        contains('einvoice._delivery_reconciliation_command_id('),
      );
      expect(recordFn, contains("'einvoice.reconcile_invoice_delivery'"));
    });

    test(
      'schedules 2m 10m 30m 2h for undetermined continuation after checks 1-4',
      () {
        expect(recordFn, contains("interval '2 minutes'"));
        expect(recordFn, contains("interval '10 minutes'"));
        expect(recordFn, contains("interval '30 minutes'"));
        expect(recordFn, contains("interval '2 hours'"));
      },
    );

    test(
      'checks 1-4 undetermined stay PENDING with exactly one next command',
      () {
        expect(recordFn, contains("'UNDETERMINED'"));
        expect(recordFn, contains("'PENDING'"));
        expect(recordFn, contains('on conflict'));
        expect(recordFn, contains('check_sequence'));
      },
    );

    test('check 5 undetermined becomes UNRESOLVED with attention', () {
      expect(recordFn, contains("'UNRESOLVED'"));
      expect(recordFn, contains("'einvoice.delivery.attention_required'"));
    });
  });

  group('record_delivery_reconciliation_check transitions', () {
    test(
      'supported terminal evidence resolves case and same delivery/attempt',
      () {
        expect(recordFn, contains("'SUCCEEDED'"));
        expect(recordFn, contains("'FAILED'"));
        expect(recordFn, contains("'RESOLVED'"));
        expect(recordFn, contains("'SUCCESS'"));
        expect(recordFn, contains("'DEFINITE_FAILURE'"));
      },
    );

    test(
      'unsupported check 1 becomes UNRESOLVED with DELIVERY_RESULT_OBSERVATION_UNSUPPORTED',
      () {
        expect(recordFn, contains("'UNSUPPORTED'"));
        expect(recordFn, contains('DELIVERY_RESULT_OBSERVATION_UNSUPPORTED'));
        expect(recordFn, contains("'UNRESOLVED'"));
        expect(recordFn, contains('next_check_at'));
        expect(recordFn, contains('null'));
        // No send email / getStatus on unsupported path.
        expect(recordFn, isNot(contains('getStatus')));
        expect(recordFn, isNot(contains("'einvoice.send_invoice_email'")));
      },
    );

    test(
      'clears next_check_at on terminal unsupported and exhausted paths',
      () {
        expect(recordFn, contains('next_check_at = null'));
      },
    );

    test('attention outbox only on UNRESOLVED', () {
      expect(recordFn, contains("'einvoice.delivery.attention_required'"));
      // Exactly one attention event type for delivery reconciliation.
      expect(
        'einvoice.delivery.attention_required'.allMatches(recordFn).length,
        1,
      );
    });

    test('writes only allow-listed safe messages', () {
      expect(recordFn, contains('allow-listed'));
      expect(recordFn, isNot(contains('misa')));
      expect(recordFn, isNot(contains('MeInvoice')));
      expect(recordFn, isNot(contains('http_body')));
      expect(recordFn, isNot(contains('raw_response')));
      expect(recordFn, isNot(contains('stack_trace')));
    });
  });

  group('late evidence amendment', () {
    test(
      'authenticated terminal evidence may resolve PENDING or UNRESOLVED to RESOLVED',
      () {
        expect(recordFn, contains("'PENDING'"));
        expect(recordFn, contains("'UNRESOLVED'"));
        expect(recordFn, contains("'RESOLVED'"));
        expect(recordFn, isNot(contains("'einvoice.send_invoice_email'")));
        expect(
          recordFn,
          isNot(contains('insert into einvoice.invoice_deliveries')),
        );
      },
    );

    test('duplicate or late failure cannot reverse success', () {
      expect(recordFn, contains("status = 'SUCCEEDED'"));
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
    });
  });

  group('Grants', () {
    test('load and record granted to service_role only', () {
      expect(
        grantsTail,
        contains(
          'grant execute on function einvoice.load_delivery_reconciliation_context(',
        ),
      );
      expect(
        grantsTail,
        contains(
          'grant execute on function einvoice.record_delivery_reconciliation_check(',
        ),
      );
      expect(grantsTail, contains('to service_role'));
      expect(grantsTail, contains('from public, anon, authenticated'));
    });
  });
}
