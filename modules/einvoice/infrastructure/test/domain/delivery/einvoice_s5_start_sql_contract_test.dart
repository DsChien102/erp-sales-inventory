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
  late String startAutoFn;
  late String sendManualFn;
  late String loadAttemptFn;
  late String startHelperFn;
  late String grantsTail;

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
    startAutoFn = _extractFunction(
      sql,
      'create or replace function einvoice.start_auto_delivery(',
    );
    sendManualFn = _extractFunction(
      sql,
      'create or replace function einvoice.send_electronic_invoice(',
    );
    loadAttemptFn = _extractFunction(
      sql,
      'create or replace function einvoice.load_delivery_attempt_context(',
    );
    startHelperFn = _extractFunction(
      sql,
      'create or replace function einvoice._start_invoice_delivery(',
    );
    final revokeStart = sql.indexOf(
      'revoke all on function einvoice._delivery_send_command_id(',
    );
    expect(
      revokeStart,
      greaterThanOrEqualTo(0),
      reason: 'missing grants/revokes section',
    );
    grantsTail = sql.substring(revokeStart);
  });

  group('Public and worker RPC auth surface', () {
    test(
      'manual send enforces auth.uid, actor equality, and einvoice.send',
      () {
        expect(sendManualFn, contains('auth.uid()'));
        expect(sendManualFn, contains('p_actor_id <> auth.uid()'));
        expect(
          sendManualFn,
          contains("iam.has_permission(p_tenant_id, 'einvoice.send')"),
        );
        expect(sendManualFn, contains('sales.can_access_sales_order'));
        expect(sendManualFn, contains("NOT_FOUND: sales order not found"));
        expect(sendManualFn, isNot(contains('select true')));
      },
    );

    test('manual send fails closed without allow-all sales fallback', () {
      expect(sendManualFn, contains('sales.can_access_sales_order('));
      expect(sendManualFn, isNot(contains('partner.partners')));
      expect(sendManualFn, isNot(contains('sales.orders')));
      expect(sendManualFn, isNot(contains('from partner.')));
      expect(sendManualFn, isNot(contains('from sales.')));
    });

    test('idempotency replay and IDEMPOTENCY_CONFLICT are defined', () {
      expect(sendManualFn, contains('idempotency_key'));
      expect(sendManualFn, contains('electronic_invoice_id'));
      expect(sendManualFn, contains("recipient_snapshot ->> 'toEmail'"));
      expect(sendManualFn, contains('IDEMPOTENCY_CONFLICT'));
      expect(startAutoFn, contains('idempotency_key'));
      expect(startAutoFn, contains('electronic_invoice_id'));
      expect(startAutoFn, contains("'INITIAL_SEND'"));
      expect(startAutoFn, contains('IDEMPOTENCY_CONFLICT'));
      expect(sql, isNot(contains('intent_hash')));
    });

    test('load_delivery_attempt_context is service_role only', () {
      expect(
        loadAttemptFn,
        contains("current_setting('request.jwt.claim.role', true)"),
      );
      expect(loadAttemptFn, contains("'service_role'"));
      expect(loadAttemptFn, isNot(contains('p_actor_id')));
      expect(loadAttemptFn, contains('recipient_snapshot'));
      expect(loadAttemptFn, contains('provider_invoice_reference'));
      expect(loadAttemptFn, isNot(contains('is_simulated')));
      expect(loadAttemptFn, isNot(contains('MISA_MEINVOICE_EMAIL_TRANSPORT')));
      expect(loadAttemptFn, isNot(contains('isMock')));
    });

    test('load_delivery_attempt_context drops before OUT row type change', () {
      final dropIdx = sql.indexOf(
        'drop function if exists einvoice.load_delivery_attempt_context(uuid, uuid, uuid)',
      );
      final createIdx = sql.indexOf(
        'create or replace function einvoice.load_delivery_attempt_context(',
      );
      expect(dropIdx, greaterThanOrEqualTo(0));
      expect(createIdx, greaterThan(dropIdx));
    });

    test('private delivery helpers are not granted to service_role', () {
      expect(
        grantsTail,
        contains('revoke all on function einvoice._start_invoice_delivery('),
      );
      expect(
        grantsTail,
        contains('from public, anon, authenticated, service_role'),
      );
      expect(
        grantsTail,
        isNot(
          contains(
            RegExp(
              r'grant execute on function einvoice\._start_invoice_delivery\([\s\S]*?\)\s*to service_role',
            ),
          ),
        ),
      );
      expect(
        grantsTail,
        isNot(
          contains(
            'grant execute on function einvoice._delivery_send_command_id(uuid)\n'
            '  to service_role',
          ),
        ),
      );
      expect(
        grantsTail,
        isNot(
          contains(
            'grant execute on function einvoice._delivery_public_status(text)\n'
            '  to service_role',
          ),
        ),
      );
      expect(
        grantsTail,
        isNot(
          contains(
            'grant execute on function einvoice._delivery_display_projection(text[])\n'
            '  to service_role',
          ),
        ),
      );
      expect(
        grantsTail,
        contains(
          'grant execute on function einvoice.start_auto_delivery(uuid, uuid, uuid, uuid)\n'
          '  to service_role',
        ),
      );
      expect(
        grantsTail,
        contains(
          'grant execute on function einvoice.load_delivery_attempt_context(uuid, uuid, int)\n'
          '  to service_role',
        ),
      );
      expect(
        grantsTail,
        contains(
          'grant execute on function einvoice.send_electronic_invoice(uuid, uuid, uuid, text, uuid)\n'
          '  to authenticated',
        ),
      );
    });
  });

  group('Atomic start and race invariants', () {
    test(
      'inserts one delivery row, recipient snapshot, and send command',
      () {
        expect(startAutoFn, contains('einvoice._start_invoice_delivery'));
        expect(sendManualFn, contains('einvoice._start_invoice_delivery'));
        expect(
          startHelperFn,
          contains('insert into einvoice.invoice_deliveries'),
        );
        expect(startHelperFn, contains('recipient_snapshot'));
        expect(startHelperFn, contains("'QUEUED'"));
        expect(startHelperFn, contains('retry_count'));
        expect(startHelperFn, isNot(contains('delivery_attempts')));
        expect(startHelperFn, contains('einvoice.enqueue_internal_command'));
        expect(startHelperFn, contains("'einvoice.send_invoice_email'"));
      },
    );

    test('start RPCs and draft schema omit is_simulated entirely', () {
      expect(startHelperFn, isNot(contains('is_simulated')));
      expect(startAutoFn, isNot(contains('is_simulated')));
      expect(sendManualFn, isNot(contains('is_simulated')));
      expect(sql, isNot(contains('is_simulated')));
    });

    test('internal command payload is ids-only with retry-tied identity', () {
      expect(sql, contains('_delivery_send_command_id'));
      expect(startHelperFn, contains("'tenant_id'"));
      expect(startHelperFn, contains("'delivery_id'"));
      expect(startHelperFn, contains("'retry_count'"));
      expect(startHelperFn, isNot(contains("'attempt_id'")));
      expect(startHelperFn, isNot(contains("'recipientEmail'")));
      expect(startHelperFn, isNot(contains('recipientEmail')));
    });

    test('enforces one INITIAL_SEND and active/unknown lock', () {
      expect(sql, contains("'INITIAL_SEND'"));
      expect(sendManualFn, contains("'RESEND'"));
      expect(sendManualFn, contains('OPERATION_IN_PROGRESS'));
      expect(startAutoFn, contains('OPERATION_IN_PROGRESS'));
      expect(startAutoFn, contains('INITIAL_DELIVERY_ALREADY_CLAIMED'));
      expect(sendManualFn, isNot(contains('p_delivery_kind')));
      expect(sendManualFn, isNot(contains('p_delivery_intent')));
    });

    test('maps concurrent INITIAL/idempotency unique races in shared start', () {
      expect(startHelperFn, contains('when unique_violation then'));
      expect(startHelperFn, contains('IDEMPOTENCY_CONFLICT'));
      expect(startHelperFn, contains('INITIAL_DELIVERY_ALREADY_CLAIMED'));
      expect(startHelperFn, contains('OPERATION_IN_PROGRESS'));
      expect(startHelperFn, contains('idempotency_key'));
      expect(startHelperFn, contains('electronic_invoice_id'));
      expect(startHelperFn, contains("recipient_snapshot ->> 'toEmail'"));
      expect(startHelperFn, isNot(contains('intent_hash')));
      // Auto maps helper INITIAL claim race to skip disposition.
      expect(
        RegExp(
          r"when others then[\s\S]*?INITIAL_DELIVERY_ALREADY_CLAIMED[\s\S]*?'skipped'",
          multiLine: true,
        ).hasMatch(startAutoFn),
        isTrue,
      );
      expect(
        RegExp(
          r"SQLERRM like 'INITIAL_DELIVERY_ALREADY_CLAIMED%'",
        ).hasMatch(startAutoFn),
        isTrue,
      );
    });

    test(
      'auto uses SYSTEM and stable auto identity seed comment',
      () {
        expect(startAutoFn, contains("'SYSTEM'"));
        expect(sql, contains("'AUTOMATIC'"));
        expect(sql, contains('9d4c1d80-8d2c-5f2a-8b86-ff34c8a8e275'));
        expect(sql, contains('auto_initial'));
        expect(startAutoFn, contains('p_idempotency_key'));
        expect(startAutoFn, contains('p_trigger_id'));
        expect(startAutoFn, contains('p_electronic_invoice_id'));
      },
    );

    test('server derives INITIAL vs RESEND for manual send', () {
      expect(sendManualFn, contains("'INITIAL_SEND'"));
      expect(sendManualFn, contains("'RESEND'"));
      expect(sendManualFn, contains("'USER'"));
      expect(sendManualFn, contains("'USER_INPUT'"));
      expect(sql, contains("'MANUAL'"));
    });
  });

  group('Eligibility and recipient resolution', () {
    test('auto re-reads auto_send_enabled and email capability', () {
      expect(startAutoFn, contains('auto_send_enabled'));
      expect(startAutoFn, contains('tenant_settings'));
      expect(startAutoFn, contains("'POLICY_OFF'"));
      expect(startAutoFn, contains("capabilities_snapshot"));
      expect(startAutoFn, contains('supports_email_delivery'));
      expect(startAutoFn, contains('DELIVERY_NOT_SUPPORTED'));
    });

    test('auto skips without creating rows for policy/email failures', () {
      expect(startAutoFn, contains("'INVALID_OR_MISSING_EMAIL'"));
      expect(startAutoFn, contains('disposition'));
      expect(startAutoFn, contains("'skipped'"));
      expect(startAutoFn, contains("'started'"));
      // Early returns before insert for skip paths must exist.
      expect(
        RegExp(
          r"POLICY_OFF[\s\S]{0,400}?return",
          multiLine: true,
        ).hasMatch(startAutoFn),
        isTrue,
      );
    });

    test('manual ignores auto policy but still requires email capability', () {
      expect(sendManualFn, isNot(contains('auto_send_enabled')));
      expect(sendManualFn, contains('supports_email_delivery'));
      expect(sendManualFn, contains('DELIVERY_NOT_SUPPORTED'));
    });

    test('resolves Partner email then BuyerInvoiceSnapshot lineage only', () {
      expect(sql, contains('partner.get_einvoice_recipient_snapshot'));
      expect(sql, contains("buyer_lineage"));
      expect(sql, contains('buyerInvoiceSnapshot'));
      expect(sql, contains('buyerPartnerId'));
      expect(sql, contains("'CURRENT_PARTNER_PROFILE'"));
      expect(sql, contains("'BUYER_INVOICE_SNAPSHOT'"));
      // Negative: never fall back to effective buyer email.
      expect(sql, isNot(contains("attemptSnapshot'->'buyer'->>'email")));
      expect(sql, isNot(contains("->'buyer'->>'email")));
      expect(sql, isNot(contains("{attemptSnapshot,buyer,email}")));
      expect(
        sql,
        contains("{buyer_lineage,buyerInvoiceSnapshot,buyerEmail}"),
      );
    });

    test('does not query partner/sales tables directly', () {
      expect(sql, isNot(contains('partner.partners')));
      expect(sql, isNot(contains('partner.person_profiles')));
      expect(sql, isNot(contains('sales.orders')));
      expect(sql, contains('partner.get_einvoice_recipient_snapshot'));
      expect(sql, contains('sales.can_access_sales_order'));
    });
  });
}
