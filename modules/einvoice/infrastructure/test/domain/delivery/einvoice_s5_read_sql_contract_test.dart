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
  late String sheetFn;
  late String historyFn;
  late String loadAttemptFn;

  setUpAll(() {
    final draft = File(
      '${_repoRoot().path}/supabase/migrations/_drafts/'
      '013_einvoice_delivery_schema_and_start_rpcs.sql',
    );
    expect(
      draft.existsSync(),
      isTrue,
      reason: 'S5 draft SQL 013 must exist under supabase/migrations/_drafts/',
    );
    sql = draft.readAsStringSync();
    sheetFn = _extractFunction(
      sql,
      'create or replace function einvoice.get_send_invoice_sheet_context(',
    );
    historyFn = _extractFunction(
      sql,
      'create or replace function einvoice.get_invoice_delivery_history(',
    );
    loadAttemptFn = _extractFunction(
      sql,
      'create or replace function einvoice.load_delivery_attempt_context(',
    );
  });

  group('Sheet context and history access', () {
    test('sheet context enforces actor, send permission, and sales scope', () {
      expect(sheetFn, contains('auth.uid()'));
      expect(sheetFn, contains('p_actor_id <> auth.uid()'));
      expect(
        sheetFn,
        contains("iam.has_permission(p_tenant_id, 'einvoice.send')"),
      );
      expect(sheetFn, contains('sales.can_access_sales_order'));
      expect(sheetFn, contains("NOT_FOUND: sales order not found"));
      expect(sheetFn, isNot(contains('select true')));
    });

    test('history enforces actor, send permission, and sales scope', () {
      expect(historyFn, contains('auth.uid()'));
      expect(historyFn, contains('p_actor_id <> auth.uid()'));
      expect(
        historyFn,
        contains("iam.has_permission(p_tenant_id, 'einvoice.send')"),
      );
      expect(historyFn, contains('sales.can_access_sales_order'));
      expect(historyFn, contains("NOT_FOUND: sales order not found"));
    });

    test('full recipient fields require send permission gate', () {
      expect(sheetFn, contains('suggested_email'));
      expect(sheetFn, contains('suggested_email_source'));
      expect(historyFn, contains('recipientEmail'));
      expect(
        sheetFn,
        contains("iam.has_permission(p_tenant_id, 'einvoice.send')"),
      );
      expect(
        historyFn,
        contains("iam.has_permission(p_tenant_id, 'einvoice.send')"),
      );
    });
  });

  group('Suggestion priorities and history semantics', () {
    test(
      'manual initial suggestion uses Partner then successful Partner delivery',
      () {
        expect(sheetFn, contains("'CURRENT_PARTNER_PROFILE'"));
        expect(sheetFn, contains("'LAST_SUCCESSFUL_PARTNER_DELIVERY'"));
        expect(sheetFn, contains('partner.get_einvoice_recipient_snapshot'));
        expect(sheetFn, contains('buyerPartnerId'));
        expect(sheetFn, contains("'SUCCEEDED'"));
      },
    );

    test('manual resend suggestion uses last invoice delivery recipient', () {
      expect(sheetFn, contains("'LAST_INVOICE_DELIVERY'"));
      expect(sheetFn, contains("'resend'"));
      expect(sheetFn, contains("'send'"));
      expect(sql, contains("'RESEND'"));
    });

    test('does not perform cross-partner email history lookup', () {
      expect(sheetFn, isNot(contains('partner.partners')));
      expect(historyFn, isNot(contains('partner.partners')));
      // History/suggestions must stay scoped by buyerPartnerId or invoice id.
      expect(sheetFn, contains('electronic_invoice_id'));
      expect(
        RegExp(
              r'from\s+einvoice\.invoice_deliveries[\s\S]{0,200}tenant_id\s*=\s*p_tenant_id'
              r'[\s\S]{0,120}order by',
              caseSensitive: false,
            ).hasMatch(sheetFn.replaceAll('\n', ' ')) ||
            sheetFn.contains('buyerPartnerId'),
        isTrue,
      );
    });

    test(
      'history is chronological and exposes display + secondary attention',
      () {
        expect(historyFn, contains('order by'));
        expect(historyFn, contains('delivery_no'));
        expect(historyFn, contains('display_state'));
        expect(historyFn, contains('has_secondary_attention'));
        expect(sql, contains("'NOT_SENT'"));
        expect(sql, contains("'SENDING'"));
        expect(sql, contains("'SENT'"));
        expect(sql, contains("'FAILED'"));
        expect(historyFn, contains('_delivery_display_projection'));
      },
    );

    test('sheet context exposes mode, lock, displayState, and history', () {
      expect(sheetFn, contains('mode'));
      expect(sheetFn, contains('operation_locked'));
      expect(sheetFn, contains('display_state'));
      expect(sheetFn, contains("'PROCESSING'"));
      expect(sheetFn, contains("'UNKNOWN'"));
      expect(sheetFn, contains('history'));
    });
  });

  group('Worker load context', () {
    test(
      'derives identity from persisted delivery/attempt/invoice context',
      () {
        expect(loadAttemptFn, contains('invoice_deliveries'));
        expect(loadAttemptFn, contains('delivery_attempts'));
        expect(loadAttemptFn, contains('electronic_invoices'));
        expect(loadAttemptFn, contains('provider_connection_id'));
        expect(loadAttemptFn, contains('delivery_version'));
        expect(loadAttemptFn, contains('attempt_version'));
        expect(loadAttemptFn, contains('recipient_email'));
        expect(loadAttemptFn, contains('invoice_series'));
      },
    );
  });
}
