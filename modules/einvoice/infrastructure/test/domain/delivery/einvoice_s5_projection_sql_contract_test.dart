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
  late String projectionFn;

  setUpAll(() {
    final draft = File(
      '${_repoRoot().path}/supabase/migrations/_drafts/'
      '014_einvoice_delivery_results_and_projection_rpcs.sql',
    );
    expect(
      draft.existsSync(),
      isTrue,
      reason: 'S5 draft SQL 014 must exist under supabase/migrations/_drafts/',
    );
    sql = draft.readAsStringSync();
    projectionFn = _extractFunction(
      sql,
      'create or replace function einvoice.get_order_invoice_projection(',
    );
  });

  group('get_order_invoice_projection drop-before-recreate', () {
    test('drops function before recreating changed OUT row type', () {
      final dropIdx = sql.indexOf(
        'drop function if exists einvoice.get_order_invoice_projection(uuid, uuid, uuid)',
      );
      final createIdx = sql.indexOf(
        'create or replace function einvoice.get_order_invoice_projection(',
      );
      expect(dropIdx, greaterThanOrEqualTo(0));
      expect(createIdx, greaterThan(dropIdx));
      expect(sql, contains('einvoice.get_order_invoice_projection'));
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
    });

    test('exposes delivery_display_state and has_secondary_attention', () {
      expect(projectionFn, contains('delivery_display_state'));
      expect(projectionFn, contains('has_secondary_attention'));
      expect(projectionFn, contains('issuance_display_state'));
      expect(projectionFn, contains('actions'));
    });

    test('exposes delivery_pending and omits delivery_is_simulated', () {
      expect(projectionFn, contains('delivery_pending boolean'));
      expect(projectionFn, isNot(contains('delivery_is_simulated')));
      expect(projectionFn, isNot(contains('is_simulated')));
      expect(projectionFn, isNot(contains('v_simulated')));
      expect(projectionFn, contains("d.status = 'PROCESSING'"));
      expect(
        projectionFn,
        isNot(contains("d.status in ('PROCESSING', 'UNKNOWN')")),
      );
    });

    test(
      'reuses _delivery_display_projection for main + secondary attention',
      () {
        expect(projectionFn, contains('_delivery_display_projection'));
        expect(projectionFn, contains('invoice_deliveries'));
        expect(projectionFn, contains('order by'));
        expect(projectionFn, contains('delivery_no'));
      },
    );

    test(
      'prior success keeps SENT with secondary attention for later problem',
      () {
        // Helper from draft 013 already encodes precedence; projection must call it.
        expect(projectionFn, contains('_delivery_display_projection'));
        expect(sql, contains("'SENT'"));
        expect(sql, contains('has_secondary_attention'));
      },
    );

    test('does not copy unrelated RPCs into this draft', () {
      expect(
        sql,
        isNot(
          contains('create or replace function einvoice.start_auto_delivery('),
        ),
      );
      expect(
        sql,
        isNot(
          contains(
            'create or replace function einvoice.send_electronic_invoice(',
          ),
        ),
      );
      expect(
        sql,
        isNot(
          contains(
            'create or replace function einvoice.prepare_issuance_publish(',
          ),
        ),
      );
      expect(
        sql,
        isNot(
          contains(
            'create or replace function einvoice.record_issuance_success(',
          ),
        ),
      );
    });
  });
}
