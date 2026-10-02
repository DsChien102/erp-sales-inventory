import 'dart:io';

import 'package:test/test.dart';

Directory _repoRoot() {
  var dir = Directory.current;
  while (!Directory('${dir.path}/supabase/migrations/_drafts').existsSync()) {
    final parent = dir.parent;
    if (parent.path == dir.path) break;
    dir = parent;
  }
  return dir;
}

String _read(String name) => File(
  '${_repoRoot().path}/supabase/migrations/_drafts/$name',
).readAsStringSync();

String _function(String sql, String prefix) {
  final start = sql.indexOf(prefix);
  expect(start, greaterThanOrEqualTo(0), reason: 'missing $prefix');
  final end = sql.indexOf('\n\$\$;', start);
  expect(end, greaterThan(start));
  return sql.substring(start, end + 4);
}

void main() {
  late String draft007;
  late String draft008;
  late String issueInvoice;
  late String start008;

  setUpAll(() {
    draft007 = _read('007_einvoice_issuance_schema_and_publish_rpcs.sql');
    draft008 = _read('008_einvoice_auto_issuance_and_retry_rpcs.sql');
    issueInvoice = _function(
      draft008,
      'create or replace function einvoice.issue_invoice(',
    );
    start008 = _function(
      draft008,
      'create or replace function einvoice._start_issuance_attempt(',
    );
  });

  group('th08_hardening_attempt_provider_contract', () {
    test('attempt table keeps series; typed provider flags live in the snapshot', () {
      expect(draft007, contains('invoice_series varchar(100) not null'));
      expect(draft007, contains("invoice_series ~ '^[1256][CK].{2}[TM]'"));
      expect(draft007, isNot(contains('invoice_with_code boolean')));
      expect(draft007, isNot(contains('is_invoice_summary boolean')));
      expect(draft007, isNot(contains('sign_type smallint')));
    });

    test('clean rebuild has no compatibility repair alters', () {
      expect(
        draft007,
        isNot(contains('add column if not exists invoice_series')),
      );
      expect(
        draft008,
        isNot(contains('add column if not exists provider_result_snapshot')),
      );
    });

    test('manual issue resolves the configured tenant profile', () {
      expect(issueInvoice, isNot(contains('ip.is_active')));
      expect(issueInvoice, isNot(contains('ip.created_at')));
      expect(issueInvoice, contains('ts.default_template_id is not null'));
    });

    test('shared start helper validates and freezes all provider fields', () {
      expect(start008, contains("v_canonical_jsonb ->> 'invSeries'"));
      expect(
        start008,
        contains("jsonb_typeof(v_canonical_jsonb -> 'invoiceWithCode')"),
      );
      expect(
        start008,
        contains("jsonb_typeof(v_canonical_jsonb -> 'isInvoiceSummary')"),
      );
      expect(start008, contains("jsonb_typeof(v_canonical_jsonb -> 'signType')"));
      expect(start008, contains("'provider_contract', jsonb_build_object("));
      expect(start008, contains("'invoice_series', v_invoice_series"));
      expect(start008, contains("'invoice_with_code', v_invoice_with_code"));
      expect(start008, contains("'is_invoice_summary', v_is_invoice_summary"));
      expect(start008, contains("'sign_type', v_sign_type"));
      expect(start008, contains('invoice_series,'));
    });

    test('manual issue delegates the freeze to the shared helper', () {
      expect(issueInvoice, contains('einvoice._start_issuance_attempt('));
      expect(issueInvoice, isNot(contains('invoice_with_code,')));
      expect(issueInvoice, isNot(contains('sign_type,')));
    });

    test('all draft 008 entry points delegate to the shared helper', () {
      expect(
        RegExp(
          r'einvoice\._start_issuance_attempt\(',
        ).allMatches(draft008).length,
        7,
        reason:
            'drop old signature + definition + revoke signature + manual/auto/reevaluation/retry callers',
      );
    });

    test('PL/pgSQL IF guards parenthesize nested CASE expressions', () {
      final parenthesizedCase = RegExp(
        r'is distinct from\s*\(\s*case\s+when',
        caseSensitive: false,
      );

      expect(start008, matches(parenthesizedCase));
    });
  });
}
